# Container Restarting

## Alert

- `container restarting` — a container has restarted at least once in the last 15 minutes

## Impact

Repeated container restarts indicate the process is crashing (OOMKill, unhandled error, failed healthcheck). During each restart cycle the service is unavailable, causing request failures and potential data loss.

## Diagnosis

### Identify which container is restarting

```bash
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.RestartCount}}"
```

### Inspect recent logs for the crash reason

```bash
docker logs --tail 100 <container_id>
```

### Check systemd service status (for non-Docker containers)

```bash
systemctl status <service>
journalctl -u <service> -n 100 --no-pager
```

### Check for OOM kills

```bash
dmesg | grep -i "oom\|killed process" | tail -20
journalctl -k | grep -i "out of memory" | tail -20
```

### Check exit code of the last run

```bash
docker inspect <container_id> --format '{{ .State.ExitCode }} {{ .State.Error }}'
```

## Remediation

### 1. Fix the root cause from the logs

Address whatever error is printed at the end of the logs before the crash (panic, OOM, missing config, etc.).

### 2. If OOMKilled — increase memory limit or reduce usage

```bash
# Increase Docker container memory limit (update compose/run args)
docker update --memory 512m <container_id>
```

### 3. Restart the container manually after fixing the issue

```bash
docker restart <container_id>
# or
systemctl restart <service>
```

## Escalation

If the container continues restarting after addressing the logs, escalate to the application team with the full log output and the exit code.
