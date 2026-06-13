{{- $clonefrom := eq (get (printf "maand/worker/%s" .WorkerIP) "postgres_allocation_index") "1" -}}
{{- $tls_dir := "/var/lib/postgresql/pgdata/tls" -}}
scope: postgres
namespace: /service/postgres
name: {{ .WorkerIP }}

restapi:
  listen: 0.0.0.0:8008
  connect_address: {{ .WorkerIP }}:8008

zookeeper:
  hosts:
    {{- range $ip := split (get "maand/job/zookeeper" "workers") "," }}
    - {{ $ip }}:{{ get "maand" "zookeeper_port_client" }}
    {{- end }}

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 33554432
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:
        hot_standby: "on"
        ssl: "on"
        ssl_cert_file: {{ $tls_dir }}/server.crt
        ssl_key_file: {{ $tls_dir }}/server.key
        ssl_ca_file: {{ $tls_dir }}/ca.crt
  initdb:
    - encoding: UTF8
    - locale: en_US.UTF-8
    - data-checksums
  post_init: /etc/patroni/post-init.sh
  pg_hba:
    - local all all trust
    - local replication replicator trust
    - host all all 127.0.0.1/32 scram-sha-256
    - host all all ::1/128 scram-sha-256
    - host all all 0.0.0.0/0 scram-sha-256
    - hostssl replication replicator 0.0.0.0/0 scram-sha-256

postgresql:
  listen: 0.0.0.0:5432
  connect_address: {{ .WorkerIP }}:5432
  data_dir: /var/lib/postgresql/pgdata/data
  bin_dir: /usr/lib/postgresql/16/bin
  use_unix_socket: true
  use_unix_socket_repl: true
  authentication:
    superuser:
      username: postgres
      password: postgres
      sslmode: verify-ca
      sslrootcert: {{ $tls_dir }}/ca.crt
    replication:
      username: replicator
      password: replicator_password
      sslmode: verify-ca
      sslrootcert: {{ $tls_dir }}/ca.crt
    rewind:
      username: postgres
      password: postgres
      sslmode: verify-ca
      sslrootcert: {{ $tls_dir }}/ca.crt
  pg_hba:
    - local all all trust
    - local replication replicator trust
    - host all all 127.0.0.1/32 scram-sha-256
    - host all all ::1/128 scram-sha-256
    - host all all 0.0.0.0/0 scram-sha-256
    - hostssl replication replicator 0.0.0.0/0 scram-sha-256
  create_replica_methods:
    - basebackup
  basebackup:
    checkpoint: fast
    max-rate: 1024M
    progress:
    verbose:
  parameters:
    listen_addresses: "*"
    hot_standby: "on"
    ssl: "on"
    ssl_cert_file: {{ $tls_dir }}/server.crt
    ssl_key_file: {{ $tls_dir }}/server.key
    ssl_ca_file: {{ $tls_dir }}/ca.crt
    shared_preload_libraries: pg_stat_statements
    pg_stat_statements.max: "10000"
    pg_stat_statements.track: all
    shared_buffers: 31GB
    work_mem: 128MB
    maintenance_work_mem: 8GB
    effective_cache_size: 93GB
    effective_io_concurrency: "200"
    maintenance_io_concurrency: "200"
    random_page_cost: "1.1"
    max_parallel_maintenance_workers: "4"
    wal_decode_buffer_size: 256MB
    recovery_prefetch: "on"
    recovery_min_apply_delay: "0"
    autovacuum_vacuum_scale_factor: "0.02"
    autovacuum_analyze_scale_factor: "0.01"
    track_io_timing: "on"
    wal_level: replica
    wal_log_hints: "on"
    max_wal_senders: "10"
    max_replication_slots: "10"
    max_slot_wal_keep_size: "-1"
    wal_compression: lz4
    wal_buffers: 16MB
    max_wal_size: 16GB
    min_wal_size: 4GB
    checkpoint_completion_target: "0.5"
    bgwriter_delay: 10ms
    bgwriter_lru_maxpages: "1500"
    bgwriter_lru_multiplier: "4.0"
    checkpoint_timeout: 10min
    wal_sync_method: fdatasync
    synchronous_commit: "off"
    hot_standby_feedback: "on"
    max_standby_streaming_delay: 300s
    wal_receiver_timeout: 60s
    wal_receiver_status_interval: 1s

tags:
  nofailover: false
  noloadbalance: false
  clonefrom: {{ $clonefrom }}
  nosync: false
