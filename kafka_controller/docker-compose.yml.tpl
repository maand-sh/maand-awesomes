{{- $nodeId := add (int (get (printf "maand/worker/%s" .WorkerIP) "kafka_controller_allocation_index")) 1 -}}
services:
  kafka-controller:
    image: confluentinc/cp-kafka:7.8.0
    container_name: kafka-controller
    hostname: "{{ .WorkerIP }}"
    network_mode: host
    user: "1000:1000"
    restart: always
    stop_grace_period: 120s
    environment:
      KAFKA_NODE_ID: {{ $nodeId }}
      KAFKA_PROCESS_ROLES: 'controller'
      KAFKA_CONTROLLER_LISTENER_NAMES: 'CONTROLLER'
      KAFKA_CONTROLLER_QUORUM_VOTERS: '{{- range $index, $ip := split (get "maand/worker" "kafka_controller_workers") "," -}}{{ if $index }},{{ end }}{{ add $index 1 }}@{{ $ip }}:29093{{- end -}}'
      CLUSTER_ID: 'MkU3OEVBNTcwNTJENDM2Qk'
      KAFKA_LISTENERS: 'CONTROLLER://0.0.0.0:29093'
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: 'CONTROLLER:PLAINTEXT'
      KAFKA_JMX_PORT: 9998
      KAFKA_JMX_HOSTNAME: localhost
      KAFKA_HEAP_OPTS: "-Xms512M -Xmx512M"
      KAFKA_LOG_RETENTION_HOURS: 168
      KAFKA_LOG_RETENTION_BYTES: 1073741824
      KAFKA_LOG_SEGMENT_BYTES: 1073741824
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: "false"
      KAFKA_NUM_NETWORK_THREADS: 3
      KAFKA_NUM_IO_THREADS: 8
      KAFKA_METADATA_LOG_SEGMENT_BYTES: 67108864
      KAFKA_METADATA_LOG_RETENTION_BYTES: 1073741824
      KAFKA_METADATA_MAX_RETENTION_MS: 604800000
    deploy:
      resources:
        limits:
          memory: 1G
    healthcheck:
      test: ["CMD-SHELL", "nc -z localhost 29093 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
    volumes:
      - ./data:/var/lib/kafka/data

  kafka-controller-exporter:
    image: bitnami/jmx-exporter:latest
    container_name: kafka-controller-exporter
    network_mode: host
    restart: always
    volumes:
      - ./jmx-exporter-config.yml:/etc/jmx-exporter/config.yml
    command:
      - "5557"
      - "/etc/jmx-exporter/config.yml"
    environment:
      SERVICE_HOST: localhost
      SERVICE_PORT: 9998
    depends_on:
      - kafka-controller