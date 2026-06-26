# High Memory Usage

## Alerts

- `HighMemoryUsage` — memory usage above 85% for 10 minutes
- `CriticalMemoryUsage` — memory usage above 95% for 5 minutes

## Impact

When available memory is exhausted, the Linux OOM killer terminates processes, causing unexpected service restarts and potential data loss. High memory pressure also degrades performance through excessive swapping.

## Diagnosis

### Check overall memory usage

```bash
free -h
```

### Identify top memory consumers

```bash
ps aux --sort=-%mem | head -20
```

### Check for memory leaks via smaps

```bash
cat /proc/<pid>/status | grep -i vmrss
```

### Check swap usage

```bash
swapon --show
vmstat -s | grep swap
```

### Check OOM kill history

```bash
journalctl -k | grep -i "oom\|killed process" | tail -20
dmesg | grep -i "out of memory" | tail -20
```

## Remediation

### 1. Restart a memory-leaking service

```bash
systemctl restart <service>
```

### 2. Drop OS page cache (safe — kernel will repopulate)

```bash
sync && echo 3 > /proc/sys/vm/drop_caches
```

### 3. Identify and remove unused processes

```bash
kill -15 <pid>
```

### 4. Scale out

Add capacity by increasing the number of workers in `workers.json` and re-running `maand deploy`.

## Escalation

If `CriticalMemoryUsage` fires and the node is close to OOM, escalate immediately to the on-call engineer to restart the node or migrate workloads before data loss occurs.
