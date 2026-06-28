# clickhouse

Distributed ClickHouse cluster with TLS-only access, replication via ClickHouse Keeper, and built-in Prometheus metrics.

**Version:** 1.4.1

## Role in the stack

```
clickhouse_keeper  →  clickhouse
```

## Worker placement

| Setting | Value |
|---------|-------|
| Selector | `clickhouse` |
| Example hosts | `10.48.200.1`, `10.48.200.2`, `10.48.200.3`, `10.48.200.4` |

```json
{ "host": "10.48.200.1", "labels": ["clickhouse"] }
```

Memory is set in **`workspace/bucket.jobs.conf`**:

```toml
[clickhouse]
memory = "2048 mb"
cpu = "9600 mhz"
```

| Key | Purpose |
|-----|---------|
| `memory` | Docker memory limit; server/query memory in `memory.xml.tpl` and `users.xml.tpl` |
| `cpu` | Maand CPU reservation (MHz); Docker CPU limit, `max_threads`, and background pools |

`memory` must be within manifest bounds (min `2048 mb`, max `11264 mb`). `cpu` must be within min `2400 mhz`, max `76800 mhz`.

Thread and pool sizes scale from **logical cores** (`cpu ÷ 2400 MHz`), using a **32-core** reference profile. Example: `cpu = "9600 mhz"` → 4 cores (`max_threads = 4`, `background_pool_size = 3`).

Workers must declare `cpu` in `workers.json` when ClickHouse reserves CPU (maand validates total job CPU against worker capacity).

The same values apply to every ClickHouse allocation. On crowded 12 GB workers, keep reservations low. Raise `memory` and `cpu` on dedicated ClickHouse nodes only.

After editing: `maand build && maand deploy --jobs clickhouse`.

### manifest.json — ports

Ports use `{}` — assigned from `bucket.conf` pool, stored in KV `maand/bucket`. Templates: `get "maand/bucket" "<port_name>"`.

| Port key | Protocol | Use |
|----------|----------|-----|
| `clickhouse_port_https` | HTTPS | HTTP interface (TLS only; plain HTTP disabled) |
| `clickhouse_port_native_tls` | Native TCP + TLS | Clients, inter-node native protocol |
| `clickhouse_port_interserver_tls` | HTTPS | Replication fetch |
| `clickhouse_port_metrics` | HTTP | Built-in Prometheus `/metrics` |

### bucket.jobs.conf

See **Memory** above. No other keys for this job.

### Secrets

Generated at `post_build` on the bootstrap node (`worker_0`) by `command_ensure_secrets`:

| Secret | Used by |
|--------|---------|
| `default_password` | `default` user |
| `interserver_password` | `interserver` replication user |
| `readonly_password` | `readonly` user |

```bash
maand cat kv get secrets/job/clickhouse default_password
```

Secrets are idempotent — existing values are not rotated on rebuild.

### TLS certificates

| Cert | CN |
|------|-----|
| `server` | `clickhouse` |

Mounted at `/etc/clickhouse-server/certs/` in the container.

### Key template files

| File | Purpose |
|------|---------|
| `docker-compose.yml.tpl` | `clickhouse/clickhouse-server:26.5`, host network, all config mounts |
| `.env.tpl` | Passwords from secrets |
| `tls.xml.tpl` | TLS-only listeners; removes plain HTTP/TCP |
| `cluster.xml.tpl` | Replicated cluster definition |
| `zookeeper.xml.tpl` | ClickHouse Keeper ensemble (TLS) |
| `macros.xml.tpl` | `{shard}`, `{replica}` from allocation index |
| `interserver.xml.tpl` | Inter-server HTTPS replication |
| `users.xml.tpl` | Users, profiles, quotas |
| `memory.xml.tpl` | Server memory and cache limits |
| `prometheus-exporter.xml.tpl` | `/metrics` endpoint |

Host tuning: see **`OS-TUNING.md`** and run `sudo ./apply-os-tuning.sh apply` on ClickHouse workers (THP, ulimits, sysctl).

## Dependencies

| Hook | Upstream | Description |
|------|----------|-------------|
| `command_wait_clickhouse_keeper` (pre_deploy) | `clickhouse_keeper` / `command_service` | Bootstrap node pings Keeper `/metrics` on all keeper workers |

Deploy order is enforced by `deployment_seq`: Keeper first, then ClickHouse.

## Deploy

```bash
maand build
maand deploy --jobs clickhouse_keeper,clickhouse
```

### Health check

HTTP GET `/metrics` on `clickhouse_port_metrics` — 30 × 1s.

## Commands

| Command | When | Description |
|---------|------|-------------|
| `command_ensure_secrets` | post_build | Generate passwords on bootstrap node |
| `command_wait_clickhouse_keeper` | pre_deploy | Wait for Keeper readiness |
| `command_service` | CLI | Marker for dependent jobs |

```bash
maand job_command clickhouse command_service
```

## Monitoring

Scrape: `_prometheus/scrape.yaml` — job `clickhouse`, path `/metrics`.

No alert rules in this job.

### Connect for queries

HTTPS (replace port from KV):

```bash
curl -k "https://<host>:$(maand cat kv get maand/bucket clickhouse_port_https)/ping"
```

Native TLS clients use `clickhouse_port_native_tls`.

## Operations

### Restart

```bash
ssh root@<worker-ip> 'make -C jobs/clickhouse restart'
```

Data lives in `./data/` (UID 101). `make fix-data-perms` corrects ownership after manual edits.

### Upgrade ClickHouse version

1. Bump image tag in `docker-compose.yml.tpl`
2. Bump `version` in `manifest.json`
3. `maand build && maand deploy --jobs clickhouse`

Rolling: one node at a time; replication catches up via Keeper.

## Troubleshooting

| Symptom | Check |
|---------|-------|
| Replication not working | Keeper health; `zookeeper.xml.tpl` hosts match keeper workers |
| `BAD_ARGUMENTS` / `number_of_free_entries_in_pool_to_execute_mutation` on start | `merge_tree.xml.tpl` pool settings must be ≤ `background_pool_size × ratio` from `threadpool.xml.tpl` |
| Permission denied on data | `make fix-data-perms`; logs for uid 101 |
| THP warnings in logs | Run `apply-os-tuning.sh` per `OS-TUNING.md` |

## Related jobs

- **clickhouse_keeper** — coordination (required)
