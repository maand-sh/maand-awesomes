services:
  cassandra:
    image: cassandra:5
    container_name: cassandra
    network_mode: host
    restart: always
    environment:
      MAX_HEAP_SIZE: "{{ div (int (get "maand/job/cassandra" "max_memory_mb")) 2 }}M"
      HEAP_NEWSIZE: "{{ div (int (get "maand/job/cassandra" "max_memory_mb")) 8 }}M"
      JMX_PORT: "{{ get "maand" "cassandra_jmx_port" }}"
      # The cassandra image entrypoint rewrites cassandra.yaml on every start using
      # these env vars. Without them it resets seeds/addresses to the node's own IP,
      # which makes each node form its own single-node cluster.
      CASSANDRA_SEEDS: "{{ get "maand/worker" "cassandra_0" }}"
      CASSANDRA_LISTEN_ADDRESS: "{{ .WorkerIP }}"
      CASSANDRA_BROADCAST_ADDRESS: "{{ .WorkerIP }}"
      CASSANDRA_BROADCAST_RPC_ADDRESS: "{{ .WorkerIP }}"
      CASSANDRA_RPC_ADDRESS: "0.0.0.0"
    volumes:
      - ./data:/var/lib/cassandra
      - ./cassandra.yaml:/etc/cassandra/cassandra.yaml
    deploy:
      resources:
        limits:
          memory: {{ get "maand/job/cassandra" "memory" }}m
        reservations:
          memory: {{ get "maand/job/cassandra" "min_memory_mb" }}m
