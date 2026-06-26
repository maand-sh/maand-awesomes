# Zookeeper data growth

## Alerts

- `zookeeper znode count high` — above 1M znodes
- `zookeeper data size high` — above 1 GB approximate data
- `zookeeper watch count high` — above 10k watches

## Diagnosis

```bash
docker exec zookeeper zkCli.sh -server 127.0.0.1:<zookeeper_port_client> ls /
docker exec zookeeper zkCli.sh -server 127.0.0.1:<zookeeper_port_client> stat
```

Inspect Patroni DCS path:

```bash
docker exec zookeeper zkCli.sh -server 127.0.0.1:<zookeeper_port_client> ls /service/postgres
```

## Remediation

1. Purge stale znodes from misconfigured clients
2. Review Patroni history nodes and old session ephemerals
3. Plan ensemble expansion or snapshot tuning if growth is legitimate
