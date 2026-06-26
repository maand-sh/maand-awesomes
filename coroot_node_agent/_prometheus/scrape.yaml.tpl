- job_name: maand:job
  metrics_path: /metrics
  scheme: http
  static_configs:
    - targets:
        - maand:port/coroot_node_agent_port_metrics
      labels:
        maand_job: maand:job
