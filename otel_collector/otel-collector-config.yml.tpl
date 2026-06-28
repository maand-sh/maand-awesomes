{{- $cfg := "vars/bucket/job/otel_collector" -}}
{{- $chMode := get $cfg "clickhouse" -}}
{{- $promMode := get $cfg "prometheus" -}}
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:{{ get "maand/bucket" "otel_collector_port_grpc" }}
      http:
        endpoint: 0.0.0.0:{{ get "maand/bucket" "otel_collector_port_http" }}

processors:
  batch:
    timeout: 10s
    send_batch_size: 1024
  memory_limiter:
    check_interval: 1s
    limit_percentage: 80
    spike_limit_percentage: 25

exporters:
  file/traces:
    path: /data/traces/otel-traces.json

  file/logs:
    path: /data/logs/otel-logs.json

{{- if eq $chMode "external" }}
{{- if ne (get $cfg "clickhouse_endpoint") "" }}
  clickhouse:
    endpoint: {{ get $cfg "clickhouse_endpoint" }}
    username: {{ get $cfg "clickhouse_username" }}
    password: {{ get $cfg "clickhouse_password" }}
    database: {{ get $cfg "clickhouse_database" }}
    logs_table_name: otel_logs
    create_schema: true
    timeout: 5s
    retry_on_failure:
      enabled: true
      initial_interval: 5s
      max_interval: 30s
      max_elapsed_time: 300s
{{- end }}
{{- else }}
{{- $chHost := trim (index (split (get "maand/job/clickhouse" "workers") ",") 0) -}}
{{- if ne $chHost "" }}
  clickhouse:
    endpoint: tcp://{{ $chHost }}:{{ get "maand/bucket" "clickhouse_port_native_tls" }}?dial_timeout=10s&compress=lz4
    username: default
    password: {{ get "secrets/job/clickhouse" "default_password" }}
    database: otel
    logs_table_name: otel_logs
    create_schema: true
    timeout: 5s
    tls:
      insecure: true
    retry_on_failure:
      enabled: true
      initial_interval: 5s
      max_interval: 30s
      max_elapsed_time: 300s
{{- end }}
{{- end }}

{{- if eq $promMode "external" }}
{{- if ne (get $cfg "prometheus_endpoint") "" }}
  prometheusremotewrite:
    endpoint: {{ get $cfg "prometheus_endpoint" }}
{{- $promUser := get $cfg "prometheus_username" -}}
{{- if and (ne $promUser "") (ne (get $cfg "prometheus_password") "") }}
    auth:
      authenticator: basicauth/prometheus
{{- end }}
{{- end }}
{{- else if eq $promMode "internal" }}
{{- $promHost := trim (index (split (get "maand/worker" "prometheus_workers") ",") 0) -}}
{{- if ne $promHost "" }}
  prometheusremotewrite:
    endpoint: http://{{ $promHost }}:{{ get "maand/bucket" "prometheus_port_http" }}/api/v1/write
{{- end }}
{{- end }}

extensions:
  health_check:
    endpoint: 0.0.0.0:{{ get "maand/bucket" "otel_collector_port_health" }}
{{- $promUser := get $cfg "prometheus_username" -}}
{{- if and (eq $promMode "external") (ne $promUser "") (ne (get $cfg "prometheus_password") "") (ne (get $cfg "prometheus_endpoint") "") }}
  basicauth/prometheus:
    client_auth:
      username: {{ $promUser }}
      password: {{ get $cfg "prometheus_password" }}
{{- end }}

service:
{{- $promUser := get $cfg "prometheus_username" -}}
{{- if and (eq $promMode "external") (ne $promUser "") (ne (get $cfg "prometheus_password") "") (ne (get $cfg "prometheus_endpoint") "") }}
  extensions: [health_check, basicauth/prometheus]
{{- else }}
  extensions: [health_check]
{{- end }}
  pipelines:
    logs:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters:
{{- if eq $chMode "external" }}
{{- if ne (get $cfg "clickhouse_endpoint") "" }}
        - clickhouse
{{- else }}
        - file/logs
{{- end }}
{{- else }}
{{- $chHost := trim (index (split (get "maand/job/clickhouse" "workers") ",") 0) -}}
{{- if ne $chHost "" }}
        - clickhouse
{{- else }}
        - file/logs
{{- end }}
{{- end }}
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [file/traces]
{{- if eq $promMode "external" }}
{{- if ne (get $cfg "prometheus_endpoint") "" }}
    metrics:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [prometheusremotewrite]
{{- end }}
{{- else if eq $promMode "internal" }}
{{- $promHost := trim (index (split (get "maand/worker" "prometheus_workers") ",") 0) -}}
{{- if ne $promHost "" }}
    metrics:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [prometheusremotewrite]
{{- end }}
{{- end }}
  telemetry:
    metrics:
      address: 0.0.0.0:{{ get "maand/bucket" "otel_collector_port_metrics" }}
