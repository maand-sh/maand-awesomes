#!/usr/bin/env python3
"""Shared Cassandra helpers for maand job commands."""

from __future__ import annotations

import shlex

import maand


def log(message: str) -> None:
    print(f"[cassandra] {message}", flush=True)


def seed_ip() -> str:
    return maand.get_kv_value("maand/job/cassandra", "worker_0").strip()


def cassandra_workers() -> list[str]:
    return [
        ip.strip()
        for ip in maand.get_kv_value("maand/job/cassandra", "workers").split(",")
        if ip.strip()
    ]


def job_dir() -> str:
    bucket_id = maand.get_kv_value("maand/bucket", "bucket_id")
    return f"/opt/worker/{bucket_id}/jobs/cassandra"


def get_job_secret(key: str) -> str | None:
    response = maand.get_store_value("secrets/job/cassandra", key)
    if response.status_code == 404:
        return None
    response.raise_for_status()
    return response.json()["value"]


def put_job_secret(key: str, value: str) -> None:
    maand.put_job_secret(key, value).raise_for_status()


def admin_username() -> str:
    return get_job_secret("admin_username") or "cassandra"


def admin_password() -> str | None:
    return get_job_secret("admin_password")


def cql_port() -> int:
    return int(maand.get_kv_value("maand/bucket", "cassandra_cql_port"))


def cql_escape(value: str) -> str:
    return value.replace("'", "''")


def cqlsh(host: str, username: str, password: str, cql: str):
    port = cql_port()
    cmd = (
        f"docker exec cassandra cqlsh 127.0.0.1 {port} "
        f"-u {shlex.quote(username)} -p {shlex.quote(password)} "
        f"-e {shlex.quote(cql)}"
    )
    return maand.run_ssh(host, cmd, check=False, timeout=60)


def credentials_ready(host: str, username: str, password: str) -> bool:
    result = cqlsh(host, username, password, "SELECT release_version FROM system.local")
    return result.returncode == 0


def alter_admin_password(host: str, username: str, current_password: str, new_password: str) -> tuple[int, str]:
    cql = f"ALTER ROLE {username} WITH PASSWORD = '{cql_escape(new_password)}'"
    result = cqlsh(host, username, current_password, cql)
    if result.returncode != 0:
        err = (result.stderr or result.stdout or "").strip()
        return result.returncode or 1, err
    if not credentials_ready(host, username, new_password):
        return 1, "new credentials not accepted after ALTER ROLE"
    return 0, ""


def update_worker_env(host: str, password: str) -> tuple[int, str]:
    env_path = f"{job_dir()}/.env"
    password_line = repr(f"CASSANDRA_PASSWORD={password}")
    script = (
        "import pathlib\n"
        f"p = pathlib.Path({env_path!r})\n"
        "lines = []\n"
        "found = False\n"
        "text = p.read_text() if p.is_file() else ''\n"
        "for line in text.splitlines():\n"
        "    if line.startswith('CASSANDRA_PASSWORD='):\n"
        f"        lines.append({password_line})\n"
        "        found = True\n"
        "    else:\n"
        "        lines.append(line)\n"
        "if not found:\n"
        f"    lines.append({password_line})\n"
        "p.parent.mkdir(parents=True, exist_ok=True)\n"
        "p.write_text('\\n'.join(lines) + ('\\n' if lines else ''))\n"
    )
    cmd = f"python3 -c {shlex.quote(script)}"
    result = maand.run_ssh(host, cmd, check=False, timeout=30)
    if result.returncode != 0:
        err = (result.stderr or result.stdout or "").strip()
        return result.returncode or 1, err
    return 0, ""
