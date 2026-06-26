# Disk Usage High

## Alerts

- `DiskUsageHigh` — root filesystem usage above 85%
- `DiskUsageCritical` — root filesystem usage above 95%
- `DiskWillFillIn24h` — disk predicted to be full within 24 hours

## Impact

When disk usage is critically high, the node can no longer write logs, temporary files, or application data. This can cause service crashes, failed deployments, and data loss.

## Diagnosis

### Check current disk usage

```bash
df -h
```

### Find the largest directories

```bash
du -sh /* 2>/dev/null | sort -rh | head -20
```

### Check for large log files

```bash
find /var/log -type f -name "*.log" -size +100M | xargs ls -lh
```

### Check for large core dumps

```bash
find / -name "core" -type f 2>/dev/null | xargs ls -lh
```

## Remediation

### 1. Rotate or truncate logs

```bash
journalctl --vacuum-size=500M
```

### 2. Remove old Docker images and containers

```bash
docker system prune -af
```

### 3. Clear package manager caches

```bash
apt-get clean        # Debian/Ubuntu
yum clean all        # RHEL/CentOS
```

### 4. Remove old kernel packages

```bash
# Ubuntu
apt-get autoremove --purge
```

## Escalation

If disk cannot be freed quickly, escalate to the on-call infrastructure engineer to expand the volume or attach additional storage.
