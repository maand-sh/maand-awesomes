{{- $mhzPerCore := 2400 -}}
{{- $refCores := 32 -}}
{{- $cores := max 1 (div (int (get "maand/job/clickhouse" "cpu")) $mhzPerCore) -}}
{{- $bgPool := max 2 (div (mul $cores 24) $refCores) -}}
{{- $bgRatio := 2 -}}
{{- $bgTasks := mul $bgPool $bgRatio -}}
<clickhouse>
    <merge_tree>
        <max_suspicious_broken_parts>100</max_suspicious_broken_parts>
        <parts_to_throw_insert>3000</parts_to_throw_insert>
        <parts_to_delay_insert>1500</parts_to_delay_insert>
        <max_delay_to_insert>1</max_delay_to_insert>
        <max_parts_in_total>100000</max_parts_in_total>
        <replicated_deduplication_window>1000</replicated_deduplication_window>
        <replicated_deduplication_window_seconds>604800</replicated_deduplication_window_seconds>
        <!-- Must be <= background_pool_size * background_merges_mutations_concurrency_ratio (threadpool.xml.tpl) -->
        <number_of_free_entries_in_pool_to_execute_mutation>{{ $bgTasks }}</number_of_free_entries_in_pool_to_execute_mutation>
        <number_of_free_entries_in_pool_to_lower_max_size_of_merge>{{ $bgTasks }}</number_of_free_entries_in_pool_to_lower_max_size_of_merge>
        <number_of_free_entries_in_pool_to_execute_optimize_entire_partition>{{ $bgTasks }}</number_of_free_entries_in_pool_to_execute_optimize_entire_partition>
    </merge_tree>
</clickhouse>
