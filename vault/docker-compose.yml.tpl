{{- $leader_ip := get "maand/worker" "vault_0" -}}
{{- $is_leader := eq (get (printf "maand/worker/%s" .WorkerIP) "vault_allocation_index") "0" -}}

services:

  vault:
    image: hashicorp/vault:1.17
    container_name: vault
    hostname: "{{ .WorkerIP }}"
    network_mode: host
    restart: always
    cap_add:
      - IPC_LOCK
    environment:
      VAULT_ADDR: "http://127.0.0.1:8200"
      VAULT_API_ADDR: "http://{{ .WorkerIP }}:8200"
      VAULT_CLUSTER_ADDR: "http://{{ .WorkerIP }}:8201"
    volumes:
      - ./data:/vault/data
      - ./config.hcl:/vault/config/config.hcl:ro
      - ./entrypoint.sh:/vault/config/entrypoint.sh:ro
    entrypoint: ["/bin/sh", "/vault/config/entrypoint.sh"]
    command: ["server", "-config=/vault/config/config.hcl"]
