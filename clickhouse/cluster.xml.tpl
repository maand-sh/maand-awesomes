<clickhouse>
    <remote_servers>
        <cluster>
            <shard>
                <internal_replication>true</internal_replication>
                {{- range $index, $ch_ip := split (get "maand/worker" "clickhouse_workers") "," -}}
                <replica>
                    <host>{{ $ch_ip }}</host>
                    <port>{{ get "maand/bucket" "clickhouse_port_native_tls" }}</port>
                    <secure>1</secure>
                    <user>interserver</user>
                    <password>${CLICKHOUSE_INTERSERVER_PASSWORD}</password>
                </replica>
                {{- end -}}
            </shard>
        </cluster>
    </remote_servers>
</clickhouse>
