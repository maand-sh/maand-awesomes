#!/usr/bin/env python3
"""Verify ClickHouse HTTP ping responds before otel_collector deploy."""

from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.request


def _runtime_api_base_url() -> str:
    host = os.environ.get("JOB_COMMAND_API_HOST", "0.0.0.0")
    return f"http://{host}:8080"


def _runtime_request_headers() -> dict[str, str]:
    return {
        "Content-Type": "application/json",
        "X-ALLOCATION-ID": os.environ["ALLOCATION_ID"],
        "COMMAND": os.environ["COMMAND"],
        "EVENT": os.environ["EVENT"],
    }


def get_kv_value(namespace: str, key: str) -> str:
    body = json.dumps({"namespace": namespace, "key": key}).encode()
    req = urllib.request.Request(
        f"{_runtime_api_base_url()}/kv",
        data=body,
        headers=_runtime_request_headers(),
        method="GET",
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        payload = json.loads(resp.read().decode())
    return payload["value"]


def main() -> int:
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
        url = f"http://{host}:{port}/ping"
        try:
            with urllib.request.urlopen(url, timeout=10) as resp:
                if resp.status != 200:
                    sys.stderr.write(
                        f"clickhouse health check failed: {url} status {resp.status}\n"
                    )
                    return 1
        except (urllib.error.URLError, OSError) as exc:
            sys.stderr.write(f"clickhouse health check failed: {url}: {exc}\n")
            return 1
        print(f"clickhouse {host}:{port} ready", flush=True)

    print(f"clickhouse ready ({len(workers)} nodes)", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
