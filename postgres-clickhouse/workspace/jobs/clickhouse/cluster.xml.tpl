<clickhouse>
    <remote_servers>
        <cluster>
            <shard>
                <internal_replication>true</internal_replication>
                {{- range $index, $ch_ip := split (get "maand/worker" "clickhouse_workers") "," -}}
                <replica>
                    <host>{{ $ch_ip }}</host>
                    <port>9440</port>
                    <secure>1</secure>
                    <user>default</user>
                    <password>password123</password>
                </replica>
                {{- end -}}
            </shard>
        </cluster>
    </remote_servers>
</clickhouse>
