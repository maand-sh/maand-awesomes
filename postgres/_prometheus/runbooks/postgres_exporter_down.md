# Postgres exporter down

## Alerts

- `postgres exporter down` — `pg_up == 0` for 5 minutes
- `postgres exporter scrape errors` — exporter cannot collect metrics

## Diagnosis

```bash
maand job_command postgres command_cluster_status
docker ps --filter name=postgres
docker logs postgres-exporter --tail 50
docker logs patroni --tail 50
curl -s http://127.0.0.1:<postgres_port_postgres_exporter>/metrics | head
```

Check Patroni health on the node:

```bash
curl -s -u patroni:<restapi_password> http://127.0.0.1:8008/patroni | python3 -m json.tool
```

## Remediation

1. Confirm patroni container is running: `make -C jobs/postgres restart`
2. Verify `.env` credentials match `secrets/job/postgres` after deploy
3. Check postgres_exporter `DATA_SOURCE_NAME` and TLS settings in `docker-compose.yml`
