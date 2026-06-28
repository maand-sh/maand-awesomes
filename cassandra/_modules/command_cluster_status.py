#!/usr/bin/env python3
"""Print Cassandra ring status via nodetool on the seed node."""

from __future__ import annotations

import os
import sys

import maand


def seed_ip() -> str:
    return maand.get_kv_value("maand/job/cassandra", "worker_0").strip()


def main() -> int:
    if os.getenv("ALLOCATION_INDEX") != "0":
        return 0

    host = seed_ip()
    if not host:
        sys.stderr.write("no worker_0 in maand/job/cassandra\n")
        return 1

    result = maand.run_ssh(
        host,
        "docker exec cassandra nodetool status",
        check=False,
        timeout=30,
    )
    if result.returncode != 0:
        err = (result.stderr or result.stdout or "").strip()
        sys.stderr.write(f"nodetool status failed on {host}: {err}\n")
        return result.returncode or 1

    print(f"seed: {host}", flush=True)
    print((result.stdout or "").rstrip(), flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
