services:
  cassandra:
    image: cassandra:5
    container_name: cassandra
    network_mode: host
    restart: always
    entrypoint: ["/bin/bash", "/conf/entrypoint.sh"]
    environment:
      MAX_HEAP_SIZE: "{{ div (int (get "maand/job/cassandra" "max_memory_mb")) 2 }}M"
      HEAP_NEWSIZE: "{{ div (int (get "maand/job/cassandra" "max_memory_mb")) 8 }}M"
      JMX_PORT: "{{ get "maand/bucket" "cassandra_jmx_port" }}"
      # The cassandra image entrypoint rewrites cassandra.yaml on every start using
      # these env vars. Without them it resets seeds/addresses to the node's own IP,
      # which makes each node form its own single-node cluster.
      CASSANDRA_SEEDS: "{{ get "maand/worker" "cassandra_0" }}"
      CASSANDRA_LISTEN_ADDRESS: "{{ .WorkerIP }}"
      CASSANDRA_BROADCAST_ADDRESS: "{{ .WorkerIP }}"
      CASSANDRA_BROADCAST_RPC_ADDRESS: "{{ .WorkerIP }}"
      CASSANDRA_RPC_ADDRESS: "0.0.0.0"
      JVM_EXTRA_OPTS: "-javaagent:/opt/jmx/jmx_prometheus_javaagent-1.0.1.jar=0.0.0.0:{{ get "maand/bucket" "cassandra_metrics_port" }}:/opt/jmx/jmx_exporter_config.yaml"
    volumes:
      - ./data:/var/lib/cassandra
      - ./cassandra.yaml:/etc/cassandra/cassandra.yaml
      - ./entrypoint.sh:/conf/entrypoint.sh:ro
      - ./certs:/conf/certs:ro
      - ./jmx:/opt/jmx:ro
    deploy:
      resources:
        limits:
          memory: {{ get "maand/job/cassandra" "memory" }}m
        reservations:
          memory: {{ get "maand/job/cassandra" "min_memory_mb" }}m
