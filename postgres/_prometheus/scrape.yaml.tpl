- job_name: {{ .Job }}
  metrics_path: /metrics
  scheme: http
  static_configs:
    - targets:
        - maand:port/postgres_port_postgres_exporter
      labels:
        maand_job: {{ .Job }}
