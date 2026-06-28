## Connection timeouts

1. Verify inter-node connectivity: `docker exec cassandra nodetool status`
2. Check network errors on the host (coroot_node_agent network alerts)
3. Review client load — timeouts often correlate with overload or GC pauses
4. Inspect GC logs under the Cassandra log directory if latency is elevated
