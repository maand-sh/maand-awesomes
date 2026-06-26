#!/usr/bin/env python3
"""Shared PostgreSQL / Patroni helpers for maand job commands."""

from __future__ import annotations

import json
import os
import shlex
import subprocess

import maand


def log(message: str) -> None:
    print(f"[postgres] {message}", flush=True)


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


def cert_paths(name: str) -> tuple[str, str, str]:
    cert_dir = os.path.join(os.path.dirname(__file__), "certs")
    return (
        os.path.join(cert_dir, f"{name}.crt"),
        os.path.join(cert_dir, f"{name}.key"),
        os.path.join(cert_dir, "ca.crt"),
    )


def leader_ip() -> str:
    """First postgres worker by catalog position (bootstrap / clonefrom node)."""
    return maand.get_kv_value("maand/job/postgres", "worker_0").strip()


def postgres_workers() -> list[str]:
    return [
        ip.strip()
        for ip in maand.get_kv_value("maand/job/postgres", "workers").split(",")
        if ip.strip()
    ]


def patroni_port() -> int:
    return int(maand.get_kv_value("maand", "postgres_port_patroni"))


def pg_port() -> int:
    return int(maand.get_kv_value("maand", "postgres_port_pg"))


def postgres_exporter_port() -> int:
    return int(maand.get_kv_value("maand", "postgres_port_postgres_exporter"))


def restapi_credentials() -> tuple[str, str]:
    user = os.environ.get("PATRONI_RESTAPI_USERNAME") or "patroni"
    password = os.environ.get("PATRONI_RESTAPI_PASSWORD") or get_job_secret("restapi_password") or ""
    return user, password


def fetch_cluster(host: str | None = None, port: int | None = None, timeout: float = 5) -> dict | None:
    """Fetch Patroni /cluster via SSH (REST API listens on 127.0.0.1 only)."""
    port = port if port is not None else patroni_port()
    host = (host or "127.0.0.1").strip()
    if host in ("127.0.0.1", "localhost", "::1"):
        host = (maand.allocation_ip() or leader_ip()).strip()
    if not host:
        return None

    user, password = restapi_credentials()
    auth = f"-u {shlex.quote(user)}:{shlex.quote(password)} " if password else ""
    cmd = (
        f"curl -sf {auth}-H 'Accept: application/json' "
        f"http://127.0.0.1:{port}/cluster"
    )
    try:
        result = maand.run_ssh(host, cmd, check=False, timeout=int(timeout) + 10)
    except (OSError, subprocess.TimeoutExpired):
        return None
    if result.returncode != 0 or not result.stdout.strip():
        return None
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError:
        return None


def active_leader_ip(workers: list[str] | None = None, port: int | None = None) -> str | None:
    """Patroni leader IP, or None if the cluster is unreachable."""
    port = port if port is not None else patroni_port()
    cluster = fetch_cluster("127.0.0.1", port)
    if not cluster:
        workers = workers if workers is not None else postgres_workers()
        for host in workers:
            cluster = fetch_cluster(host, port)
            if cluster:
                break
    if not cluster:
        return None
    for member in cluster.get("members") or []:
        role = (member.get("role") or "").lower()
        if role in ("leader", "master", "primary"):
            return member.get("host") or member.get("name")
    return None


def is_cluster_running(workers: list[str] | None = None, port: int | None = None) -> bool:
    return active_leader_ip(workers, port) is not None
