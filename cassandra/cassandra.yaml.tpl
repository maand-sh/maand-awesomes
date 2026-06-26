# Cassandra configuration — rendered by maand at deploy time.

cluster_name: 'maand-cluster'
num_tokens: 16
partitioner: org.apache.cassandra.dht.Murmur3Partitioner

# --- Network ---
listen_address: {{ .WorkerIP }}
broadcast_address: {{ .WorkerIP }}
rpc_address: 0.0.0.0
broadcast_rpc_address: {{ .WorkerIP }}

# --- Ports (managed by maand) ---
native_transport_port: {{ get "maand" "cassandra_cql_port" }}
storage_port: {{ get "maand" "cassandra_storage_port" }}
ssl_storage_port: {{ get "maand" "cassandra_ssl_storage_port" }}

# --- Seeds ---
# Single seed (worker_0) for deterministic bootstrap. Multiple seeds on a fresh
# cluster cause split-brain: each seed forms its own ring instead of joining.
seed_provider:
  - class_name: org.apache.cassandra.locator.SimpleSeedProvider
    parameters:
      - seeds: "{{ get "maand/worker" "cassandra_0" }}"

# --- Commit log ---
commitlog_sync: periodic
commitlog_sync_period: 10000ms
commitlog_segment_size: 32MiB

# --- Data directories ---
data_file_directories:
  - /var/lib/cassandra/data
commitlog_directory: /var/lib/cassandra/commitlog
hints_directory: /var/lib/cassandra/hints
saved_caches_directory: /var/lib/cassandra/saved_caches

# --- Security ---
authenticator: AllowAllAuthenticator
authorizer: AllowAllAuthorizer
role_manager: CassandraRoleManager

# --- Snitch ---
endpoint_snitch: SimpleSnitch

# --- Transport ---
start_native_transport: true

# --- Compaction / concurrency ---
concurrent_reads: 32
concurrent_writes: 32
concurrent_counter_writes: 32
memtable_flush_writers: 2

# --- Timeouts ---
read_request_timeout: 5000ms
range_request_timeout: 10000ms
write_request_timeout: 2000ms
request_timeout: 10000ms
