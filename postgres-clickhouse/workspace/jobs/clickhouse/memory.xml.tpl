{{- $is_writer := eq (get (printf "maand/worker/%s" .WorkerIP) "clickhouse_allocation_index") "0" -}}
<clickhouse>
    <!-- 32 GB host (ClickHouse + Keeper); role: {{ if $is_writer }}writer{{ else }}reader{{ end }} -->
    <max_server_memory_usage>25769803776</max_server_memory_usage>
    <max_server_memory_usage_to_ram_ratio>0.75</max_server_memory_usage_to_ram_ratio>
{{- if $is_writer }}
    <!-- Writer 10.48.200.3: smaller caches, RAM for inserts/merges -->
    <mark_cache_size>1073741824</mark_cache_size>
    <uncompressed_cache_size>2147483648</uncompressed_cache_size>
    <mmap_cache_size>1073741824</mmap_cache_size>
    <index_mark_cache_size>536870912</index_mark_cache_size>
    <index_uncompressed_cache_size>536870912</index_uncompressed_cache_size>
{{- else }}
    <!-- Reader 10.48.200.4: large mark + uncompressed caches for SELECT -->
    <cache_size_to_ram_max_ratio>0.85</cache_size_to_ram_max_ratio>
    <mark_cache_size>8589934592</mark_cache_size>
    <uncompressed_cache_size>12884901888</uncompressed_cache_size>
    <mmap_cache_size>2147483648</mmap_cache_size>
    <index_mark_cache_size>2147483648</index_mark_cache_size>
    <index_uncompressed_cache_size>4294967296</index_uncompressed_cache_size>
{{- end }}
</clickhouse>
