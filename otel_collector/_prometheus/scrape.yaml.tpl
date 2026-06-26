- job_name: {{ .Job }}
  metrics_path: /metrics
  scheme: http
  static_configs:
    - targets:
        - maand:port/otel_collector_port_metrics
      labels:
        maand_job: {{ .Job }}
