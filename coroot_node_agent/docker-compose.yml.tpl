{{- $hasOtel := false -}}
{{- range keys "maand" -}}
{{- if eq . "otel_collector_port_http" -}}
{{- $hasOtel = true -}}
{{- end -}}
{{- end -}}
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
      LISTEN: 0.0.0.0:{{ get "maand" "coroot_node_agent_port_metrics" }}
    volumes:
      - /sys/kernel/tracing:/sys/kernel/tracing
      - /sys/kernel/debug:/sys/kernel/debug
      - /sys/fs/cgroup:/host/sys/fs/cgroup
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./data:/data
    command:
      - --listen=0.0.0.0:{{ get "maand" "coroot_node_agent_port_metrics" }}
      - --cgroupfs-root=/host/sys/fs/cgroup
      - --wal-dir=/data
{{- if $hasOtel }}
{{- $otelHost := index (split (get "maand/worker" "otel_collector_workers") ",") 0 -}}
      - --logs-endpoint=http://{{ $otelHost }}:{{ get "maand" "otel_collector_port_http" }}/v1/logs
      - --traces-endpoint=http://{{ $otelHost }}:{{ get "maand" "otel_collector_port_http" }}/v1/traces
{{- end }}
    deploy:
      resources:
        limits:
          memory: {{ get "maand/job/coroot_node_agent" "memory" }}m
        reservations:
          memory: {{ get "maand/job/coroot_node_agent" "min_memory_mb" }}m
