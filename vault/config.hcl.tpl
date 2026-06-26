{{- $leader_ip := get "maand/worker" "vault_0" -}}
{{- $node_index := get (printf "maand/worker/%s" .WorkerIP) "vault_allocation_index" -}}
{{- $is_leader := eq $node_index "0" -}}

ui             = true
disable_mlock  = true

storage "raft" {
  path    = "/vault/data"
  node_id = "vault-{{ $node_index }}"
{{- if not $is_leader }}
  retry_join {
    leader_api_addr = "http://{{ $leader_ip }}:8200"
  }
{{- end }}
}

listener "tcp" {
  address         = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  tls_disable     = true
}

api_addr     = "http://{{ .WorkerIP }}:8200"
cluster_addr = "http://{{ .WorkerIP }}:8201"
