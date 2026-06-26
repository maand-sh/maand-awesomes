{{- $nodeId := add (int (get (printf "maand/worker/%s" .WorkerIP) "kafka_broker_allocation_index")) 100 -}}
services:
  kafka-broker:
    image: confluentinc/cp-kafka:7.8.0
    container_name: kafka-broker
    hostname: "{{ .WorkerIP }}"
    network_mode: host
    user: "1000:1000"
    restart: always
    stop_grace_period: 120s
    environment:
      KAFKA_NODE_ID: {{ $nodeId }}
      KAFKA_PROCESS_ROLES: 'broker'
      KAFKA_CONTROLLER_LISTENER_NAMES: 'CONTROLLER'
      KAFKA_CONTROLLER_QUORUM_VOTERS: '{{- range $index, $ip := split (get "maand/worker" "kafka_controller_workers") "," -}}{{ if $index }},{{ end }}{{ add $index 1 }}@{{ $ip }}:29093{{- end -}}'
      CLUSTER_ID: 'MkU3OEVBNTcwNTJENDM2Qk'
      KAFKA_LISTENERS: 'PLAINTEXT://0.0.0.0:29092,PLAINTEXT_HOST://0.0.0.0:9092'
      KAFKA_ADVERTISED_LISTENERS: 'PLAINTEXT://{{ .WorkerIP }}:29092,PLAINTEXT_HOST://{{ .WorkerIP }}:9092'
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: 'CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT'
      KAFKA_INTER_BROKER_LISTENER_NAME: 'PLAINTEXT'
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 3
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 3
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 2
      KAFKA_DEFAULT_REPLICATION_FACTOR: 3
      KAFKA_MIN_IN_SYNC_REPLICAS: 2
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_JMX_PORT: 9999
      KAFKA_JMX_HOSTNAME: localhost
      KAFKA_HEAP_OPTS: "-Xms4G -Xmx4G"
      KAFKA_LOG_RETENTION_HOURS: 168
      KAFKA_LOG_RETENTION_BYTES: 10737418240
      KAFKA_LOG_SEGMENT_BYTES: 1073741824
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: "false"
      KAFKA_NUM_NETWORK_THREADS: 12
      KAFKA_NUM_IO_THREADS: 24
      KAFKA_LOG_CLEANER_THREADS: 2
      KAFKA_COMPRESSION_TYPE: lz4
      KAFKA_NUM_PARTITIONS: 3
      KAFKA_MESSAGE_MAX_BYTES: 10485760
      KAFKA_SOCKET_SEND_BUFFER_BYTES: 102400
      KAFKA_SOCKET_RECEIVE_BUFFER_BYTES: 102400
      KAFKA_SOCKET_REQUEST_MAX_BYTES: 104857600
    deploy:
      resources:
        limits:
          memory: 12G
    healthcheck:
      test: ["CMD-SHELL", "kafka-broker-api-versions --bootstrap-server localhost:29092 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
    volumes:
      - ./data:/var/lib/kafka/data

  kafka-broker-exporter:
    image: bitnami/jmx-exporter:latest
    container_name: kafka-broker-exporter
    network_mode: host
    restart: always
    volumes:
      - ./jmx-exporter-config.yml:/etc/jmx-exporter/config.yml
    command:
      - "5556"
      - "/etc/jmx-exporter/config.yml"
    environment:
      SERVICE_HOST: localhost
      SERVICE_PORT: 9999
    depends_on:
      - kafka-broker
