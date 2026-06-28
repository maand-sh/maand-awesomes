#!/usr/bin/env python3
"""health_check: verify Prometheus /-/healthy with basic auth."""

from __future__ import annotations

import base64
import sys
import urllib.error
import urllib.request

import maand


def get_secret(key: str, default: str | None = None) -> str | None:
    response = maand.get_store_value("secrets/job/prometheus", key)
    if response.status_code == 404:
        return default
    response.raise_for_status()
    return response.json()["value"]


def prometheus_url(host: str, port: str, path: str = "/-/healthy") -> str:
    return f"http://{host}:{port}{path}"


def check_http(url: str, username: str, password: str, timeout: float = 10) -> tuple[int, str]:
    auth = base64.b64encode(f"{username}:{password}".encode()).decode()
    request = urllib.request.Request(
        url,
        headers={"Authorization": f"Basic {auth}"},
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            if response.status != 200:
                return response.status, f"status {response.status} want 200"
            return 0, ""
    except urllib.error.HTTPError as exc:
        return exc.code, f"status {exc.code} want 200"
    except urllib.error.URLError as exc:
        return 1, str(exc.reason)


def main() -> int:
    username = get_secret("admin_username", "prometheus")
    password = get_secret("admin_password")
    if not password:
        sys.stderr.write("admin_password missing in secrets/job/prometheus\n")
        return 1

    host = maand.allocation_ip()
    port = maand.get_kv_value("maand/bucket", "prometheus_port_http")
    url = prometheus_url(host, port)

    code, err = check_http(url, username, password)
    if code != 0:
        sys.stderr.write(f"prometheus health check failed on {url}: {err}\n")
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
