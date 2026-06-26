#!/usr/bin/env python3
"""pre_deploy: rollout order for first deploy vs rolling upgrade.

  - First deploy (cluster unreachable): bootstrap node first so Patroni
    initializes the primary before replicas join.
  - Rolling upgrade (cluster running): replicas first, Patroni leader last.
"""

from __future__ import annotations

import maand
import postgres_lib as pg


def plan() -> None:
    if maand.allocation_ip() != pg.leader_ip():
        return

    workers = pg.postgres_workers()
    if not workers:
        raise RuntimeError("no workers in maand/job/postgres")

    leader = pg.active_leader_ip(workers) if pg.is_cluster_running(workers) else None

    if leader and leader in workers:
        order = [ip for ip in workers if ip != leader] + [leader]
        pg.log(f"deploy_order: rolling upgrade, leader {leader} last -> {order}")
    else:
        bootstrap = pg.leader_ip()
        order = [bootstrap] + [ip for ip in workers if ip != bootstrap]
        pg.log(f"deploy_order: first deploy, primary first -> {order}")

    maand.put_deploy_order(order).raise_for_status()


def main() -> int:
    try:
        plan()
    except Exception as exc:  # noqa: BLE001 - never block deploy on ordering
        pg.log(f"deploy_order planning skipped ({exc}); using default order")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
