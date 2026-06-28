#!/usr/bin/env python3
"""Shared PostgreSQL / Patroni helpers for maand job commands."""

from __future__ import annotations

import base64
import json
import os
import shlex
import subprocess
import urllib.error
import urllib.request

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
    return int(maand.get_kv_value("maand/bucket", "postgres_port_patroni"))


def pg_port() -> int:
    return int(maand.get_kv_value("maand/bucket", "postgres_port_pg"))


def postgres_exporter_port() -> int:
    return int(maand.get_kv_value("maand/bucket", "postgres_port_postgres_exporter"))


def restapi_credentials() -> tuple[str, str]:
    user = os.environ.get("PATRONI_RESTAPI_USERNAME") or "patroni"
    password = os.environ.get("PATRONI_RESTAPI_PASSWORD") or get_job_secret("restapi_password") or ""
    return user, password


def _fetch_patroni_http(host: str, port: int, timeout: float) -> dict | None:
    """Query Patroni /patroni (local or over the worker network)."""
    url = f"http://{host}:{port}/patroni"
    headers = {"Accept": "application/json"}
    user, password = restapi_credentials()
    if password:
        token = base64.b64encode(f"{user}:{password}".encode()).decode("ascii")
        headers["Authorization"] = f"Basic {token}"
    request = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            return json.loads(response.read().decode())
    except (
        urllib.error.URLError,
        urllib.error.HTTPError,
        TimeoutError,
        json.JSONDecodeError,
    ):
        return None


def fetch_patroni(host: str | None = None, port: int | None = None, timeout: float = 5) -> dict | None:
    """Fetch Patroni node status over HTTP (CLI) or SSH (no allocation context)."""
    port = port if port is not None else patroni_port()
    host = (host or maand.allocation_ip() or leader_ip()).strip()
    if host in ("127.0.0.1", "localhost", "::1"):
        host = (maand.allocation_ip() or leader_ip()).strip()
    if not host:
        return None

    if maand.allocation_ip():
        return _fetch_patroni_http(host, port, timeout)
    return _fetch_patroni_ssh(host, port, timeout)


def fetch_all_patroni_members(
    workers: list[str] | None = None, port: int | None = None, timeout: float = 5
) -> list[dict]:
    """Build member list from /patroni on each postgres worker."""
    port = port if port is not None else patroni_port()
    workers = workers if workers is not None else postgres_workers()
    members: list[dict] = []
    for host in workers:
        info = fetch_patroni(host, port, timeout)
        if info:
            members.append(patroni_to_member(info, host))
    return members


def _fetch_patroni_ssh(host: str, port: int, timeout: float) -> dict | None:
    cmd = (
        f"curl -sf -H 'Accept: application/json' "
        f"http://127.0.0.1:{port}/patroni"
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


def patroni_to_member(info: dict, host: str) -> dict:
    patroni = info.get("patroni") or {}
    role = (info.get("role") or "").lower()
    if role == "primary":
        role = "leader"
    return {
        "name": patroni.get("name") or host,
        "host": host,
        "port": pg_port(),
        "role": role,
        "state": info.get("state"),
    }


def _fetch_cluster_http(host: str, port: int, timeout: float) -> dict | None:
    """Query Patroni /cluster on a worker (REST API listen address)."""
    user, password = restapi_credentials()
    url = f"http://{host}:{port}/cluster"
    headers = {"Accept": "application/json"}
    if password:
        token = base64.b64encode(f"{user}:{password}".encode()).decode("ascii")
        headers["Authorization"] = f"Basic {token}"
    request = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            return json.loads(response.read().decode())
    except (
        urllib.error.URLError,
        urllib.error.HTTPError,
        TimeoutError,
        json.JSONDecodeError,
    ):
        return None


def _fetch_cluster_ssh(host: str, port: int, timeout: float) -> dict | None:
    """Query Patroni /cluster on a remote worker via SSH."""
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


def fetch_cluster(host: str | None = None, port: int | None = None, timeout: float = 5) -> dict | None:
    """Fetch Patroni /cluster over HTTP (CLI) or SSH (no allocation context)."""
    port = port if port is not None else patroni_port()
    allocation = (maand.allocation_ip() or "").strip()
    if allocation:
        return _fetch_cluster_http(allocation, port, timeout)

    host = (host or leader_ip()).strip()
    if host in ("127.0.0.1", "localhost", "::1"):
        host = leader_ip()
    if not host:
        return None
    return _fetch_cluster_ssh(host, port, timeout)


def active_leader_ip(workers: list[str] | None = None, port: int | None = None) -> str | None:
    """Patroni leader IP, or None if the cluster is unreachable."""
    port = port if port is not None else patroni_port()
    workers = workers if workers is not None else postgres_workers()
    cluster = fetch_cluster(port=port)
    if cluster:
        for member in cluster.get("members") or []:
            role = (member.get("role") or "").lower()
            if role in ("leader", "master", "primary"):
                return member.get("host") or member.get("name")
        return None

    if not maand.allocation_ip():
        for host in workers:
            cluster = _fetch_cluster_ssh(host, port, 5)
            if cluster:
                for member in cluster.get("members") or []:
                    role = (member.get("role") or "").lower()
                    if role in ("leader", "master", "primary"):
                        return member.get("host") or member.get("name")
                return None

    for member in fetch_all_patroni_members(workers, port):
        role = (member.get("role") or "").lower()
        if role in ("leader", "master", "primary"):
            return member.get("host") or member.get("name")
    return None


def is_cluster_running(workers: list[str] | None = None, port: int | None = None) -> bool:
    return active_leader_ip(workers, port) is not None
