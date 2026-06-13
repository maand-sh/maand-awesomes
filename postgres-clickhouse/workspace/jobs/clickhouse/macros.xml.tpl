<clickhouse>
    <macros>
        <shard>01</shard>
        <replica>{{ printf "%02d" (add (int (get (printf "maand/worker/%s" .WorkerIP) "clickhouse_allocation_index")) 1) }}</replica>
        <host>{{ .WorkerIP }}</host>
        <cluster>cluster</cluster>
    </macros>
</clickhouse>
