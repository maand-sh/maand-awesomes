# coroot_node_agent

Coroot node agent collects host and container metrics, eBPF traces, and logs. Runs on **every worker** in the bucket.

**Version:** 1.0.4

## Role in the stack

```
coroot_node_agent  --metrics-->  prometheus (scrape)
                 --OTLP (optional)-->  otel_collector  -->  clickhouse / prometheus
```

otel_collector is **optional**. Without it, the agent still exposes Prometheus metrics locally.

## Worker placement

| Setting | Value |
|---------|-------|
| Selector | `worker` (all catalog workers) |
| `update_parallel_count` | 4 (rolling updates) |
| Memory | min `256 mb`, max `1024 mb` (manifest); default `768 mb` in `bucket.jobs.conf` |

Every worker in `workers.json` receives an allocation automatically (label `worker` is implicit).

## Configuration

### manifest.json — ports

| Port key | Use |
|----------|-----|
| `coroot_node_agent_port_metrics` | HTTP `/metrics` for Prometheus |

### bucket.jobs.conf

No job-specific section.

### OTLP export (automatic)

When **both** conditions are true:

1. Job `otel_collector` has an active allocation (`otel_collector` appears in `maand/bucket` **`activejobs`**)
2. At least one worker has the `otel_collector` label and otel_collector is allocated (`maand/worker/otel_collector_workers` is set)

the template adds:

```
--logs-endpoint=http://<otel-host>:<port>/v1/logs
--traces-endpoint=http://<otel-host>:<port>/v1/traces
```

**Deploy order:** allocate and deploy `otel_collector` before `coroot_node_agent`, or deploy coroot first without otel in the bucket.

### Key files

| File | Purpose |
|------|---------|
| `docker-compose.yml.tpl` | Privileged agent, host PID/cgroup, Docker socket |
| `Makefile` | `start` / `restart` use `--force-recreate` (host network listen port) |

### Container requirements

- `privileged: true`
- Host mounts: `/sys/kernel/tracing`, `/sys/kernel/debug`, cgroups, Docker socket (read-only)
- WAL directory: `./data`

## Deploy

```bash
maand build
maand deploy --jobs coroot_node_agent
```

With observability pipeline:

```bash
maand deploy --jobs otel_collector,coroot_node_agent
```

### Health check

HTTP GET `/metrics` on metrics port — 60 × 2s.

## Monitoring

| Asset | Location |
|-------|----------|
| Scrape config | `_prometheus/scrape.yaml.tpl` |
| Alerts | `_prometheus/alerts/alerts.yaml` |
| Runbooks | `_prometheus/runbooks/` |

Alert groups cover availability, CPU, memory, disk, network, and containers.

### Example queries

```promql
up{maand_job="coroot_node_agent"}
```

## Commands

None registered in manifest.

## Operations

### Restart on a worker

```bash
ssh root@<worker-ip> 'make -C jobs/coroot_node_agent restart'
```

### Verify metrics locally

```bash
curl -s http://127.0.0.1:$(maand cat kv get maand/bucket coroot_node_agent_port_metrics)/metrics | head
```

### Enable logs/traces after otel was added later

1. Label workers with `otel_collector`
2. `maand build && maand deploy --jobs otel_collector`
3. `maand deploy --jobs coroot_node_agent` (re-render templates)

## Troubleshooting

| Symptom | Check |
|---------|-------|
| Template error: `otel_collector_workers` not found | Deploy otel_collector first, or remove otel_collector job from bucket until ready |
| No logs in ClickHouse | otel_collector running; coroot has `--logs-endpoint`; otel → CH pipeline healthy |
| Missing container metrics | Docker socket mounted; agent privileged |
| Health check fails, container "Running" | Stale listen port after bucket port change — redeploy with `--force-recreate` (Makefile) |
| Health check timeout / OOM in `docker events` | Memory too low for eBPF scrape — raise `[coroot_node_agent] memory` (512–768 mb+ on busy workers) |
| High memory | Reduce workload or lower manifest max in bucket if supported |

## Related jobs

- **otel_collector** — optional OTLP sink
- **prometheus** — scrapes this job's metrics
