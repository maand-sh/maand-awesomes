services:
  clickhouse:
    image: clickhouse/clickhouse-server:latest
    container_name: clickhouse-server
    network_mode: host
    environment:
      - CLICKHOUSE_USER=admin
      - CLICKHOUSE_PASSWORD=admin
    tmpfs:
      - /var/lib/clickhouse
    volumes:
      - ./clickhouse-config.xml:/etc/clickhouse-server/config.d/prometheus.xml
      - ./clickhouse-users.xml:/etc/clickhouse-server/users.d/experimental-time-series.xml
      - ./init-prometheus.sql:/docker-entrypoint-initdb.d/init-prometheus.sql:ro
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://{{ .WorkerIP }}:8123/ping"]
      interval: 5s
      timeout: 5s
      retries: 5

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus-server
    ports:
      - "9090:9090"
    tmpfs:
      - /prometheus:uid=65534,gid=65534,mode=0775
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.enable-remote-write-receiver'
    depends_on:
      clickhouse:
        condition: service_healthy
