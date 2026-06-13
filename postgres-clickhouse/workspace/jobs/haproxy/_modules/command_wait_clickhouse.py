#!/usr/bin/env python3
"""Verify ClickHouse HTTP /ping before HAProxy deploy."""

from __future__ import annotations

import sys
import urllib.error
import urllib.request

from maand import allocation_ip, get_kv_value


def check_clickhouse(host: str, port: int, timeout: float = 5) -> None:
    url = f"http://{host}:{port}/ping"
    request = urllib.request.Request(url, method="GET")
    with urllib.request.urlopen(request, timeout=timeout) as response:
        if response.status != 200:
            raise OSError(f"unexpected status {response.status}")


def main() -> int:
    leader = get_kv_value("maand/job/haproxy", "worker_0").strip()
    me = allocation_ip()
    if me != leader:
        print(f"skip clickhouse wait on {me} (checked from {leader})", flush=True)
        return 0

    port = int(get_kv_value("maand", "clickhouse_port_http"))
    workers = [
        ip.strip()
        for ip in get_kv_value("maand/job/clickhouse", "workers").split(",")
        if ip.strip()
    ]
    if not workers:
        sys.stderr.write("no workers in maand/job/clickhouse\n")
        return 1

    for host in workers:
        try:
            check_clickhouse(host, port)
        except (OSError, urllib.error.URLError) as exc:
            sys.stderr.write(
                f"clickhouse pre_deploy check failed: {host}:{port}/ping: {exc}\n"
            )
            return 1
        print(f"clickhouse {host}:{port}/ping ok", flush=True)

    print(f"clickhouse cluster ready ({len(workers)} nodes)", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
