# Zookeeper quorum at risk

## Alert

- `zookeeper quorum at risk` — fewer than 2 of 3 nodes are scrapeable

## Diagnosis

```bash
maand job_command zookeeper command_cluster_status
```

Check each ensemble member:

```bash
for ip in $(maand cat kv get maand/job/zookeeper workers | tr ',' ' '); do
  echo "=== $ip ==="
  curl -s --connect-timeout 2 "http://$ip:$(maand cat kv get maand/bucket zookeeper_port_metrics)/metrics" | head -1 || echo unreachable
done
```

## Remediation

1. Restore failed nodes first (deploy order: bootstrap node, then peers)
2. Do not restart more than one node at a time unless quorum is confirmed healthy
3. If data is corrupt on one node, remove its data dir and rejoin per zookeeper reinit docs
