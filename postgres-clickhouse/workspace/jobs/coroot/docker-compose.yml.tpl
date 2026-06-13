services:

  coroot:
    image: ghcr.io/coroot/coroot:latest
    container_name: coroot
    hostname: "{{ .WorkerIP }}"
    network_mode: host
    restart: always
    user: root
    volumes:
      - ./data/coroot:/data
    command:
      - --data-dir=/data
      - --listen=0.0.0.0:{{ get "maand" "coroot_port_http" }}
      - --bootstrap-prometheus-url=http://{{ get "maand/worker" "prometheus_0" }}:{{ get "maand" "prometheus_port_http" }}
      - --bootstrap-refresh-interval=15s
      - --bootstrap-clickhouse-address={{ get "maand/worker" "prometheus_0" }}:9363
      - --bootstrap-clickhouse-user=admin
      - --bootstrap-clickhouse-password=admin
      - --bootstrap-clickhouse-database=default