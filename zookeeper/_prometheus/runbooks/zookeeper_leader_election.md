# Zookeeper leader election

## Alert

- `zookeeper leader election` — `election_time_count` increased in the last 5 minutes

## Impact

Brief leadership change is normal during rolling restarts. Unexpected elections may cause Patroni failovers or client session expiry.

## Diagnosis

```bash
maand job_command zookeeper command_cluster_status
maand job_command postgres command_cluster_status
docker logs zookeeper --tail 100
```

## Remediation

1. If during deploy, wait for ensemble to stabilize
2. Check network partitions and node restarts
3. Verify only one node was restarted at a time (`deploy_parallel_count: 1`)
