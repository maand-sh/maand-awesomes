- job_name: {{ .Job }}
  metrics_path: /metrics
  scheme: http
  static_configs:
    - targets:
        - maand:port/zookeeper_port_metrics
      labels:
        maand_job: {{ .Job }}
  metric_relabel_configs:
    - source_labels: [__name__]
      regex: '^zookeeper_(.+)$'
      target_label: __name__
      replacement: 'zookeeper_${1}'
    - source_labels: [__name__]
      regex: '(.+)'
      target_label: __name__
      replacement: 'zookeeper_${1}'
