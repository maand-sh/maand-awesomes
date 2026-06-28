# postgres

Highly available PostgreSQL 16 cluster managed by Patroni, with ZooKeeper as DCS, TLS everywhere, and postgres_exporter for Prometheus.

**Version:** 2.5.9

## Role in the stack

```
zookeeper  →  postgres
```

Patroni stores cluster state in ZooKeeper over mutual TLS. Clients connect to PostgreSQL on the TLS-enabled `postgres_port_pg`.

## Worker placement

| Setting | Value |
|---------|-------|
| Selector | `postgres` (implicit — job name when manifest omits selectors) |
| Example hosts | `10.48.200.3`, `10.48.200.4` |
| `deploy_parallel_count` | 1 |
| `update_parallel_count` | 1 |

```json
{ "host": "10.48.200.3", "labels": ["postgres", "zookeeper", "..."] }
```

## Configuration

### bucket.jobs.conf

```toml
[postgres]
memory = "6024 mb"
cpu = "4800 mhz"
# optional — omit or leave empty for per-worker /32 only
replication_subnet = "10.48.0.0/16,10.48.1.0/24"
```

Settings sync to KV `vars/bucket/job/postgres`. `memory` must be within manifest bounds: min `4 gb`, max `64 gb`. Memory drives PostgreSQL tuning in `patroni.yml.tpl` (shared_buffers, effective_cache_size, shm_size, etc.).

`replication_subnet` is optional. When set, adds one `hostssl replication replicator <subnet> scram-sha-256` line per comma-separated CIDR (spaces trimmed). Per-worker `/32` rules are always added from `maand/job/postgres` `workers`.

After editing: `maand build && maand deploy --jobs postgres`.

### manifest.json — ports

| Port key | Use |
|----------|-----|
| `postgres_port_pg` | PostgreSQL (TLS) |
| `postgres_port_patroni` | Patroni REST API |
| `postgres_port_postgres_exporter` | Prometheus metrics |

### Secrets

Generated at `post_build` on leader (`worker_0`) only:

| Secret | Purpose |
|--------|---------|
| `superuser_password` | PostgreSQL superuser |
| `replication_password` | Replication user `replicator` |
| `restapi_password` | Patroni REST API |

```bash
maand cat kv get secrets/job/postgres superuser_password
```

### TLS certificates

| Cert | CN | Notes |
|------|-----|-------|
| `server` | `postgres` | PostgreSQL and Patroni |
| `zookeeper_client` | `postgres-zookeeper-client` | PKCS#8, one cert for all nodes |

Certs are copied to `/run/patroni/certs` at container start (writable by Patroni uid 999).

### Key files

| File | Purpose |
|------|---------|
| `docker-compose.yml.tpl` | Patroni image + postgres-exporter sidecar |
| `patroni.yml.tpl` | Cluster config, ZK DCS, PG tuning, SSL |
| `.env.tpl` | Passwords from secrets |
| `entrypoint.sh` | Cert copy, permissions |
| `Containerfile` | Custom Patroni image (PG 16, Patroni 4.0.6) |
| `post-init.sh.tpl` | Enables `pg_stat_statements` |
| `Makefile` | `build`, `start`, `restart`, permission fixes |

Build the image on workers before first deploy:

```bash
make -C workspace/jobs/postgres build   # or via maand deploy staging
```

## Dependencies

| Hook | Upstream | Description |
|------|----------|-------------|
| `command_wait_zookeeper` (pre_deploy) | `zookeeper` / `command_service` | Leader node verifies ZK TLS on all ensemble members |
| `command_plan_order` (pre_deploy) | — | First deploy: bootstrap primary first; rolling upgrade: leader last |

Deploy ZooKeeper before Postgres:

```bash
maand deploy --jobs zookeeper,postgres
```

## Deploy

```bash
maand build
maand deploy --jobs postgres
```

### Health check

TCP connect on `postgres_port_pg` — 36 × 5s.

## Commands

| Command | When | Description |
|---------|------|-------------|
| `command_ensure_secrets` | post_build | Generate passwords (leader only) |
| `command_plan_order` | pre_deploy | Set rollout order |
| `command_wait_zookeeper` | pre_deploy | Wait for ZK TLS |
| `command_cluster_status` | CLI | Print leader and replicas |
| `command_service` | CLI | Marker for dependents |

### Cluster status

```bash
maand job_command postgres command_cluster_status
```

Example output:

```
master: 10.48.200.3 (10.48.200.3:30009) state=running
replicas: [replica] 10.48.200.4 ...
```

Runs meaningful checks from allocation index 0 only.

## Monitoring

| Asset | Location |
|-------|----------|
| Scrape | `_prometheus/scrape.yaml.tpl` → postgres-exporter |
| Alerts | `_prometheus/alerts/alerts.yaml` |
| Runbooks | `_prometheus/runbooks/` |

Alerts: exporter down, replication lag, connections, deadlocks.

## Operations

### Connect to primary

```bash
psql "host=<leader-ip> port=$(maand cat kv get maand/bucket postgres_port_pg) user=postgres sslmode=require"
```

### Rolling restart

Deploy uses `update_parallel_count: 1` and leader-last order on upgrades.

### Manual restart on a node

```bash
ssh root@<worker-ip> 'make -C jobs/postgres restart'
```

## Troubleshooting

| Symptom | Check |
|---------|-------|
| No leader / partial cluster | `command_cluster_status`; Patroni logs; ZK connectivity and cert permissions |
| ZK permission denied | `entrypoint.sh` copies certs to `/run/patroni/certs`; key mode 0600 |
| `command_wait_zookeeper` fails | `maand job_command zookeeper command_cluster_status`; openssl to client port |
| Replication lag alerts | Network, disk, `pg_stat_replication` on primary |

## Related jobs

- **zookeeper** — required DCS for Patroni
