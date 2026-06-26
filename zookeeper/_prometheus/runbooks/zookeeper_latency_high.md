# Zookeeper latency / disk slow

## Alerts

- `zookeeper avg latency high` — `avg_latency > 100` ms
- `zookeeper fsync slow` — high fsync time rate
- `zookeeper snapshot slow` — high snapshot time rate

## Diagnosis

```bash
docker exec zookeeper zkCli.sh -server 127.0.0.1:<zookeeper_port_client> stat
docker logs zookeeper --tail 100
iostat -x 1 5
df -h
```

## Remediation

1. Check disk latency and free space on `./data` and `./logs`
2. Reduce client load or batch writes to ZK
3. Tune `tickTime`, `syncLimit`, and JVM heap (`JVMFLAGS` in docker-compose) if sustained under load
