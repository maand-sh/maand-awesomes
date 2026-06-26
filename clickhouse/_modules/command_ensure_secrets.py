#!/usr/bin/env python3
"""post_build: generate clickhouse credentials in secrets/job/clickhouse (bootstrap node only)."""

from __future__ import annotations

import secrets

import maand
import clickhouse_lib as ch


_SECRET_KEYS = (
    ("default_password", 24),
    ("interserver_password", 24),
    ("readonly_password", 24),
)


def ensure() -> None:
    if maand.allocation_ip() != ch.bootstrap_ip():
        return

    created: list[str] = []
    for key, nbytes in _SECRET_KEYS:
        if ch.get_job_secret(key):
            continue
        ch.put_job_secret(key, secrets.token_urlsafe(nbytes))
        created.append(key)

    if created:
        ch.log(f"generated secrets: {', '.join(created)}")
    else:
        ch.log("secrets already present in secrets/job/clickhouse")


def main() -> int:
    try:
        ensure()
    except Exception as exc:  # noqa: BLE001
        ch.log(f"secret setup failed ({exc})")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
