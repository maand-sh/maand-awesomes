{{- $cpuMHz := int (get "maand/job/clickhouse_keeper" "cpu") -}}
{{- $cores := max 1 (div $cpuMHz 2400) -}}
services:

  keeper-1:
    image: clickhouse/clickhouse-server:26.5
    container_name: clickhouse-keeper
    hostname: "{{ .WorkerIP }}"
    network_mode: host
    user: "101:101"
    restart: always
    stop_grace_period: 120s
    volumes:
      - ./keeper_config.xml:/etc/clickhouse-keeper/keeper_config.xml:ro
      - ./certs:/etc/clickhouse-keeper/certs:ro
      - ./data:/var/lib/clickhouse-keeper
    entrypoint: ["clickhouse-keeper", "--config-file=/etc/clickhouse-keeper/keeper_config.xml"]
    deploy:
      resources:
        limits:
          cpus: "{{ $cores }}"
          memory: {{ get "maand/job/clickhouse_keeper" "memory" }}m
        reservations:
          cpus: "{{ $cores }}"
          memory: {{ get "maand/job/clickhouse_keeper" "min_memory_mb" }}m
