#!/usr/bin/env python3
"""Shared Prometheus helpers for maand job commands."""

from __future__ import annotations

import maand


def log(message: str) -> None:
    print(f"[prometheus] {message}", flush=True)


def primary_ip() -> str:
    return maand.get_kv_value("maand/job/prometheus", "worker_0").strip()


def get_job_secret(key: str) -> str | None:
    response = maand.get_store_value("secrets/job/prometheus", key)
    if response.status_code == 404:
        return None
    response.raise_for_status()
    return response.json()["value"]


def put_job_secret(key: str, value: str) -> None:
    maand.put_job_secret(key, value).raise_for_status()


def admin_username() -> str:
    return get_job_secret("admin_username") or "prometheus"


def admin_password() -> str | None:
    return get_job_secret("admin_password")


def http_port() -> int:
    return int(maand.get_kv_value("maand/bucket", "prometheus_port_http"))
