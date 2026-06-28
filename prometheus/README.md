# prometheus

Central metrics server for the bucket. Scrapes all jobs that define `_prometheus/scrape.yaml` (or `.tpl`), evaluates alert rules from other jobs, and accepts remote write (from otel_collector).

**Version:** 1.0.0

## Role in the stack

```
all jobs (_prometheus/)  --scrape-->  prometheus
otel_collector           --remote write-->  prometheus (when prometheus=internal)
coroot_node_agent        --scrape-->  prometheus
```

## Worker placement

| Setting | Value |
|---------|-------|
| Selector | `prometheus` (implicit job name) |
| Example host | `10.48.198.160` |
| Memory (bucket) | `1024 mb` |
| Manifest memory | min `512 mb`, max `2048 mb` |

```json
{ "host": "10.48.198.160", "labels": ["prometheus"] }
```

Typically one Prometheus instance per bucket.

## Configuration

### bucket.jobs.conf

```toml
[prometheus]
memory = "1024 mb"
```

After editing: `maand build && maand deploy --jobs prometheus`.

### manifest.json — ports

| Port key | Use |
|----------|-----|
| `prometheus_port_http` | Web UI, API, `/metrics`, remote write receiver |

### Key files

| File | Purpose |
|------|---------|
| `docker-compose.yml.tpl` | `prom/prometheus:v2.55.1`, port published to host |
| `prometheus.yml.tpl` | Global 15s scrape/eval; self-scrape + aggregated configs |
| `consoles/workers.html` | Custom worker overview console |
| `consoles/worker_detail.html` | Per-worker detail console |
| `Makefile` | `start`, `stop`, `restart` |

### Aggregated scrape and rules

At build/deploy, maand injects:

- `{{ scrapeConfigs }}` — all job scrape definitions using `maand:port/*` targets
- `{{ ruleFiles }}` — alert YAML from each job's `_prometheus/alerts/`

Adding a new monitored job requires only `_prometheus/scrape.yaml` in that job plus `maand build`.

### Remote write

Enabled in `docker-compose.yml.tpl` for otel_collector internal mode:

```
http://<prometheus-host>:<prometheus_port_http>/api/v1/write
```

## Deploy

```bash
maand build
maand deploy --jobs prometheus
```

Deploy Prometheus early so other jobs' metrics are collected after they start.

### Health check

HTTP GET `/-/healthy` — 60 × 2s.

## Monitoring

Prometheus scrapes itself. All other scrape configs and alerts come from sibling jobs:

| Job | Alerts |
|-----|--------|
| coroot_node_agent | CPU, memory, disk, containers, … |
| postgres | replication, connections, deadlocks |
| vault | sealed, quorum, metrics down |
| zookeeper | quorum, latency, JVM, elections |

## Commands

None in manifest.

## Operations

### Web UI

```
http://<prometheus-host>:<prometheus_port_http>/
```

Port from KV:

```bash
maand cat kv get maand/bucket prometheus_port_http
```

### Worker consoles

Open **Consoles** in the UI → `workers.html` for bucket worker overview.

### Reload config after job scrape changes

```bash
maand build
maand deploy --jobs prometheus
# or deploy the job that changed _prometheus/ — prometheus config updates on build
```

### Check targets

Status → Targets, or:

```bash
curl -s http://<host>:<port>/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'
```

## Troubleshooting

| Symptom | Check |
|---------|-------|
| Target down | Worker reachable; port in KV; job container running |
| No otel metrics | otel `prometheus=internal` in bucket.jobs.conf; remote write URL |
| Alerts not firing | `_prometheus/alerts/` present; `ruleFiles` in generated config |
| OOM | Raise `[prometheus] memory` in bucket.jobs.conf |

## Related jobs

- **otel_collector** — optional remote write source
- **All jobs with `_prometheus/`** — scrape and alert sources
