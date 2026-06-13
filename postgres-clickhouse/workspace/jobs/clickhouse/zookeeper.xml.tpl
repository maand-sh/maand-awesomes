<clickhouse>
    <zookeeper>
        {{- range $index, $keeper_ip := split (get "maand/worker" "clickhouse_keeper_workers") "," -}}
        <node>
            <host>{{ $keeper_ip }}</host>
            <port>9281</port>
            <secure>1</secure>
        </node>
        {{- end -}}
    </zookeeper>
</clickhouse>
