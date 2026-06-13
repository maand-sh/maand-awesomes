{{- $is_writer := eq (get (printf "maand/worker/%s" .WorkerIP) "clickhouse_allocation_index") "0" -}}
<clickhouse>
    <timezone>UTC</timezone>
    <mlock_executable>true</mlock_executable>
    <max_connections>2048</max_connections>
    <keep_alive_timeout>30</keep_alive_timeout>
{{- if $is_writer }}
    <max_concurrent_queries>128</max_concurrent_queries>
{{- else }}
    <max_concurrent_queries>200</max_concurrent_queries>
{{- end }}
    <max_table_size_to_drop>0</max_table_size_to_drop>
    <max_partition_size_to_drop>0</max_partition_size_to_drop>
</clickhouse>
