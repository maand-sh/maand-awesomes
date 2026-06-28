#!/usr/bin/env python3
"""Verify ClickHouse Keeper metrics respond before ClickHouse deploy."""

from __future__ import annotations

import sys
import urllib.error
import urllib.request

import maand
import clickhouse_lib as ch


def main() -> int:
    me = maand.allocation_ip()
    bootstrap = ch.bootstrap_ip()
    if me != bootstrap:
        print(
            f"skip clickhouse-keeper wait on {me} (checked from {bootstrap})",
            flush=True,
        )
        return 0

    port = int(maand.get_kv_value("maand/bucket", "clickhouse_keeper_port_metrics"))
    workers = [
        ip.strip()
        for ip in maand.get_kv_value("maand/job/clickhouse_keeper", "workers").split(",")
        if ip.strip()
    ]
    if not workers:
        sys.stderr.write("no workers in maand/job/clickhouse_keeper\n")
        return 1

    for host in workers:
        url = f"http://{host}:{port}/metrics"
        try:
            with urllib.request.urlopen(url, timeout=10) as resp:
                if resp.status != 200:
                    sys.stderr.write(
                        f"clickhouse-keeper health check failed: {url} status {resp.status}\n"
                    )
                    return 1
        except (urllib.error.URLError, OSError) as exc:
            sys.stderr.write(f"clickhouse-keeper health check failed: {url}: {exc}\n")
            return 1
        print(f"clickhouse-keeper {host}:{port} ready", flush=True)

    print(f"clickhouse-keeper ready ({len(workers)} nodes)", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
