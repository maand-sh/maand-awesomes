#!/usr/bin/env python3
"""Print Patroni cluster master (leader) and replicas."""

from __future__ import annotations

import os
import sys

import postgres_lib as pg


def member_endpoint(member: dict) -> str:
    name = member.get("name") or member.get("host") or "?"
    host = member.get("host") or name
    pg_port = member.get("port") or pg.pg_port()
    state = member.get("state") or "?"
    return f"{name} ({host}:{pg_port}) state={state}"


def main() -> int:
    allocation_index = os.getenv('ALLOCATION_INDEX')
    if allocation_index != "0":
        return 0
    port = pg.patroni_port()
    workers = pg.postgres_workers()
    if not workers:
        sys.stderr.write("no workers in maand/job/postgres\n")
        return 1

    cluster = None
    source = None
    for host in workers:
        cluster = pg.fetch_cluster(host, port)
        if cluster is not None:
            source = host
            break

    if cluster is None:
        sys.stderr.write("failed to fetch /cluster from postgres nodes\n")
        return 1

    members = cluster.get("members") or []
    leader = None
    replicas: list[tuple[str, str]] = []

    for member in members:
        role = (member.get("role") or "").lower()
        line = member_endpoint(member)
        if role in ("leader", "master", "primary"):
            leader = line
        else:
            replicas.append((role or "unknown", line))

    print(f"scope: {cluster.get('scope', 'postgres')}", flush=True)
    print(f"queried: {source}:{port} (via ssh)", flush=True)
    print(f"master: {leader or 'none'}", flush=True)
    if replicas:
        print("replicas:", flush=True)
        for role, line in replicas:
            print(f"  - [{role}] {line}", flush=True)
    else:
        print("replicas: none", flush=True)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
