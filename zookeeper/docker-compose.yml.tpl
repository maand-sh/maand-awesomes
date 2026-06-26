{{- $memMB := int (get "maand/job/zookeeper" "memory") -}}
{{- $heapMB := max 512 (div (mul $memMB 3) 4) -}}
services:
  zookeeper:
    image: zookeeper:3.9
    container_name: zookeeper
    hostname: "{{ .WorkerIP }}"
    network_mode: host
    restart: always
    entrypoint: ["/bin/bash", "/conf/entrypoint.sh"]
    environment:
      ZOO_MY_ID: {{ add (int (get (printf "maand/job/zookeeper/worker/%s" .WorkerIP) "zookeeper_allocation_index")) 1 }}
      JVMFLAGS: "-Xms{{ if ge $heapMB 1024 }}{{ div $heapMB 1024 }}g{{ else }}{{ $heapMB }}m{{ end }} -Xmx{{ if ge $heapMB 1024 }}{{ div $heapMB 1024 }}g{{ else }}{{ $heapMB }}m{{ end }}"
      ZOO_METRICS_PROVIDER_CLASS_NAME: org.apache.zookeeper.metrics.prometheus.PrometheusMetricsProvider
      ZOO_4LW_COMMANDS_WHITELIST: "srvr,stat,mntr,conf,ruok"
    deploy:
      resources:
        limits:
          memory: {{ get "maand/job/zookeeper" "memory" }}m
        reservations:
          memory: {{ get "maand/job/zookeeper" "min_memory_mb" }}m
    volumes:
      - ./entrypoint.sh:/conf/entrypoint.sh:ro
      - ./zoo.cfg:/conf/zoo.cfg:ro
      - ./certs:/conf/certs:ro
      - ./data:/data
      - ./logs:/logs
