# clickhouse_keeper

ClickHouse Keeper provides ZooKeeper-compatible coordination for the ClickHouse cluster (replicated tables, distributed DDL). This job runs the `clickhouse-keeper` binary from the official ClickHouse image in a dedicated Raft ensemble.

**Version:** 1.0.5

## Role in the stack

```
clickhouse_keeper  →  clickhouse
```

ClickHouse **must not** deploy until Keeper is healthy. The `clickhouse` job waits for Keeper in `pre_deploy`.

## Worker placement

| Setting | Value |
|---------|-------|
| Selector | `clickhouse_keeper` |
| Example hosts | `10.48.200.3`, `10.48.200.4`, `10.48.198.160` |

Add the label to every worker that should run a Keeper node:

```json
{ "host": "10.48.200.3", "labels": ["clickhouse_keeper", "..."] }
```

Recommended: **3 nodes** for quorum (odd count). All nodes must be reachable on Raft and TLS client ports.

## Configuration

### manifest.json

| Resource | Notes |
|----------|-------|
| `clickhouse_keeper_port_client_tls` | TLS client port (ClickHouse connects here) |
| `clickhouse_keeper_port_raft` | Inter-node Raft |
| `clickhouse_keeper_port_metrics` | Prometheus `/metrics` |

No memory limits in manifest — tune host resources for Keeper + co-located jobs.

### bucket.jobs.conf

No job-specific section. Port numbers and placement come from `maand build`.

### TLS certificates

| Cert | CN | Purpose |
|------|-----|---------|
| `server` | `clickhouse-keeper` | TLS for client and Raft connections |

Certs are issued by the bucket CA and mounted at `./certs/` on each worker.

### Key files

| File | Purpose |
|------|---------|
| `keeper_config.xml.tpl` | Raft ensemble, server ID, TLS, Prometheus |
| `docker-compose.yml.tpl` | Container: `clickhouse/clickhouse-server:26.5`, `clickhouse-keeper` entrypoint |
| `Makefile` | `start`, `stop`, `restart`, data directory permissions |

## Deploy

```bash
maand build
maand deploy --jobs clickhouse_keeper
```

Deploy Keeper **before** ClickHouse on first bootstrap:

```bash
maand deploy --jobs clickhouse_keeper,clickhouse
```

### Health check

HTTP GET `/metrics` on `clickhouse_keeper_port_metrics` — 30 attempts × 1s.

## Commands

| Command | When | Description |
|---------|------|-------------|
| `command_service` | CLI | Marker for downstream jobs (`clickhouse` pre_deploy demand) |

```bash
maand job_command clickhouse_keeper command_service
```

## Monitoring

Scrape config: `_prometheus/scrape.yaml`

- Job name: `clickhouse_keeper`
- Path: `/metrics`
- Target: `maand:port/clickhouse_keeper_port_metrics`

No alert rules defined in this job.

## Operations

### Restart one node

```bash
ssh root@<worker-ip> 'make -C jobs/clickhouse_keeper restart'
```

### Verify metrics

```bash
curl -s http://<worker-ip>:$(maand cat kv get maand/bucket clickhouse_keeper_port_metrics)/metrics | head
```

### Data directories

Keeper stores coordination data under `./data/coordination/` on each worker. Preserve these directories across restarts; losing a majority of nodes requires manual recovery.

## Troubleshooting

| Symptom | Check |
|---------|-------|
| ClickHouse fails to start / replication errors | Keeper `/metrics` on all nodes; Raft connectivity between keeper hosts |
| Health check timeout | `docker logs clickhouse-keeper`; cert permissions in `./certs/` |
| Quorum lost | At least `(N/2)+1` keeper nodes must be up |

## Related jobs

- **clickhouse** — connects via `zookeeper.xml.tpl` to this ensemble
- **clickhouse** — see `OS-TUNING.md` when Keeper is co-located with ClickHouse
