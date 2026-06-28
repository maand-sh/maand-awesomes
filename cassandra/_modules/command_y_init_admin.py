#!/usr/bin/env python3
"""after_allocation_started: apply admin password on the seed node (index 0)."""

from __future__ import annotations

import os
import sys
import time

import cassandra_lib as cs

WAIT_TIMEOUT = 900
WAIT_INTERVAL = 10
DEFAULT_PASSWORD = "cassandra"


def wait_for_cql_auth(host: str, username: str, password: str) -> str | None:
    """Wait for CQL auth. Returns 'configured', 'default', or None on timeout."""
    deadline = time.time() + WAIT_TIMEOUT
    while time.time() < deadline:
        if cs.credentials_ready(host, username, password):
            return "configured"
        if password != DEFAULT_PASSWORD and cs.credentials_ready(host, username, DEFAULT_PASSWORD):
            return "default"
        cs.log(f"still waiting for CQL on {host}:{cs.cql_port()} ...")
        time.sleep(WAIT_INTERVAL)
    return None


def apply_admin_password(host: str, username: str, password: str) -> int:
    cs.log("waiting for CQL on seed before applying admin password ...")
    state = wait_for_cql_auth(host, username, password)
    if state is None:
        sys.stderr.write(f"CQL not ready on {host} within {WAIT_TIMEOUT}s\n")
        return 1

    if state == "configured":
        cs.log("admin credentials already configured")
        return 0

    code, err = cs.alter_admin_password(host, username, DEFAULT_PASSWORD, password)
    if code != 0:
        sys.stderr.write(f"failed to set admin password on {host}: {err}\n")
        return code

    cs.log("admin credentials configured on seed")
    return 0


def main() -> int:
    if os.getenv("ALLOCATION_INDEX") != "0":
        return 0

    password = cs.admin_password()
    if not password:
        sys.stderr.write("admin_password missing in secrets/job/cassandra\n")
        return 1

    host = cs.seed_ip()
    if not host:
        sys.stderr.write("no worker_0 in maand/job/cassandra\n")
        return 1

    return apply_admin_password(host, cs.admin_username(), password)


if __name__ == "__main__":
    raise SystemExit(main())
