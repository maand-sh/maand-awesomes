#!/usr/bin/env python3
"""Verify ZooKeeper client port is reachable before Patroni deploy."""

from __future__ import annotations

import socket
import sys

from maand import allocation_ip, get_kv_value


def check_zookeeper(host: str, port: int, timeout: float = 5) -> None:
    with socket.create_connection((host, port), timeout=timeout):
        return


def main() -> int:
    # Run the ensemble check once per deploy wave (first postgres allocation).
    leader = get_kv_value("maand/job/postgres", "worker_0").strip()
    me = allocation_ip()
    if me != leader:
        print(f"skip zookeeper wait on {me} (checked from {leader})", flush=True)
        return 0

    port = int(get_kv_value("maand", "zookeeper_port_client"))
    workers = [
        ip.strip()
        for ip in get_kv_value("maand/job/zookeeper", "workers").split(",")
        if ip.strip()
    ]
    if not workers:
        sys.stderr.write("no workers in maand/job/zookeeper\n")
        return 1

    for host in workers:
        try:
            check_zookeeper(host, port)
        except OSError as exc:
            sys.stderr.write(
                f"zookeeper pre_deploy check failed: {host}:{port}: {exc}\n"
            )
            return 1
        print(f"zookeeper {host}:{port} reachable", flush=True)

    print(f"zookeeper ensemble ready ({len(workers)} nodes)", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
