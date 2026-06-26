# Copyright 2025 Kiruba Sankar Swaminathan. All rights reserved.
# Use of this source code is governed by a MIT style
# license that can be found in the LICENSE file.

"""
after_allocation_started hook for Cassandra.

With deploy_parallel_count=1 / update_parallel_count=1, maand starts (first deploy)
and restarts (upgrades) one node at a time in deploy_order. deploy_order defaults
to catalog/position order, so the seed (worker_0) comes up first.

After each node's container starts, this hook blocks until that node reports
Up/Normal (UN) in `nodetool status`, so the next node only starts against a settled
ring. Batching + this gate serialize the bootstrap, replacing the old job_control
command, its semaphore, and the manual `make start` orchestration.
"""

import sys
import time

import maand

ALLOCATION_IP = maand.allocation_ip()

WAIT_TIMEOUT = 900
WAIT_INTERVAL = 10


def log(msg):
    print(f"[wait-up] {msg}", flush=True)


def is_node_up(host, target_ip):
    """True if `nodetool status` on host lists target_ip as UN (Up/Normal)."""
    result = maand.run_ssh(
        host,
        "docker exec cassandra nodetool status",
        check=False,
        timeout=30,
    )
    if result.returncode != 0:
        return False
    for line in (result.stdout or "").splitlines():
        parts = line.split()
        # Status line: "UN  10.48.200.1  114 KiB  16  100.0%  <uuid>  rack1"
        if len(parts) >= 2 and parts[0] == "UN" and parts[1] == target_ip:
            return True
    return False


def main():
    log(f"waiting for {ALLOCATION_IP} to be UN ...")
    deadline = time.time() + WAIT_TIMEOUT
    while time.time() < deadline:
        if is_node_up(ALLOCATION_IP, ALLOCATION_IP):
            log(f"{ALLOCATION_IP} is UN")
            return
        time.sleep(WAIT_INTERVAL)
    sys.stderr.write(f"{ALLOCATION_IP} did not reach UN within {WAIT_TIMEOUT}s\n")
    sys.exit(1)


if __name__ == "__main__":
    main()
