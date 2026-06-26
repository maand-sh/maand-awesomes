# Postgres connections high

## Alerts

- `postgres connections high` — above 85% of `max_connections` for 10 minutes
- `postgres connections critical` — above 95% for 5 minutes

## Diagnosis

```bash
docker exec patroni psql -U postgres -c "SELECT count(*), state FROM pg_stat_activity GROUP BY 1, 2 ORDER BY 1 DESC;"
docker exec patroni psql -U postgres -c "SHOW max_connections;"
docker exec patroni psql -U postgres -c "SELECT pid, usename, application_name, client_addr, state, wait_event_type, query FROM pg_stat_activity WHERE state != 'idle' ORDER BY query_start;"
```

## Remediation

1. Terminate idle-in-transaction sessions if safe
2. Scale connection pooling at the application layer
3. Raise `max_connections` in Patroni only after verifying memory headroom
