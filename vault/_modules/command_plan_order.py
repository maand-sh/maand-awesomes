#!/usr/bin/env python3
"""pre_deploy: choose the rollout order for this deploy via put_deploy_order.

deploy_order (maand/job/vault/deploy_order) drives both deploy_parallel_count
(first-deploy starts) and update_parallel_count (rolling restarts). Default is
catalog/position order (leader vault_0 first).

  - First deploy / cluster unreachable: keep leader (vault_0) FIRST so it
    initializes the cluster before followers join.
  - Rolling restart of a live cluster: restart followers FIRST and the active
    Raft leader LAST, so leadership transfers at most once.

Only the catalog-leader allocation writes the order (idempotent single writer).
Non-fatal: on any error it leaves the default order in place. build resets
deploy_order on the next `maand build`.
"""

from __future__ import annotations

import maand
import vault_lib as v


def plan() -> None:
    if maand.allocation_ip() != v.leader_ip():
        return

    workers = v.vault_workers()
    bootstrapped = v.get_job_var(v.KV_BOOTSTRAPPED) == "true"
    leader = v.active_leader_ip() if bootstrapped else None

    if leader and leader in workers:
        order = [ip for ip in workers if ip != leader] + [leader]
        v.log(f"deploy_order: rolling restart, leader {leader} last -> {order}")
    else:
        order = workers
        v.log(f"deploy_order: bootstrap, leader first -> {order}")

    maand.put_deploy_order(order).raise_for_status()


def main() -> int:
    try:
        plan()
    except Exception as exc:  # noqa: BLE001 - never block deploy on ordering
        v.log(f"deploy_order planning skipped ({exc}); using default order")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
