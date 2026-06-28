#!/usr/bin/env python3
"""CLI: rotate Cassandra admin password in the cluster and KV."""

from __future__ import annotations

import os
import secrets
import sys

import cassandra_lib as cs


def main() -> int:
    if os.getenv("ALLOCATION_INDEX") != "0":
        return 0

    username = cs.admin_username()
    current_password = cs.admin_password()
    if not current_password:
        sys.stderr.write("admin_password missing in secrets/job/cassandra\n")
        return 1

    host = cs.seed_ip()
    if not host:
        sys.stderr.write("no worker_0 in maand/job/cassandra\n")
        return 1

    if not cs.credentials_ready(host, username, current_password):
        sys.stderr.write(
            f"current admin password from KV does not authenticate on {host}\n"
        )
        return 1

    new_password = secrets.token_urlsafe(24)
    cs.log("rotating admin password on seed ...")
    code, err = cs.alter_admin_password(host, username, current_password, new_password)
    if code != 0:
        sys.stderr.write(f"failed to rotate admin password on {host}: {err}\n")
        return code

    cs.put_job_secret("admin_password", new_password)
    cs.log("updated secrets/job/cassandra admin_password")

    workers = cs.cassandra_workers()
    for worker in workers:
        code, err = cs.update_worker_env(worker, new_password)
        if code != 0:
            sys.stderr.write(f"failed to update .env on {worker}: {err}\n")
            return code
        cs.log(f"updated .env on {worker}")

    cs.log("admin password rotated")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
