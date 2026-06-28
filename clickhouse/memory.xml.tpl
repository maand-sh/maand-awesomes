{{- $memMB := int (get "maand/job/clickhouse" "memory") -}}
{{- $memBytes := mul $memMB 1048576 -}}
<clickhouse>
    <max_server_memory_usage>{{ $memBytes }}</max_server_memory_usage>
    <max_server_memory_usage_to_ram_ratio>0.75</max_server_memory_usage_to_ram_ratio>
    <mark_cache_size>{{ div (mul $memMB 1048576) 12 }}</mark_cache_size>
    <uncompressed_cache_size>{{ div (mul $memMB 1048576) 6 }}</uncompressed_cache_size>
    <mmap_cache_size>{{ div (mul $memMB 1048576) 24 }}</mmap_cache_size>
    <index_mark_cache_size>{{ div (mul $memMB 1048576) 24 }}</index_mark_cache_size>
    <index_uncompressed_cache_size>{{ div (mul $memMB 1048576) 12 }}</index_uncompressed_cache_size>
</clickhouse>
