# Zookeeper connections / file descriptors high

## Alerts

- `zookeeper connections high` — `num_alive_connections > 200` (limit 256)
- `zookeeper open files high` — `open_file_descriptor_count > 300`

## Diagnosis

```bash
docker exec zookeeper zkCli.sh -server 127.0.0.1:<zookeeper_port_client> cons
docker exec zookeeper zkCli.sh -server 127.0.0.1:<zookeeper_port_client> stat
```

## Remediation

1. Identify clients holding many connections (Patroni, apps, stale sessions)
2. Restart misbehaving clients; fix connection leaks in application code
3. Raise `maxClientCnxns` in `zoo.cfg` only after confirming server capacity
