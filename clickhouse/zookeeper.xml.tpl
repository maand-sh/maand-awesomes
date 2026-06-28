<clickhouse>
    <zookeeper>
        <session_timeout_ms>120000</session_timeout_ms>
        <operation_timeout_ms>60000</operation_timeout_ms>
        {{- range $index, $keeper_ip := split (get "maand/worker" "clickhouse_keeper_workers") "," -}}
        <node>
            <host>{{ $keeper_ip }}</host>
            <port>{{ get "maand/bucket" "clickhouse_keeper_port_client_tls" }}</port>
            <secure>1</secure>
        </node>
        {{- end -}}
    </zookeeper>
</clickhouse>
