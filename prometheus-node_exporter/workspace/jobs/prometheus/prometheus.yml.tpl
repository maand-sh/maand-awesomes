global:
  scrape_interval: 15s
  scrape_timeout: 10s
  evaluation_interval: 15s

scrape_configs:
- job_name: prometheus
  honor_timestamps: true
  scrape_interval: 15s
  scrape_timeout: 10s
  metrics_path: /metrics
  scheme: http
  basic_auth:
    username: admin
    password: admin
  static_configs:
  - targets:
    - {{ .WorkerIP }}:9091

- job_name: workers
  honor_timestamps: true
  scrape_interval: 10s
  scrape_timeout: 10s
  metrics_path: /metrics
  scheme: http
  static_configs:
  - targets: [{{- range $index, $ip := (split (get "maand/worker" "worker_nodes") ",") -}}{{- if $index}}, {{end}}"{{$ip}}:9100"{{end}}]
