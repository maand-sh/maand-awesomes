apiVersion: 1

datasources:
- name: Prometheus
  type: prometheus
  url: http://{{ get "maand/worker" "prometheus_0" }}:9091
  isDefault: true
  access: proxy
  editable: true
  basicAuth: true
  basicAuthUser: {{ get "vars/job/grafana" "prometheus_user" }}
  secureJsonData:
    basicAuthPassword: {{ get "vars/job/grafana" "prometheus_password" }}