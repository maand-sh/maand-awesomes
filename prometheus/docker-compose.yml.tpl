services:
  prometheus:
    image: prom/prometheus:v2.55.1
    container_name: prometheus-server
    hostname: "{{ .WorkerIP }}"
    user: "root"
    ports:
      - "{{ get "maand" "prometheus_port_http" }}:{{ get "maand" "prometheus_port_http" }}"
    volumes:
      - ./data/prometheus:/prometheus:z
      - ./rules:/etc/prometheus/rules:z
      - ./consoles:/etc/prometheus/consoles:z
      - ./console_libraries:/etc/prometheus/console_libraries:z
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.enable-remote-write-receiver'
      - '--web.listen-address=0.0.0.0:{{ get "maand" "prometheus_port_http" }}'
    deploy:
      resources:
        limits:
          memory: {{ get "maand/job/prometheus" "memory" }}m
        reservations:
          memory: {{ get "maand/job/prometheus" "min_memory_mb" }}m
