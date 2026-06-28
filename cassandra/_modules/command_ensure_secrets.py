#!/usr/bin/env python3
"""post_build: generate Cassandra admin credentials in secrets/job/cassandra (seed only)."""

from __future__ import annotations

import secrets

import maand
import cassandra_lib as cs


def ensure() -> None:
    if maand.allocation_ip() != cs.seed_ip():
        return

    created: list[str] = []
    if not cs.get_job_secret("admin_username"):
        cs.put_job_secret("admin_username", "cassandra")
        created.append("admin_username")

    if not cs.get_job_secret("admin_password"):
        cs.put_job_secret("admin_password", secrets.token_urlsafe(24))
        created.append("admin_password")

    if created:
        cs.log(f"generated secrets: {', '.join(created)}")
    else:
        cs.log("secrets already present in secrets/job/cassandra")


def main() -> int:
    try:
        ensure()
    except Exception as exc:  # noqa: BLE001
        cs.log(f"secret setup failed ({exc})")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
