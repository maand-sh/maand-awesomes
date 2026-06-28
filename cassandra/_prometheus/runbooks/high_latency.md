## High read/write latency

1. Check node status: `docker exec cassandra nodetool status`
2. Review pending compactions and disk I/O saturation
3. Compare latency across nodes in Prometheus to spot hot spots
4. Check for repair or bootstrap activity that may temporarily increase latency
