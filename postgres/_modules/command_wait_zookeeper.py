#!/usr/bin/env python3
"""Verify ZooKeeper TLS client port responds before Patroni deploy."""

from __future__ import annotations

import os
import subprocess
import sys

import maand
import postgres_lib as pg
from maand import get_kv_value


def check_zookeeper(host: str, port: int, timeout: float = 10) -> None:
    cert, key, ca = pg.cert_paths("zookeeper_client")
    for path in (cert, key, ca):
        if not os.path.isfile(path):
            raise OSError(f"missing cert file: {path}")

    proc = subprocess.run(
        [
            "openssl",
            "s_client",
            "-connect",
            f"{host}:{port}",
            "-cert",
            cert,
            "-key",
            key,
            "-CAfile",
            ca,
        ],
        input=b"srvr\n",
        capture_output=True,
        timeout=timeout,
        check=False,
    )
    out = (proc.stdout + proc.stderr).decode(errors="replace")
    if proc.returncode != 0:
        raise OSError(out.strip() or f"openssl exit {proc.returncode}")
    if "Verify return code: 0" not in out and "Verification: OK" not in out:
        raise OSError(f"TLS verify failed for {host}:{port}: {out[-500:]}")


def main() -> int:
    leader = pg.leader_ip()
    me = maand.allocation_ip()
    if me != leader:
        print(f"skip zookeeper wait on {me} (checked from {leader})", flush=True)
        return 0

    port = int(get_kv_value("maand", "zookeeper_port_client"))
    workers = [
        ip.strip()
        for ip in get_kv_value("maand/job/zookeeper", "workers").split(",")
        if ip.strip()
    ]
    if not workers:
        sys.stderr.write("no workers in maand/job/zookeeper\n")
        return 1

    for host in workers:
        try:
            check_zookeeper(host, port)
        except (OSError, subprocess.TimeoutExpired) as exc:
            sys.stderr.write(
                f"zookeeper pre_deploy check failed: {host}:{port}: {exc}\n"
            )
            return 1
        print(f"zookeeper {host}:{port} tls ready", flush=True)

    print(f"zookeeper ensemble ready ({len(workers)} nodes)", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
