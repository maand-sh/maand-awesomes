# otel_collector

OpenTelemetry Collector receives OTLP logs, traces, and metrics from agents (e.g. coroot_node_agent) and exports them to ClickHouse and/or Prometheus.

**Version:** 1.1.0

This job is **optional**. coroot_node_agent runs without it; when otel_collector is deployed, coroot pushes logs and traces via OTLP/HTTP.

## Role in the stack

```
coroot_node_agent  --OTLP-->  otel_collector  --logs-->  clickhouse
                                              --metrics--> prometheus (optional)
                                              --traces-->  local file
```

## Worker placement

| Setting | Value |
|---------|-------|
| Selector | `otel_collector` |
| Memory (bucket) | `1024 mb` default |

Add the label to workers that should run the collector:

```json
{ "host": "10.48.200.1", "labels": ["otel_collector"] }
```

**Important:** coroot_node_agent resolves the otel endpoint from `maand/worker/otel_collector_workers`. The job must have **at least one allocation** before deploying coroot, or template render fails. Either:

- Label workers and deploy otel_collector first, or
- Omit the `otel_collector` job from the bucket until ready.

## Configuration

All backend settings live in **`workspace/bucket.jobs.conf`** under `[otel_collector]`. Values are synced to KV namespace `vars/bucket/job/otel_collector` at build.

### bucket.jobs.conf reference

```toml
[otel_collector]
memory = "1024 mb"

# --- ClickHouse (logs) ---
# internal: use maand clickhouse job (first worker, native TLS, default_password secret)
# external: use clickhouse_* fields below
clickhouse = "internal"              # internal | external
clickhouse_endpoint = ""             # e.g. tcp://host:9440?secure=true (external only)
clickhouse_username = "default"
clickhouse_password = ""             # external only; internal uses secrets/job/clickhouse
clickhouse_database = "otel"

# --- Prometheus (metrics remote write) ---
# internal: first prometheus worker + /api/v1/write
# external: prometheus_endpoint URL
# off: no metrics export pipeline
prometheus = "internal"              # internal | external | off
prometheus_endpoint = ""             # e.g. https://prom.example/api/v1/write
prometheus_username = ""             # optional basic auth (external)
prometheus_password = ""
```

After editing:

```bash
maand build
maand deploy --jobs otel_collector
```

### manifest.json — ports

Ports use `{}` in the manifest so maand assigns from the bucket pool (`bucket.conf` `port_min`–`port_max`). Read assigned numbers in templates with `get "maand/bucket" "<port_name>"`.

| Port key | Use |
|----------|-----|
| `otel_collector_port_grpc` | OTLP gRPC |
| `otel_collector_port_http` | OTLP HTTP (coroot uses this) |
| `otel_collector_port_metrics` | Collector self-metrics |
| `otel_collector_port_health` | Health check extension |

```bash
maand cat kv get maand/bucket otel_collector_port_http
```

Memory bounds in manifest: min `256 mb`, max `1024 mb` (bucket value must fit).

### Export behavior (`otel-collector-config.yml.tpl`)

| Pipeline | Destination |
|----------|-------------|
| **logs** | ClickHouse when configured; else `./data/logs/otel-logs.json` |
| **traces** | `./data/traces/otel-traces.json` |
| **metrics** | Prometheus remote write when `prometheus` is `internal` or `external`; omitted when `off` |

#### Internal ClickHouse

- Endpoint: first `maand/job/clickhouse` worker + `clickhouse_port_native_tls`
- Password: `secrets/job/clickhouse/default_password`
- TLS: `insecure: true` (encrypted channel, no CA verification)

#### External ClickHouse

- Uses `clickhouse_endpoint`, username, password, database from bucket config
- Add TLS query params or `tls` block in endpoint URL as required by your server

#### Internal Prometheus

- Remote write: `http://<first-prometheus-worker>:<prometheus_port_http>/api/v1/write`

#### External Prometheus

- Remote write URL from `prometheus_endpoint`
- Optional HTTP basic auth when username and password are both set

### TLS / CA for ClickHouse

Internal mode does **not** require mounting the bucket CA — connection uses TLS with verification skipped. For production hardening, mount `ca.crt` and set `tls.ca_file` with `insecure: false` in the template.

External mode: configure TLS in `clickhouse_endpoint` (e.g. `?secure=true`) and provide CA path in the exporter `tls` section if needed.

## Dependencies

| Hook | Description |
|------|-------------|
| `command_wait_clickhouse` (pre_deploy) | When `clickhouse=internal`, pings ClickHouse HTTP `/ping` on all CH workers. Skipped when `clickhouse=external` or no CH workers. |

No manifest demand on clickhouse — wait is best-effort via runtime KV.

**Recommended deploy order:**

```bash
maand deploy --jobs clickhouse_keeper,clickhouse,otel_collector,coroot_node_agent
```

## Deploy

```bash
maand build
maand deploy --jobs otel_collector
```

### Health check

HTTP GET `/` on `otel_collector_port_health` — 60 × 2s.

## Commands

| Command | When | Description |
|---------|------|-------------|
| `command_wait_clickhouse` | pre_deploy | Wait for internal ClickHouse (optional skip) |
| `command_service` | CLI | Marker command |

## Monitoring

Self-scrape: `_prometheus/scrape.yaml.tpl` on `otel_collector_port_metrics`.

## coroot_node_agent integration

When otel_collector is allocated, coroot gets:

```
--logs-endpoint=http://<otel-host>:<otel_collector_port_http>/v1/logs
--traces-endpoint=http://<otel-host>:<otel_collector_port_http>/v1/traces
```

coroot does **not** require otel_collector to start; it only enables OTLP when otel workers exist in KV.

## Operations

### Verify OTLP ingress

```bash
curl -s http://<otel-host>:$(maand cat kv get maand/bucket otel_collector_port_health)/
```

### Check logs landed in ClickHouse

Query the `otel.otel_logs` table on a ClickHouse node (internal mode creates schema automatically).

### Disable metrics export

Set `prometheus = "off"` in `bucket.jobs.conf`, then `maand build && maand deploy --jobs otel_collector`.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `exporter "clickhouse" which is not configured` | No CH workers and not external — logs fall back to file; ensure `clickhouse=internal` only when CH is deployed |
| coroot deploy template error on `otel_collector_workers` | Deploy otel_collector to at least one labeled worker first |
| Cannot reach ClickHouse | Check native TLS port, firewall, `default_password` |
| pre_deploy wait skipped | `clickhouse=external`, or no `clickhouse_port_http` in KV (ClickHouse uses HTTPS/metrics only) |

## Related jobs

- **coroot_node_agent** — OTLP source (optional)
- **clickhouse** — internal logs backend
- **prometheus** — internal metrics backend
