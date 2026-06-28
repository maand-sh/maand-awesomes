## Pending compactions high

1. Check compaction throughput: `docker exec cassandra nodetool compactionstats`
2. Review write load — sustained high writes increase compaction backlog
3. Verify disk I/O is not saturated (coroot_node_agent disk alerts)
4. If backlog persists, review compaction strategy settings for affected keyspaces
