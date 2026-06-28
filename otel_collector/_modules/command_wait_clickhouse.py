#!/usr/bin/env python3
"""Verify ClickHouse HTTP ping responds before otel_collector deploy (internal mode only)."""

from __future__ import annotations

import json
import os
import ssl
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


def get_kv_optional(namespace: str, key: str, default: str = "") -> str:
    try:
        return get_kv_value(namespace, key).strip()
    except (urllib.error.URLError, OSError, KeyError, json.JSONDecodeError, ValueError):
        return default


def main() -> int:
    mode = get_kv_optional("vars/bucket/job/otel_collector", "clickhouse", "internal")
    if mode == "external":
        print("clickhouse=external; skip internal wait", flush=True)
        return 0

    port_raw = get_kv_optional("maand/bucket", "clickhouse_port_https")
    if not port_raw:
        print("clickhouse_port_https not set; skip wait", flush=True)
        return 0

    workers = [
        ip.strip()
        for ip in get_kv_optional("maand/job/clickhouse", "workers").split(",")
        if ip.strip()
    ]
    if not workers:
        print("no internal clickhouse workers; skip wait", flush=True)
        return 0

    port = int(port_raw)
    for host in workers:
        url = f"https://{host}:{port}/ping"
        try:
            ctx = ssl.create_default_context()
            ctx.check_hostname = False
            ctx.verify_mode = ssl.CERT_NONE
            req = urllib.request.Request(url)
            with urllib.request.urlopen(req, context=ctx, timeout=10) as resp:
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
