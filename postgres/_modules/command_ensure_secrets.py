#!/usr/bin/env python3
"""post_build: generate postgres credentials in secrets/job/postgres (leader only)."""

from __future__ import annotations

import secrets

import maand
import postgres_lib as pg

_SECRET_KEYS = (
    ("superuser_password", 24),
    ("replication_password", 24),
    ("restapi_password", 24),
)


def ensure() -> None:
    if maand.allocation_ip() != pg.leader_ip():
        return

    created: list[str] = []
    for key, nbytes in _SECRET_KEYS:
        if pg.get_job_secret(key):
            continue
        pg.put_job_secret(key, secrets.token_urlsafe(nbytes))
        created.append(key)

    if created:
        pg.log(f"generated secrets: {', '.join(created)}")
    else:
        pg.log("secrets already present in secrets/job/postgres")


def main() -> int:
    try:
        ensure()
    except Exception as exc:  # noqa: BLE001
        pg.log(f"secret setup failed ({exc})")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
