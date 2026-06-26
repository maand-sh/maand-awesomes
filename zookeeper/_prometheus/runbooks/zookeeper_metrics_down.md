# Zookeeper metrics down

## Alert

- `zookeeper metrics down` — `/metrics` scrape failing for 5 minutes

## Diagnosis

```bash
maand job_command zookeeper command_cluster_status
docker ps --filter name=zookeeper
docker logs zookeeper --tail 50
curl -s http://127.0.0.1:<zookeeper_port_metrics>/metrics | head
```

## Remediation

1. Restart the node: `make -C jobs/zookeeper restart`
2. Check `zoo.cfg` and data/log volume permissions under `./data` and `./logs`
3. Verify the metrics port in `maand cat kv get maand zookeeper_port_metrics`
