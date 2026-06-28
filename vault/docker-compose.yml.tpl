{{- $api_port := get "maand/bucket" "vault_port_api" -}}
{{- $cluster_port := get "maand/bucket" "vault_port_cluster" -}}
{{- $cpuMHz := int (get "maand/job/vault" "cpu") -}}
{{- $cores := max 1 (div $cpuMHz 2400) -}}

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
      VAULT_ADDR: "https://127.0.0.1:{{ $api_port }}"
      VAULT_API_ADDR: "https://{{ .WorkerIP }}:{{ $api_port }}"
      VAULT_CLUSTER_ADDR: "https://{{ .WorkerIP }}:{{ $cluster_port }}"
      VAULT_CACERT: "/vault/tls/ca.crt"
    volumes:
      - ./data:/vault/data
      - ./certs:/vault/tls:ro
      - ./config.hcl:/vault/config/config.hcl:ro
      - ./entrypoint.sh:/vault/config/entrypoint.sh:ro
    entrypoint: ["/bin/sh", "/vault/config/entrypoint.sh"]
    command: ["server", "-config=/vault/config/config.hcl"]
    deploy:
      resources:
        limits:
          cpus: "{{ $cores }}"
          memory: {{ get "maand/job/vault" "memory" }}m
        reservations:
          cpus: "{{ $cores }}"
          memory: {{ get "maand/job/vault" "min_memory_mb" }}m
