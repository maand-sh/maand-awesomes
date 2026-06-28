#!/usr/bin/env python3
"""after_allocation_started: apply admin password on the seed node (index 0)."""

from __future__ import annotations

import os
import shlex
import sys
import time

import maand
import cassandra_lib as cs

WAIT_TIMEOUT = 900
WAIT_INTERVAL = 10


def cql_escape(value: str) -> str:
    return value.replace("'", "''")


def cqlsh(host: str, username: str, password: str, cql: str):
    port = cs.cql_port()
    cmd = (
        f"docker exec cassandra cqlsh 127.0.0.1 {port} "
        f"-u {shlex.quote(username)} -p {shlex.quote(password)} "
        f"-e {shlex.quote(cql)}"
    )
    return maand.run_ssh(host, cmd, check=False, timeout=60)


def credentials_ready(host: str, username: str, password: str) -> bool:
    result = cqlsh(host, username, password, "SELECT release_version FROM system.local")
    return result.returncode == 0


def wait_for_cql(host: str, username: str, password: str) -> bool:
    deadline = time.time() + WAIT_TIMEOUT
    while time.time() < deadline:
        if credentials_ready(host, username, password):
            return True
        cs.log(f"still waiting for CQL on {host}:{cs.cql_port()} ...")
        time.sleep(WAIT_INTERVAL)
    return False


def apply_admin_password(host: str, username: str, password: str) -> int:
    if credentials_ready(host, username, password):
        cs.log("admin credentials already configured")
        return 0

    cs.log("waiting for CQL on seed before applying admin password ...")
    if not wait_for_cql(host, "cassandra", "cassandra"):
        sys.stderr.write(f"CQL not ready on {host} within {WAIT_TIMEOUT}s\n")
        return 1

    cql = f"ALTER ROLE {username} WITH PASSWORD = '{cql_escape(password)}'"
    result = cqlsh(host, "cassandra", "cassandra", cql)
    if result.returncode != 0:
        err = (result.stderr or result.stdout or "").strip()
        sys.stderr.write(f"failed to set admin password on {host}: {err}\n")
        return result.returncode or 1

    if not credentials_ready(host, username, password):
        sys.stderr.write(f"admin credentials not accepted on {host} after ALTER ROLE\n")
        return 1

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
