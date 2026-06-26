# Postgres deadlocks

## Alert

- `postgres deadlocks` — deadlock rate above zero for 5 minutes

## Diagnosis

```bash
docker exec patroni psql -U postgres -c "SELECT * FROM pg_stat_database WHERE datname = 'postgres';"
docker exec patroni psql -U postgres -c "SELECT * FROM pg_locks WHERE NOT granted;"
```

Enable `log_lock_waits` temporarily if needed and inspect patroni/postgres logs.

## Remediation

1. Fix application transaction ordering (consistent lock acquisition order)
2. Keep transactions short; add retries for serialization/deadlock errors
3. Review indexes to reduce lock contention on hot tables
