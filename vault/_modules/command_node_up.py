#!/usr/bin/env python3
"""after_allocation_started: bring this Vault node to operational.

maand starts/restarts one node at a time (deploy_parallel_count=1 /
update_parallel_count=1) in deploy_order, leader (vault_0) first. After each node's
container starts, this hook runs for that node only:

  - leader: initialize the cluster on first deploy (store unseal keys in KV), then
    unseal.
  - follower: wait for the leader to be operational, ensure unseal keys exist,
    wait until this node is initialized (retry_join), unseal, then join Raft.

Because batches are serialized and the leader runs first, followers always find an
initialized cluster and published unseal keys. No semaphore, no job_control.
"""

from __future__ import annotations

import os
import sys

import maand
import vault_lib as v


def bring_up_leader(leader: str) -> None:
    status = v.vault_status(leader)
    unseal_keys = None
    if not status.get("initialized"):
        unseal_keys = v.init_leader(leader)
    elif v.get_job_secret("unseal_key_1") is None:
        raise RuntimeError(
            f"{leader}: vault initialized on disk but unseal keys are missing from "
            f"secrets/job/{maand.job_name()}. A previous bootstrap failed partway. "
            "Recovery: stop vault and clear ./data on every vault worker, delete the "
            f"{v.KV_INITIALIZED}/{v.KV_BOOTSTRAPPED} vars and vault secrets, redeploy."
        )
    v.unseal_node(leader, unseal_keys=unseal_keys)


def bring_up_follower(worker_ip: str, leader: str) -> None:
    v.wait_operational(leader)
    v.ensure_keys_present()
    v.wait_until_initialized(worker_ip)
    v.unseal_node(worker_ip)


def main() -> int:
    worker_ip = maand.allocation_ip()
    leader = v.leader_ip()
    phase = os.environ.get("DEPLOY_PHASE", "")
    v.log(f"node_up {worker_ip} (leader={leader}, phase={phase or 'n/a'})")

    v.wait_for_container(worker_ip)
    v.wait_for_api(worker_ip)

    if worker_ip == leader:
        bring_up_leader(leader)
    else:
        bring_up_follower(worker_ip, leader)

    v.wait_operational(worker_ip)
    v.log(f"{worker_ip}: operational")

    # The last node to come up (cluster fully operational) records completion.
    # Informational only — nothing gates on it. Serialized batches make this safe.
    if v.get_job_var(v.KV_BOOTSTRAPPED) != "true" and all(
        v.is_operational(ip) for ip in v.vault_workers()
    ):
        v.mark_bootstrapped(leader)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:  # noqa: BLE001 - surface a clean deploy failure
        sys.stderr.write(f"vault node_up failed on {maand.allocation_ip()}: {exc}\n")
        raise SystemExit(1) from exc
