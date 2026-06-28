{{- $leader_ip := get "maand/worker" "vault_0" -}}
{{- $node_index := get (printf "maand/worker/%s" .WorkerIP) "vault_allocation_index" -}}
{{- $is_leader := eq $node_index "0" -}}
{{- $api_port := get "maand/bucket" "vault_port_api" -}}
{{- $cluster_port := get "maand/bucket" "vault_port_cluster" -}}

ui             = true
disable_mlock  = true

storage "raft" {
  path    = "/vault/data"
  node_id = "vault-{{ $node_index }}"
{{- if not $is_leader }}
  retry_join {
    leader_api_addr     = "https://{{ $leader_ip }}:{{ $api_port }}"
    leader_ca_cert_file = "/vault/tls/ca.crt"
  }
{{- end }}
}

listener "tcp" {
  address         = "0.0.0.0:{{ $api_port }}"
  cluster_address = "0.0.0.0:{{ $cluster_port }}"
  tls_cert_file   = "/vault/tls/server.crt"
  tls_key_file    = "/vault/tls/server.key"
  tls_client_ca_file = "/vault/tls/ca.crt"

  telemetry {
    unauthenticated_metrics_access = true
  }
}

telemetry {
  disable_hostname          = true
  prometheus_retention_time = "12h"
}

api_addr     = "https://{{ .WorkerIP }}:{{ $api_port }}"
cluster_addr = "https://{{ .WorkerIP }}:{{ $cluster_port }}"
