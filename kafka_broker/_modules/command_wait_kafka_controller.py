#!/usr/bin/env python3
"""Verify Kafka controller quorum port is reachable before broker deploy."""

from __future__ import annotations

import socket
import sys

from maand import allocation_ip, get_kv_value


def check_controller(host: str, port: int, timeout: float = 5) -> None:
    with socket.create_connection((host, port), timeout=timeout):
        return


def main() -> int:
    # Run the quorum check once per deploy wave (first kafka_broker allocation).
    leader = get_kv_value("maand/job/kafka_broker", "worker_0").strip()
    me = allocation_ip()
    if me != leader:
        print(f"skip kafka_controller wait on {me} (checked from {leader})", flush=True)
        return 0

    port = int(get_kv_value("maand", "kafka_controller_port_controller"))
    workers = [
        ip.strip()
        for ip in get_kv_value("maand/job/kafka_controller", "workers").split(",")
        if ip.strip()
    ]
    if not workers:
        sys.stderr.write("no workers in maand/job/kafka_controller\n")
        return 1

    for host in workers:
        try:
            check_controller(host, port)
        except OSError as exc:
            sys.stderr.write(
                f"kafka_controller pre_deploy check failed: {host}:{port}: {exc}\n"
            )
            return 1
        print(f"kafka_controller {host}:{port} reachable", flush=True)

    print(f"kafka_controller quorum ready ({len(workers)} nodes)", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
