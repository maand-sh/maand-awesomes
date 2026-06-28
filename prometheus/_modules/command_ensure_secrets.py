#!/usr/bin/env python3
"""post_build: generate Prometheus web UI credentials in secrets/job/prometheus."""

from __future__ import annotations

import secrets
import shutil
import subprocess

import maand
import prometheus_lib as prom


def bcrypt_hash(username: str, password: str) -> str:
    htpasswd = shutil.which("htpasswd")
    if not htpasswd:
        raise RuntimeError("htpasswd not found (required to hash prometheus web password)")

    result = subprocess.run(
        [htpasswd, "-nbBC", "12", username, password],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        err = (result.stderr or result.stdout or "").strip()
        raise RuntimeError(f"htpasswd failed: {err}")

    line = result.stdout.strip()
    if ":" not in line:
        raise RuntimeError(f"unexpected htpasswd output: {line!r}")
    return line.split(":", 1)[1]


def ensure() -> None:
    if maand.allocation_ip() != prom.primary_ip():
        return

    created: list[str] = []
    username = prom.get_job_secret("admin_username")
    if not username:
        username = "prometheus"
        prom.put_job_secret("admin_username", username)
        created.append("admin_username")

    password = prom.get_job_secret("admin_password")
    password_created = False
    if not password:
        password = secrets.token_urlsafe(24)
        prom.put_job_secret("admin_password", password)
        created.append("admin_password")
        password_created = True

    if password_created or not prom.get_job_secret("admin_password_bcrypt"):
        prom.put_job_secret("admin_password_bcrypt", bcrypt_hash(username, password))
        created.append("admin_password_bcrypt")

    if created:
        prom.log(f"generated secrets: {', '.join(created)}")
    else:
        prom.log("secrets already present in secrets/job/prometheus")


def main() -> int:
    try:
        ensure()
    except Exception as exc:  # noqa: BLE001
        prom.log(f"secret setup failed ({exc})")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
