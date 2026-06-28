## Cassandra metrics endpoint down

1. Check the container: `docker ps -f name=cassandra`
2. Verify metrics locally: `curl -s http://127.0.0.1:<cassandra_metrics_port>/metrics | head`
3. If the container is running but metrics fail, inspect logs: `docker logs cassandra --tail 100`
4. Confirm the JMX exporter agent started — look for `jmx_prometheus_javaagent` in JVM args
5. Restart if needed: `make restart` in the cassandra job directory
