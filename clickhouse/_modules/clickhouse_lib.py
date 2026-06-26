#!/usr/bin/env python3
"""Shared ClickHouse helpers for maand job commands."""

from __future__ import annotations

import maand


def log(message: str) -> None:
    print(f"[clickhouse] {message}", flush=True)


def _job_ns(prefix: str) -> str:
    return f"{prefix}/job/{maand.job_name()}"


def get_job_secret(key: str) -> str | None:
    response = maand.get_store_value(_job_ns("secrets"), key)
    if response.status_code == 404:
        return None
    response.raise_for_status()
    return response.json()["value"]


def put_job_secret(key: str, value: str) -> None:
    maand.put_job_secret(key, value).raise_for_status()


def bootstrap_ip() -> str:
    """First clickhouse worker by catalog position (shared secret bootstrap node)."""
    return maand.get_kv_value("maand/job/clickhouse", "worker_0").strip()
