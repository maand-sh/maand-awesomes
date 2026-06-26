#!/usr/bin/env python3
"""cli: re-unseal this Vault node.

Operator helper for after a worker reboot or container restart that left Vault
sealed (Shamir seal does not auto-unseal). Each invocation unseals only its own
ALLOCATION_IP, so running it across the job unseals the whole cluster:

    maand job_command vault command_unseal --concurrency 1

Position order means the leader (vault_0) is handled first. Use after deploy has
initialized the cluster; it does not initialize.
"""

from __future__ import annotations

import sys

import maand
import vault_lib as v


def main() -> int:
    worker_ip = maand.allocation_ip()
    v.wait_for_container(worker_ip)
    v.wait_for_api(worker_ip)

    status = v.vault_status(worker_ip)
    if not status.get("initialized"):
        raise RuntimeError(
            f"{worker_ip}: vault is not initialized; run a deploy to bootstrap first"
        )

    v.ensure_keys_present()
    v.unseal_node(worker_ip)
    v.wait_operational(worker_ip)
    v.log(f"{worker_ip}: operational")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:  # noqa: BLE001 - clean CLI failure
        sys.stderr.write(f"vault unseal failed on {maand.allocation_ip()}: {exc}\n")
        raise SystemExit(1) from exc
