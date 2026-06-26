# Zookeeper JVM memory high

## Alert

- `zookeeper jvm memory high` — heap above 85%

## Diagnosis

```bash
docker logs zookeeper --tail 50 | grep -i gc
curl -s http://127.0.0.1:<zookeeper_port_metrics>/metrics | grep jvm_memory
```

## Remediation

1. Increase `-Xmx` in `JVMFLAGS` (currently 2g in docker-compose)
2. Reduce znode/watch growth or client session churn
3. Restart during a maintenance window if heap is exhausted
