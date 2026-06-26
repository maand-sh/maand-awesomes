# High System Load

## Alert

- `HighSystemLoad` — 1-minute load average per CPU core above 1.5 for 10 minutes

## Impact

A sustained load average above 1.5× the CPU count means the run-queue is backed up. Processes experience scheduling delays, leading to increased latency and degraded throughput for all services on the node.

## Diagnosis

### Check load averages and CPU count

```bash
uptime
nproc
```

### Identify what is driving the load

```bash
# Separate CPU-bound from I/O-bound processes
# D = uninterruptible sleep (I/O wait), R = running
ps aux | awk '$8 ~ /[DR]/' | sort -k3 -rn | head -20
```

### Check I/O wait

```bash
iostat -x 1 5
```

### Check for CPU-intensive processes

```bash
top -bn1 -o %CPU | head -30
```

### Check for blocked I/O

```bash
iotop -o -b -n 3
```

## Remediation

### 1. Reduce I/O pressure — limit a process's I/O

```bash
ionice -c 3 -p <pid>
```

### 2. Reduce CPU priority of non-critical processes

```bash
renice +10 -p <pid>
```

### 3. Restart services generating high I/O

```bash
systemctl restart <service>
```

### 4. Scale out

Add capacity by increasing the number of workers in `workers.json` and re-running `maand deploy`.

## Escalation

If load stays above 2× CPU count and no single process is responsible, escalate to the infrastructure team — the node may be undersized for the current workload.
