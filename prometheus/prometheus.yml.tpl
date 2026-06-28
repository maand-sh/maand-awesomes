global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: prometheus
    basic_auth:
      username: {{ getSecret "admin_username" }}
      password: {{ getSecret "admin_password" }}
    static_configs:
      - targets: ['{{ .WorkerIP }}:{{ get "maand/bucket" "prometheus_port_http" }}']
{{ scrapeConfigs }}

{{ ruleFiles }}
