receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:{{ get "maand" "otel_collector_port_grpc" }}
      http:
        endpoint: 0.0.0.0:{{ get "maand" "otel_collector_port_http" }}

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

  clickhouse:
    endpoint: tcp://{{ .WorkerIP }}:{{ get "maand" "clickhouse_port_native" }}?dial_timeout=10s&compress=lz4
    username: default
    password: {{ get "secrets/job/clickhouse" "password" }}
    database: otel
    logs_table_name: otel_logs
    create_schema: true
    timeout: 5s
    retry_on_failure:
      enabled: true
      initial_interval: 5s
      max_interval: 30s
      max_elapsed_time: 300s

extensions:
  health_check:
    endpoint: 0.0.0.0:{{ get "maand" "otel_collector_port_health" }}

service:
  extensions: [health_check]
  pipelines:
    logs:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [clickhouse]
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [file/traces]
  telemetry:
    metrics:
      address: 0.0.0.0:{{ get "maand" "otel_collector_port_metrics" }}
