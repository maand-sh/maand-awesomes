#!/usr/bin/env python3
"""Print Vault Raft cluster active leader and standby nodes."""

from __future__ import annotations

import os
import sys

import vault_lib as v


def main() -> int:
    allocation_index = os.getenv("ALLOCATION_INDEX")
    if allocation_index != "0":
        return 0

    port = v.api_port()
    workers = v.vault_workers()
    if not workers:
        sys.stderr.write("no workers in maand/worker/vault_workers\n")
        return 1

    leader_live = v.active_leader_ip()
    leader = None
    replicas: list[tuple[str, str]] = []
    queried = None
    cluster_name = None
    cluster_id = None

    for host in workers:
        health = v.fetch_health(host)
        if health is None:
            replicas.append(("unreachable", v.node_endpoint(host, workers, port)))
            continue
        if queried is None:
            queried = host
            cluster_name = health.get("cluster_name")
            cluster_id = health.get("cluster_id")
        line = v.node_endpoint(host, workers, port, health)
        state = v.node_state(health)
        if leader_live and host == leader_live:
            leader = line
        elif state == "active" and leader_live is None:
            leader = line
        else:
            replicas.append((state, line))

    if queried is None:
        sys.stderr.write("failed to fetch /v1/sys/health from vault nodes\n")
        return 1

    print("scope: vault", flush=True)
    if cluster_name:
        print(f"cluster: {cluster_name}", flush=True)
    if cluster_id:
        print(f"cluster_id: {cluster_id}", flush=True)
    print(f"queried: {queried}:{port}", flush=True)
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
