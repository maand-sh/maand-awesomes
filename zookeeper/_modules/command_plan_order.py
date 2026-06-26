#!/usr/bin/env python3
"""pre_deploy: rollout order for first deploy vs rolling upgrade.

  - First deploy (ensemble unreachable): server.1 first so quorum can form.
  - Rolling upgrade (ensemble running): followers first, ZooKeeper leader last.
"""

from __future__ import annotations

import maand
import zookeeper_lib as zk


def plan() -> None:
    if maand.allocation_ip() != zk.leader_ip():
        return

    workers = zk.zookeeper_workers()
    if not workers:
        raise RuntimeError("no workers in maand/job/zookeeper")

    leader = zk.active_leader_ip(workers) if zk.is_cluster_running(workers) else None

    if leader and leader in workers:
        order = [ip for ip in workers if ip != leader] + [leader]
        zk.log(f"deploy_order: rolling upgrade, leader {leader} last -> {order}")
    else:
        bootstrap = zk.leader_ip()
        order = [bootstrap] + [ip for ip in workers if ip != bootstrap]
        zk.log(f"deploy_order: first deploy, {bootstrap} first -> {order}")

    maand.put_deploy_order(order).raise_for_status()


def main() -> int:
    try:
        plan()
    except Exception as exc:  # noqa: BLE001 - never block deploy on ordering
        zk.log(f"deploy_order planning skipped ({exc}); using default order")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
