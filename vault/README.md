# vault

HashiCorp Vault cluster in integrated Raft storage mode with TLS on all listeners. Auto-initializes on first deploy and unseals nodes via lifecycle hooks.

**Version:** 2.3.0

## Role in the stack

Standalone secrets management cluster. Other jobs do not depend on Vault for deploy ordering in this bucket, but applications may use it for runtime secrets.

## Worker placement

| Setting | Value |
|---------|-------|
| Selector | `vault` |
| Example hosts | `10.48.200.1`, `10.48.200.2`, `10.48.200.3` |
| `deploy_parallel_count` | 1 |
| `update_parallel_count` | 1 |

```json
{ "host": "10.48.200.1", "labels": ["vault"] }
```

Raft requires **odd** node count (3+ recommended). Leader (`vault_0`) bootstraps the cluster; followers join via `retry_join`.

## Configuration

### bucket.jobs.conf

No job-specific section.

### manifest.json — ports

| Port key | Use |
|----------|-----|
| `vault_port_api` | HTTPS API |
| `vault_port_cluster` | Raft cluster communication |

### TLS certificates

| Cert | CN |
|------|-----|
| `server` | `vault` |

Mounted at `/vault/tls/` (`server.crt`, `server.key`, `ca.crt`).

### Key files

| File | Purpose |
|------|---------|
| `config.hcl.tpl` | Raft storage, TLS listener, telemetry, retry_join |
| `docker-compose.yml.tpl` | `hashicorp/vault:1.17`, host network, IPC_LOCK |
| `entrypoint.sh.tpl` | Data directory permissions |
| `Makefile` | `start`, `restart` (force-recreate for rolling) |

Telemetry exposes Prometheus metrics at `/v1/sys/metrics?format=prometheus` (unauthenticated metrics access enabled in config).

## Secrets and cluster vars

### Generated secrets (`secrets/job/vault`)

Created during first leader bootstrap (Shamir 5-of-3):

| Key | Purpose |
|-----|---------|
| `unseal_key_1` … `unseal_key_5` | Unseal key shares |
| `root_token` | Initial root token |

```bash
maand cat kv get secrets/job/vault root_token
maand cat kv get secrets/job/vault unseal_key_1
```

**Store these securely.** Loss of unseal quorum requires Vault recovery procedures.

### Cluster vars (`vars/job/vault`)

| Key | Purpose |
|-----|---------|
| `cluster_initialized` | Whether init ran |
| `cluster_leader_ip` | Bootstrap leader |
| `cluster_bootstrapped` | Cluster ready flag |
| `cluster_key_shares` / `cluster_key_threshold` | Shamir parameters |

## Lifecycle hooks

| Hook | Description |
|------|-------------|
| `command_plan_order` (pre_deploy) | Leader first on bootstrap; controlled order on upgrades |
| `command_node_up` (after_allocation_started) | Init cluster on leader; unseal each node |
| `command_unseal` (CLI) | Re-unseal after host reboot |

### Deploy

```bash
maand build
maand deploy --jobs vault
```

One node at a time (`deploy_parallel_count: 1`).

### Health check

TCP on `vault_port_api` — 60 × 5s.

## Commands

| Command | When | Description |
|---------|------|-------------|
| `command_cluster_status` | CLI | Raft leader and standbys |
| `command_unseal` | CLI | Unseal all nodes (e.g. after reboot) |

### Cluster status

```bash
maand job_command vault command_cluster_status
```

Runs from allocation index 0.

### Unseal after reboot

```bash
maand job_command vault command_unseal --concurrency 1
```

## Monitoring

| Asset | Location |
|-------|----------|
| Scrape | `_prometheus/scrape.yaml` — HTTPS metrics, `insecure_skip_verify: true` |
| Alerts | `_prometheus/alerts/alerts.yaml` |
| Runbooks | `_prometheus/runbooks/` |

Alerts: metrics down, **sealed** state, quorum at risk.

### Example: check sealed status

```bash
curl -sk https://<host>:$(maand cat kv get maand/bucket vault_port_api)/v1/sys/seal-status | jq
```

## Operations

### API access

```bash
export VAULT_ADDR=https://<leader-ip>:$(maand cat kv get maand/bucket vault_port_api)
export VAULT_TOKEN=$(maand cat kv get secrets/job/vault root_token)
vault status
```

Install Vault CLI on the orchestrator host or use curl against the API.

### Rolling upgrade

1. Bump image in `docker-compose.yml.tpl` and `version` in manifest
2. `maand build && maand deploy --jobs vault`
3. Follow deploy order (followers, leader last on upgrade)
4. Run `command_unseal` if nodes restart sealed

### Backup

Back up `./data/` on each Vault node and secure unseal keys separately. Use Vault's native snapshot for consistent Raft state.

## Troubleshooting

| Symptom | Check |
|---------|-------|
| Node sealed after reboot | `maand job_command vault command_unseal` |
| Follower not joining | Leader API reachable; `retry_join` addresses in config; Raft port open |
| Quorum at risk | Majority of nodes up and unsealed |
| Metrics scrape fails | TLS skip verify in scrape config; API port |

## Security notes

- Root token and unseal keys live in maand KV — restrict CLI and database access
- Rotate root token and enable proper auth methods for production use
- API uses TLS with bucket CA; clients should verify server cert in production

## Related jobs

None in deploy dependency graph for this bucket.
