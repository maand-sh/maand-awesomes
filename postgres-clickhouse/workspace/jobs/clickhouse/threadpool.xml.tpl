{{- $is_writer := eq (get (printf "maand/worker/%s" .WorkerIP) "clickhouse_allocation_index") "0" -}}
<clickhouse>
    <max_thread_pool_size>15000</max_thread_pool_size>
    <thread_pool_queue_size>15000</thread_pool_queue_size>
    <max_thread_pool_free_size>1500</max_thread_pool_free_size>

{{- if $is_writer }}
    <!-- Writer 10.48.200.3: 32 vCPU — merges and inserts -->
    <background_pool_size>32</background_pool_size>
    <background_merges_mutations_concurrency_ratio>2</background_merges_mutations_concurrency_ratio>
    <background_fetches_pool_size>12</background_fetches_pool_size>
    <background_schedule_pool_size>192</background_schedule_pool_size>
{{- else }}
    <!-- Reader 10.48.200.4: 32 vCPU — replication fetch + parallel reads -->
    <background_pool_size>16</background_pool_size>
    <background_merges_mutations_concurrency_ratio>2</background_merges_mutations_concurrency_ratio>
    <background_fetches_pool_size>24</background_fetches_pool_size>
    <background_schedule_pool_size>256</background_schedule_pool_size>
{{- end }}
    <background_merges_mutations_scheduling_policy>round_robin</background_merges_mutations_scheduling_policy>
    <background_move_pool_size>8</background_move_pool_size>
    <background_common_pool_size>8</background_common_pool_size>
    <background_distributed_schedule_pool_size>24</background_distributed_schedule_pool_size>
    <max_io_thread_pool_size>256</max_io_thread_pool_size>
</clickhouse>
