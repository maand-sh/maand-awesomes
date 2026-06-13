global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['{{ .WorkerIP }}:9090']

  - job_name: 'node_agent'
    static_configs:
      - targets: [{{- range $index, $ip := (split (get "maand/worker" "worker_workers") ",") -}}{{- if $index}}, {{end}}"{{$ip}}:{{ get "maand" "node_agent_port_metrics" }}"{{end}}]

  - job_name: 'patroni'
    static_configs:
      - targets: [{{- range $index, $ip := (split (get "maand/worker" "postgres_workers") ",") -}}{{- if $index}}, {{end}}"{{$ip}}:{{ get "maand" "postgres_port_patroni" }}"{{end}}]

  - job_name: 'postgres'
    static_configs:
      - targets: [{{- range $index, $ip := (split (get "maand/worker" "postgres_workers") ",") -}}{{- if $index}}, {{end}}"{{$ip}}:{{ get "maand" "postgres_port_postgres_exporter" }}"{{end}}]

  - job_name: 'clickhouse'
    static_configs:
      - targets: [{{- range $index, $ip := (split (get "maand/worker" "clickhouse_workers") ",") -}}{{- if $index}}, {{end}}"{{$ip}}:{{ get "maand" "clickhouse_port_metrics" }}"{{end}}]

  - job_name: 'clickhouse_keeper'
    static_configs:
      - targets: [{{- range $index, $ip := (split (get "maand/worker" "clickhouse_keeper_workers") ",") -}}{{- if $index}}, {{end}}"{{$ip}}:{{ get "maand" "clickhouse_keeper_port_metrics" }}"{{end}}]

  - job_name: 'haproxy'
    static_configs:
      - targets: [{{- range $index, $ip := (split (get "maand/worker" "haproxy_workers") ",") -}}{{- if $index}}, {{end}}"{{$ip}}:{{ get "maand" "haproxy_port_metrics" }}"{{end}}]

remote_write:
  - url: "http://{{ .WorkerIP }}:9363/write"
    basic_auth:
      username: "admin"
      password: "admin"
    queue_config:
      capacity: 100000
      max_samples_per_send: 10000
      max_shards: 10

remote_read:
  - url: "http://{{ .WorkerIP }}:9363/read"
    read_recent: true
    basic_auth:
      username: "admin"
      password: "admin"