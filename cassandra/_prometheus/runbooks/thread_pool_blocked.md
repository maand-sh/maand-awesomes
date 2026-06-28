## Thread pool blocked

1. Identify the blocked pool from alert labels (`path`, `scope`)
2. Check for downstream issues: disk saturation, network errors, or overloaded peers
3. Review `docker exec cassandra nodetool tpstats` for pool state
4. If a specific pool stays blocked, reduce load or investigate stuck operations
