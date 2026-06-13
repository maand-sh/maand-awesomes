{{- $ch_workers := split (get "maand/worker" "clickhouse_workers") "," -}}
{{- $ch_writer := index $ch_workers 0 -}}
{{- $ch_reader := index $ch_workers 1 -}}
{{- $ch_native := get "maand" "clickhouse_port_native" -}}
global
    log stdout format raw local0
    maxconn 2000

defaults
    log global
    mode tcp
    timeout connect 10s
    timeout client 1m
    timeout server 1m
    timeout check 10s

# Client connections on :6432 are routed to the current Patroni leader.
listen postgres
    bind *:{{ get "maand" "haproxy_port_postgres" }}
    mode tcp
    option tcplog
    option httpchk
    http-check send meth GET uri /primary
    http-check expect status 200
    default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
{{- range $ip := split (get "maand/worker" "postgres_workers") "," }}
    server {{ $ip }} {{ $ip }}:{{ get "maand" "postgres_port_pg" }} check port {{ get "maand" "postgres_port_patroni" }}
{{- end }}

# ClickHouse native write: primary {{ $ch_writer }}, backup {{ $ch_reader }}.
listen clickhouse_native_write
    bind *:{{ get "maand" "haproxy_port_clickhouse_native_write" }}
    mode tcp
    option tcplog
    option tcp-check
    default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
    server {{ $ch_writer }} {{ $ch_writer }}:{{ $ch_native }} check
    server {{ $ch_reader }} {{ $ch_reader }}:{{ $ch_native }} check backup

# ClickHouse native read: primary {{ $ch_reader }}, backup {{ $ch_writer }}.
listen clickhouse_native_read
    bind *:{{ get "maand" "haproxy_port_clickhouse_native_read" }}
    mode tcp
    option tcplog
    option tcp-check
    default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
    server {{ $ch_reader }} {{ $ch_reader }}:{{ $ch_native }} check
    server {{ $ch_writer }} {{ $ch_writer }}:{{ $ch_native }} check backup

frontend prometheus
    bind *:{{ get "maand" "haproxy_port_metrics" }}
    mode http
    http-request use-service prometheus-exporter if { path /metrics }
