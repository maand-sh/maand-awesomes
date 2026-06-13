{{- $is_writer := eq (get (printf "maand/worker/%s" .WorkerIP) "clickhouse_allocation_index") "0" -}}
<clickhouse>
    <merge_tree>
        <max_suspicious_broken_parts>100</max_suspicious_broken_parts>
{{- if $is_writer }}
        <parts_to_throw_insert>3000</parts_to_throw_insert>
        <parts_to_delay_insert>1500</parts_to_delay_insert>
{{- else }}
        <parts_to_throw_insert>3000</parts_to_throw_insert>
        <parts_to_delay_insert>1000</parts_to_delay_insert>
{{- end }}
        <max_delay_to_insert>1</max_delay_to_insert>
        <max_parts_in_total>100000</max_parts_in_total>
        <replicated_deduplication_window>1000</replicated_deduplication_window>
        <replicated_deduplication_window_seconds>604800</replicated_deduplication_window_seconds>
    </merge_tree>
</clickhouse>
