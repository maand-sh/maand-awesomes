{{- $mhzPerCore := 2400 -}}
{{- $refCores := 32 -}}
{{- $cores := max 1 (div (int (get "maand/job/clickhouse" "cpu")) $mhzPerCore) -}}
<clickhouse>
    <max_thread_pool_size>15000</max_thread_pool_size>
    <thread_pool_queue_size>15000</thread_pool_queue_size>
    <max_thread_pool_free_size>{{ max 100 (div (mul $cores 1500) $refCores) }}</max_thread_pool_free_size>
    <background_pool_size>{{ max 2 (div (mul $cores 24) $refCores) }}</background_pool_size>
    <background_merges_mutations_concurrency_ratio>2</background_merges_mutations_concurrency_ratio>
    <background_fetches_pool_size>{{ max 2 (div (mul $cores 16) $refCores) }}</background_fetches_pool_size>
    <background_schedule_pool_size>{{ max 4 (div (mul $cores 224) $refCores) }}</background_schedule_pool_size>
    <background_merges_mutations_scheduling_policy>round_robin</background_merges_mutations_scheduling_policy>
    <background_move_pool_size>{{ max 1 (div (mul $cores 8) $refCores) }}</background_move_pool_size>
    <background_common_pool_size>{{ max 1 (div (mul $cores 8) $refCores) }}</background_common_pool_size>
    <background_distributed_schedule_pool_size>{{ max 2 (div (mul $cores 24) $refCores) }}</background_distributed_schedule_pool_size>
    <max_io_thread_pool_size>{{ max 4 (div (mul $cores 256) $refCores) }}</max_io_thread_pool_size>
</clickhouse>
