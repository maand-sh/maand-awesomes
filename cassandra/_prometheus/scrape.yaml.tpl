- job_name: maand:job
  metrics_path: /metrics
  scheme: http
  static_configs:
    - targets:
        - maand:port/cassandra_metrics_port
      labels:
        maand_job: maand:job
