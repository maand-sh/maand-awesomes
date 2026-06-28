{{- $cpuMHz := int (get "maand/job/otel_collector" "cpu") -}}
{{- $cores := max 1 (div $cpuMHz 2400) -}}
services:
  {{ .Job }}:
    image: otel/opentelemetry-collector-contrib:0.115.1
    container_name: otel-collector
    hostname: "{{ .WorkerIP }}"
    network_mode: host
    restart: always
    volumes:
      - ./otel-collector-config.yml:/etc/otelcol-contrib/config.yaml:ro
      - ./data:/data
    command:
      - --config=/etc/otelcol-contrib/config.yaml
    deploy:
      resources:
        limits:
          cpus: "{{ $cores }}"
          memory: {{ get "maand/job/otel_collector" "memory" }}m
        reservations:
          cpus: "{{ $cores }}"
          memory: {{ get "maand/job/otel_collector" "min_memory_mb" }}m
