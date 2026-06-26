# Postgres replication lag

## Alerts

- `postgres replication lag` — lag above 60s for 5 minutes
- `postgres replication stalled` — lag above 300s for 2 minutes

## Diagnosis

```bash
maand job_command postgres command_cluster_status
docker exec patroni psql -U postgres -c "SELECT * FROM pg_stat_replication;"
docker exec patroni psql -U postgres -c "SELECT pg_is_in_recovery();"
```

## Remediation

1. Check network between primary and replicas
2. Inspect long transactions blocking replay on the standby
3. Verify zookeeper ensemble is healthy: `maand job_command zookeeper command_cluster_status`
4. If a replica is far behind, consider reinit from primary (Patroni basebackup)
