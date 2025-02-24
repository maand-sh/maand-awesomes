basic_auth_users:
    {{ get "vars/job/prometheus" "prometheus_admin_user" }}: {{ get "vars/job/prometheus" "prometheus_admin_password_hash" }}
    {{ get "vars/job/prometheus" "grafana_user" }}: {{ get "vars/job/prometheus" "grafana_password_hash" }}
