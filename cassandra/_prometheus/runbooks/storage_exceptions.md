## Storage exceptions

1. Check Cassandra logs: `docker logs cassandra --tail 200 | grep -i exception`
2. Review disk space on the data volume (`./data`)
3. Run `docker exec cassandra nodetool status` to confirm the node is healthy
4. Check for recent schema or topology changes that may have caused write failures
