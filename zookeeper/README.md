# zookeeper

Apache ZooKeeper 3.9 ensemble with TLS-only client and quorum ports. Used as Patroni's distributed configuration store for the PostgreSQL cluster.

**Version:** 1.0.2

## Role in the stack

```
zookeeper  →  postgres (Patroni DCS)
```

Not used by ClickHouse (that stack uses **clickhouse_keeper**).

## Worker placement

| Setting | Value |
|---------|-------|
| Selector | `zookeeper` |
| Example hosts | `10.48.200.3`, `10.48.200.4`, `10.48.198.160` |
| Memory | min `512 mb`, max `3584 mb` (manifest) |
| `deploy_parallel_count` | 1 |
| `update_parallel_count` | 1 |

```json
{ "host": "10.48.200.3", "labels": ["zookeeper", "postgres"] }
```

Use an **odd** number of nodes (3 recommended) for quorum.

## Configuration

### bucket.jobs.conf

No job-specific section. Tune memory via bucket if needed (within manifest min/max).

### manifest.json — ports

| Port key | Use |
|----------|-----|
| `zookeeper_port_client` | TLS client connections (Patroni) |
| `zookeeper_port_follower` | Quorum follower |
| `zookeeper_port_election` | Leader election |
| `zookeeper_port_metrics` | Prometheus `/metrics` |

### TLS certificates

| Cert | CN | Notes |
|------|-----|-------|
| `quorum` | `zookeeper` | PKCS#8; used for client + quorum TLS |

`entrypoint.sh` builds a Java keystore from `quorum.crt`, `quorum.key`, and `ca.crt`.

### Key files

| File | Purpose |
|------|---------|
| `docker-compose.yml.tpl` | `zookeeper:3.9`, host network, JVM heap ~75% of job memory |
| `zoo.cfg.tpl` | Ensemble `server.N` lines, TLS ports, autopurge, metrics |
| `entrypoint.sh` | Keystore generation |
| `Makefile` | `start`, `restart`, data/log permissions |

## Dependencies

None upstream. **postgres** depends on this job via `command_wait_zookeeper`.

## Deploy

```bash
maand build
maand deploy --jobs zookeeper
```

Before first Postgres deploy:

```bash
maand deploy --jobs zookeeper,postgres
```

### Rollout order (`command_plan_order`)

| Scenario | Order |
|----------|-------|
| First bootstrap | `server.1` (first worker) first |
| Rolling upgrade | Current leader **last** |

### Health check

- TCP on `zookeeper_port_client`
- HTTP GET `/metrics` on `zookeeper_port_metrics`
- 60 × 2s

## Commands

| Command | When | Description |
|---------|------|-------------|
| `command_plan_order` | pre_deploy | Bootstrap vs rolling order |
| `command_cluster_status` | CLI | Leader/followers via 4lw `stat` |
| `command_service` | CLI | Marker for postgres pre_deploy wait |

### Cluster status

```bash
maand job_command zookeeper command_cluster_status
```

Meaningful output from allocation index 0.

## Monitoring

| Asset | Location |
|-------|----------|
| Scrape | `_prometheus/scrape.yaml.tpl` |
| Alerts | `_prometheus/alerts/alerts.yaml` (7 groups) |
| Runbooks | `_prometheus/runbooks/` |

Alerts: metrics down, quorum at risk, latency, connections, JVM, elections, data growth.

## Operations

### Four-letter words

Allowed: `ruok`, `mntr`, `stat` (configured in `zoo.cfg.tpl`).

### Restart one node

```bash
ssh root@<worker-ip> 'make -C jobs/zookeeper restart'
```

Never restart a majority of nodes simultaneously.

### Verify TLS client port (like Patroni)

```bash
openssl s_client -connect <host>:$(maand cat kv get maand/bucket zookeeper_port_client) \
  -cert jobs/postgres/certs/zookeeper_client.crt \
  -key jobs/postgres/certs/zookeeper_client.key \
  -CAfile jobs/postgres/certs/ca.crt
```

(Postgres client cert — from postgres job workspace on CLI host.)

## Troubleshooting

| Symptom | Check |
|---------|-------|
| Postgres cannot elect leader | `command_cluster_status`; Patroni ZK paths |
| Quorum at risk alert | Number of reachable nodes ≥ `(N/2)+1` |
| Metrics down | `docker logs zookeeper`; metrics port |
| Leader election storm | Disk latency, network partitions |

## Related jobs

- **postgres** — Patroni DCS client (required dependency)
