{{- $mhzPerCore := 2400 -}}
{{- $refCores := 32 -}}
{{- $cores := max 1 (div (int (get "maand/job/clickhouse" "cpu")) $mhzPerCore) -}}
<clickhouse>
    <timezone>UTC</timezone>
    <mlock_executable>true</mlock_executable>
    <max_connections>2048</max_connections>
    <keep_alive_timeout>30</keep_alive_timeout>
    <max_concurrent_queries>{{ max 4 (div (mul $cores 164) $refCores) }}</max_concurrent_queries>
    <max_table_size_to_drop>50000000000</max_table_size_to_drop>
    <max_partition_size_to_drop>50000000000</max_partition_size_to_drop>
</clickhouse>
