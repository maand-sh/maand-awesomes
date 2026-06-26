# High CPU Usage

## Alerts

- `HighCPUUsage` — CPU usage above 85% for 10 minutes
- `CriticalCPUUsage` — CPU usage above 95% for 5 minutes

## Impact

Sustained high CPU usage causes increased request latency, timeouts, and can make the node unresponsive. In production this may trigger cascading failures across dependent services.

## Diagnosis

### Identify top CPU-consuming processes

```bash
top -bn1 | head -30
# or
ps aux --sort=-%cpu | head -20
```

### Check for runaway threads

```bash
top -H -bn1 | head -30
```

### Review recent CPU trends

```bash
sar -u 1 10
```

### Check for CPU throttling (containers / cgroups)

```bash
cat /sys/fs/cgroup/cpu/cpu.stat | grep throttled
```

## Remediation

### 1. Identify and kill runaway process (if safe)

```bash
kill -15 <pid>   # graceful
kill -9 <pid>    # forceful — use as last resort
```

### 2. Restart the offending service

```bash
systemctl restart <service>
```

### 3. Reduce load — re-route traffic away from the node

Update the load balancer or Prometheus alert routing to mark this node degraded.

### 4. Scale out

Add capacity by increasing the number of workers in `workers.json` and re-running `maand deploy`.

## Escalation

If the high CPU cannot be attributed to a known process, escalate to the application team and capture a CPU profile before restarting.
