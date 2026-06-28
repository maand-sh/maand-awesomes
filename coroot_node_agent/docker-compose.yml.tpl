{{- $hasOtel := false -}}
{{- range split (get "maand/bucket" "activejobs") "," -}}
{{- if eq (trim .) "otel_collector" -}}
{{- $hasOtel = true -}}
{{- end -}}
{{- end -}}
{{- $cpuMHz := int (get "maand/job/coroot_node_agent" "cpu") -}}
{{- $cores := max 1 (div $cpuMHz 2400) -}}
services:

  coroot-node-agent:
    image: ghcr.io/coroot/coroot-node-agent:latest
    container_name: node-agent
    hostname: "{{ .WorkerIP }}"
    network_mode: host
    restart: always
    privileged: true
    pid: "host"
    environment:
      LISTEN: 0.0.0.0:{{ get "maand/bucket" "coroot_node_agent_port_metrics" }}
    volumes:
      - /sys/kernel/tracing:/sys/kernel/tracing
      - /sys/kernel/debug:/sys/kernel/debug
      - /sys/fs/cgroup:/host/sys/fs/cgroup
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./data:/data
    command:
      - --listen=0.0.0.0:{{ get "maand/bucket" "coroot_node_agent_port_metrics" }}
      - --cgroupfs-root=/host/sys/fs/cgroup
      - --wal-dir=/data
{{- if $hasOtel }}
{{- $otelHost := trim (index (split (get "maand/worker" "otel_collector_workers") ",") 0) -}}
      - --logs-endpoint=http://{{ $otelHost }}:{{ get "maand/bucket" "otel_collector_port_http" }}/v1/logs
      - --traces-endpoint=http://{{ $otelHost }}:{{ get "maand/bucket" "otel_collector_port_http" }}/v1/traces
{{- end }}
    deploy:
      resources:
        limits:
          cpus: "{{ $cores }}"
          memory: {{ get "maand/job/coroot_node_agent" "memory" }}m
        reservations:
          cpus: "{{ $cores }}"
          memory: {{ get "maand/job/coroot_node_agent" "min_memory_mb" }}m
