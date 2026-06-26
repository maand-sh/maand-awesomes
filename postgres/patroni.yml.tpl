{{ define "pgMemUnit" -}}
{{- $mb := int . -}}
{{- if ge $mb 1024 -}}
{{- div $mb 1024 -}}GB
{{- else -}}
{{- $mb -}}MB
{{- end -}}
{{- end }}
{{ define "pgHbaClients" -}}
{{- range $ip := split (get "maand/worker" "worker_workers") "," }}
{{- if $ip }}
    - hostssl all all {{ $ip }}/32 scram-sha-256
{{- end }}
{{- end }}
{{- end }}
{{ define "pgHbaReplication" -}}
{{- range $ip := split (get "maand/job/postgres" "workers") "," }}
{{- if $ip }}
    - hostssl replication replicator {{ $ip }}/32 scram-sha-256
{{- end }}
{{- end }}
{{- end }}
{{- $clonefrom := eq (get (printf "maand/worker/%s" .WorkerIP) "postgres_allocation_index") "1" -}}
{{- $tls_dir := "/etc/patroni/certs" -}}
{{- $memMB := int (get "maand/job/postgres" "memory") -}}
{{- $sharedMB := div $memMB 4 -}}
{{- $cacheMB := div (mul $memMB 3) 4 -}}
{{- $maintMB := min 2048 (div $memMB 16) -}}
{{- $workMB := min 128 (max 4 (div $memMB 64)) -}}
{{- $maxWalMB := div $memMB 2 -}}
{{- $minWalMB := div $memMB 8 -}}
{{- $walDecodeMB := max 64 (div $memMB 128) -}}
{{- $walBufMB := max 16 (div $sharedMB 512) -}}
{{- $shmMB := add $sharedMB 1024 -}}
scope: postgres
namespace: /service/postgres
name: {{ .WorkerIP }}

restapi:
  listen: 127.0.0.1:{{ get "maand" "postgres_port_patroni" }}
  connect_address: {{ .WorkerIP }}:{{ get "maand" "postgres_port_patroni" }}

zookeeper:
  hosts:
    {{- range $ip := split (get "maand/job/zookeeper" "workers") "," }}
    - {{ $ip }}:{{ get "maand" "zookeeper_port_client" }}
    {{- end }}
  use_ssl: true
  cacert: {{ $tls_dir }}/ca.crt
  cert: {{ $tls_dir }}/zookeeper_client.crt
  key: {{ $tls_dir }}/zookeeper_client.key
  verify: true

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
    - hostssl all all 127.0.0.1/32 scram-sha-256
    - hostssl all all ::1/128 scram-sha-256
{{ template "pgHbaClients" . }}
{{ template "pgHbaReplication" . }}

postgresql:
  listen: 0.0.0.0:{{ get "maand" "postgres_port_pg" }}
  connect_address: {{ .WorkerIP }}:{{ get "maand" "postgres_port_pg" }}
  data_dir: /var/lib/postgresql/pgdata/data
  bin_dir: /usr/lib/postgresql/16/bin
  use_unix_socket: true
  use_unix_socket_repl: true
  authentication:
    superuser:
      username: postgres
      sslmode: verify-ca
      sslrootcert: {{ $tls_dir }}/ca.crt
    replication:
      username: replicator
      sslmode: verify-ca
      sslrootcert: {{ $tls_dir }}/ca.crt
    rewind:
      username: postgres
      sslmode: verify-ca
      sslrootcert: {{ $tls_dir }}/ca.crt
  pg_hba:
    - local all all trust
    - local replication replicator trust
    - hostssl all all 127.0.0.1/32 scram-sha-256
    - hostssl all all ::1/128 scram-sha-256
{{ template "pgHbaClients" . }}
{{ template "pgHbaReplication" . }}
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
    shared_buffers: {{ template "pgMemUnit" $sharedMB }}
    work_mem: {{ $workMB }}MB
    maintenance_work_mem: {{ template "pgMemUnit" $maintMB }}
    effective_cache_size: {{ template "pgMemUnit" $cacheMB }}
    effective_io_concurrency: "200"
    maintenance_io_concurrency: "200"
    random_page_cost: "1.1"
    max_parallel_maintenance_workers: "4"
    wal_decode_buffer_size: {{ $walDecodeMB }}MB
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
    wal_buffers: {{ $walBufMB }}MB
    max_wal_size: {{ template "pgMemUnit" $maxWalMB }}
    min_wal_size: {{ template "pgMemUnit" $minWalMB }}
    checkpoint_completion_target: "0.9"
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
