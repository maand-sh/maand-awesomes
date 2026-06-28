{{- $cpuMHz := int (get "maand/job/clickhouse" "cpu") -}}
{{- $mhzPerCore := 2400 -}}
{{- $cores := max 1 (div $cpuMHz $mhzPerCore) -}}
services:

  clickhouse:
    image: clickhouse/clickhouse-server:26.5
    container_name: clickhouse-server
    hostname: "{{ .WorkerIP }}"
    network_mode: host
    restart: always
    stop_grace_period: 120s
    environment:
      CLICKHOUSE_USER: default
      CLICKHOUSE_PASSWORD: ${CLICKHOUSE_PASSWORD}
      CLICKHOUSE_INTERSERVER_PASSWORD: ${CLICKHOUSE_INTERSERVER_PASSWORD}
      CLICKHOUSE_READONLY_PASSWORD: ${CLICKHOUSE_READONLY_PASSWORD}
      CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT: 1
    volumes:
      - ./data:/var/lib/clickhouse
      - ./prometheus-exporter.xml:/etc/clickhouse-server/config.d/prometheus-exporter.xml
      - ./zookeeper.xml:/etc/clickhouse-server/config.d/zookeeper.xml
      - ./cluster.xml:/etc/clickhouse-server/config.d/cluster.xml
      - ./macros.xml:/etc/clickhouse-server/config.d/macros.xml
      - ./server.xml:/etc/clickhouse-server/config.d/server.xml
      - ./threadpool.xml:/etc/clickhouse-server/config.d/threadpool.xml
      - ./interserver.xml:/etc/clickhouse-server/config.d/interserver.xml
      - ./tls.xml:/etc/clickhouse-server/config.d/tls.xml
      - ./certs:/etc/clickhouse-server/certs:ro
      - ./logger.xml:/etc/clickhouse-server/config.d/logger.xml
      - ./memory.xml:/etc/clickhouse-server/config.d/memory.xml
      - ./limits.xml:/etc/clickhouse-server/config.d/limits.xml
      - ./query_log.xml:/etc/clickhouse-server/config.d/query_log.xml
      - ./users.xml:/etc/clickhouse-server/config.d/users.xml
      - ./password_complexity.xml:/etc/clickhouse-server/config.d/password_complexity.xml
      - ./merge_tree.xml:/etc/clickhouse-server/config.d/merge_tree.xml
    ulimits:
      nofile:
        soft: 262144
        hard: 262144
    deploy:
      resources:
        limits:
          cpus: "{{ $cores }}"
          memory: {{ get "maand/job/clickhouse" "memory" }}m
        reservations:
          cpus: "{{ $cores }}"
          memory: {{ get "maand/job/clickhouse" "min_memory_mb" }}m
