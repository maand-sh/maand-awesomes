#!/usr/bin/env python3
"""Print ZooKeeper ensemble leader and followers."""

from __future__ import annotations

import os
import sys

import zookeeper_lib as zk


def main() -> int:
    allocation_index = os.getenv("ALLOCATION_INDEX")
    if allocation_index != "0":
        return

    port = zk.client_port()
    workers = zk.zookeeper_workers()
    if not workers:
        sys.stderr.write("no workers in maand/job/zookeeper\n")
        return 1

    leader = None
    replicas: list[tuple[str, str]] = []
    queried = None

    for host in workers:
        fields = zk.fetch_node_stat(host, port)
        if fields is None:
            replicas.append(("unreachable", zk.node_endpoint(host, workers, port)))
            continue
        if queried is None:
            queried = host
        mode = (fields.get("Mode") or "").lower()
        line = zk.node_endpoint(host, workers, port, fields)
        if mode == "leader":
            leader = line
        else:
            replicas.append((mode or "unknown", line))

    if queried is None:
        sys.stderr.write("failed to fetch stat from zookeeper nodes\n")
        return 1

    print(f"ensemble: {len(workers)} nodes", flush=True)
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
