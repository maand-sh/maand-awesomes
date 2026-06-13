# ClickHouse OS-level tuning

Apply these settings on Linux hosts running ClickHouse (and ClickHouse Keeper when co-located). Your ClickHouse logs will warn about **transparent hugepages** and **delay accounting** until they are fixed.

**Automated script:** run `sudo ./apply-os-tuning.sh apply` on each worker (see `./apply-os-tuning.sh check` to verify).

Target hosts in this bucket: `10.48.200.3`, `10.48.200.4` (ClickHouse + Keeper, 32 GB RAM, 32 vCPU).

---

## Priority order

1. **Transparent huge pages (THP)** — biggest impact on latency and stability
2. **Swappiness + file descriptor limits** on the host
3. **Delay accounting** — enables `OSIOWaitMicroseconds` metrics (not required for startup)
4. **Network sysctl** — helps under replication and distributed query load
5. **Disk layout and mount options** — long-term throughput

---

## 1. Transparent huge pages (required)

ClickHouse recommends disabling THP or setting it to `madvise`. Avoid `always`.

```bash
# Immediate (until reboot)
echo madvise | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
echo madvise | sudo tee /sys/kernel/mm/transparent_hugepage/defrag
```

Persistent via systemd:

```bash
sudo tee /etc/systemd/system/disable-thp.service <<'EOF'
[Unit]
Description=Disable Transparent Huge Pages for ClickHouse
After=sysinit.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo madvise > /sys/kernel/mm/transparent_hugepage/enabled'
ExecStart=/bin/sh -c 'echo madvise > /sys/kernel/mm/transparent_hugepage/defrag'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable --now disable-thp.service
```

Verify:

```bash
cat /sys/kernel/mm/transparent_hugepage/enabled
# expected: always madvise [never]  OR  [madvise] never always
```

---

## 2. File descriptor limits

The ClickHouse job sets `ulimits.nofile: 262144` in Docker. Also configure the host for the `clickhouse` user:

```bash
sudo tee /etc/security/limits.d/clickhouse.conf <<'EOF'
clickhouse soft nofile 262144
clickhouse hard nofile 262144
EOF
```

Verify after restart:

```bash
pid=$(pgrep -f clickhouse-server | head -1)
grep "open files" /proc/$pid/limits
```

---

## 3. Swappiness

Keep ClickHouse data in RAM; avoid swapping hot pages.

```bash
sudo tee /etc/sysctl.d/99-clickhouse.conf <<'EOF'
vm.swappiness = 1
EOF

sudo sysctl --system
```

---

## 4. Delay accounting (metrics)

Enables IO wait metrics in ClickHouse (`OSIOWaitMicroseconds`). Without this you see:

```text
Delay accounting is not enabled, OSIOWaitMicroseconds will not be gathered
```

Add to `/etc/sysctl.d/99-clickhouse.conf`:

```ini
kernel.task_delayacct = 1
```

Apply:

```bash
sudo sysctl --system
```

Reboot recommended so all processes pick up delay accounting.

---

## 5. Network sysctl

Useful for replication, inter-server traffic (port 9009), and HTTP/native clients.

Add to `/etc/sysctl.d/99-clickhouse.conf`:

```ini
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 4096
net.core.netdev_max_backlog = 250000
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 5
```

Apply:

```bash
sudo sysctl --system
```

---

## 6. Disk and filesystem

| Item | Recommendation |
|------|----------------|
| Filesystem | XFS or ext4 |
| Mount options | `noatime` (or `relatime`) on data volumes |
| Layout | Dedicated disk for data; separate from OS |
| RAID | RAID10 for production writes; avoid RAID5/6 for heavy ingest |
| SSD | Enable `fstrim` timer |

Example `fstab` entry:

```text
/dev/md0 /var/lib/clickhouse xfs defaults,noatime 0 0
```

This job bind-mounts `./data` → `/var/lib/clickhouse` under the maand job directory. Ensure that host path sits on fast, dedicated storage with `noatime` if possible.

---

## 7. CPU governor (bare metal / fixed CPU VMs)

```bash
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

Skip on cloud instances without cpufreq controls.

---

## 8. Optional memory settings

Only if you hit specific limits:

```ini
# /etc/sysctl.d/99-clickhouse.conf
vm.max_map_count = 262144
```

Do **not** set `vm.overcommit_memory` unless you understand the tradeoffs.

---

## 9. NUMA (multi-socket hosts only)

On single-socket 8-core nodes (typical here), NUMA tuning is usually unnecessary.

On multi-socket servers:

```bash
numactl --hardware
```

Pin ClickHouse to one socket or use `numactl --interleave=all` for memory.

---

## Complete sysctl example

`/etc/sysctl.d/99-clickhouse.conf`:

```ini
vm.swappiness = 1
kernel.task_delayacct = 1
vm.max_map_count = 262144

net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 4096
net.core.netdev_max_backlog = 250000
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 5
```

```bash
sudo sysctl --system
```

---

## Verify on host

Run on each ClickHouse worker before or after deploy:

```bash
echo "THP enabled:     $(cat /sys/kernel/mm/transparent_hugepage/enabled)"
echo "delayacct:         $(sysctl -n kernel.task_delayacct)"
echo "swappiness:        $(sysctl -n vm.swappiness)"
echo "somaxconn:         $(sysctl -n net.core.somaxconn)"
echo "data mount opts:   $(findmnt -no OPTIONS /opt/worker/*/jobs/clickhouse/data 2>/dev/null | head -1)"
```

---

## Already configured in this job

The maand ClickHouse job (`docker-compose.yml.tpl`) sets:

- `ulimits.nofile: 262144`
- `network_mode: host`
- Bind mounts: `./data`, `./logs`
- `user: clickhouse` (UID 101) via Makefile `fix-data-perms`

Host-level items above are still required; Docker ulimits do not replace THP, sysctl, or host `limits.d` configuration.

---

## References

- [ClickHouse production recommendations](https://clickhouse.com/docs/operations/tips)
- [Transparent huge pages](https://clickhouse.com/docs/knowledgebase/configure-htap-latency-with-real-time-monitoring-and-tracing#transparent-huge-pages)
