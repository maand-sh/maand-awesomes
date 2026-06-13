{{- $is_writer := eq (get (printf "maand/worker/%s" .WorkerIP) "clickhouse_allocation_index") "0" -}}
<clickhouse>
    <profiles>
        <!-- Writer node default (10.48.200.3): DDL + heavy inserts -->
        <writer_profile>
            <max_memory_usage>17179869184</max_memory_usage>
            <max_memory_usage_for_user>25769803776</max_memory_usage_for_user>
            <max_threads>32</max_threads>
            <max_execution_time>300</max_execution_time>
            <max_rows_to_read>10000000000</max_rows_to_read>
            <max_bytes_to_read>100000000000</max_bytes_to_read>
            <max_concurrent_queries_for_user>64</max_concurrent_queries_for_user>
            <max_concurrent_queries_for_all_users>128</max_concurrent_queries_for_all_users>
            <max_concurrent_insert_queries>50</max_concurrent_insert_queries>
            <max_concurrent_select_queries>50</max_concurrent_select_queries>
            <load_balancing>random</load_balancing>
            <allow_ddl>1</allow_ddl>
        </writer_profile>
        <!-- Reader node default (10.48.200.4): analytics / SELECT -->
        <reader_profile>
            <max_memory_usage>21474836480</max_memory_usage>
            <max_memory_usage_for_user>25769803776</max_memory_usage_for_user>
            <max_threads>32</max_threads>
            <max_execution_time>600</max_execution_time>
            <max_rows_to_read>10000000000</max_rows_to_read>
            <max_bytes_to_read>100000000000</max_bytes_to_read>
            <max_concurrent_queries_for_user>128</max_concurrent_queries_for_user>
            <max_concurrent_queries_for_all_users>200</max_concurrent_queries_for_all_users>
            <max_concurrent_insert_queries>8</max_concurrent_insert_queries>
            <max_concurrent_select_queries>100</max_concurrent_select_queries>
            <load_balancing>nearest_hostname</load_balancing>
            <prefer_localhost_replica>1</prefer_localhost_replica>
            <allow_ddl>0</allow_ddl>
            <use_uncompressed_cache>1</use_uncompressed_cache>
            <use_query_cache>1</use_query_cache>
            <query_cache_min_query_runs>2</query_cache_min_query_runs>
            <query_cache_ttl>300</query_cache_ttl>
            <merge_tree_max_rows_to_use_cache>1048576</merge_tree_max_rows_to_use_cache>
            <merge_tree_max_bytes_to_use_cache>1073741824</merge_tree_max_bytes_to_use_cache>
        </reader_profile>
        <readonly_profile>
            <readonly>1</readonly>
            <allow_ddl>0</allow_ddl>
            <max_memory_usage>17179869184</max_memory_usage>
            <max_threads>32</max_threads>
            <max_execution_time>600</max_execution_time>
            <load_balancing>nearest_hostname</load_balancing>
            <prefer_localhost_replica>1</prefer_localhost_replica>
            <use_uncompressed_cache>1</use_uncompressed_cache>
            <use_query_cache>1</use_query_cache>
            <query_cache_min_query_runs>2</query_cache_min_query_runs>
            <query_cache_ttl>300</query_cache_ttl>
            <merge_tree_max_rows_to_use_cache>1048576</merge_tree_max_rows_to_use_cache>
            <merge_tree_max_bytes_to_use_cache>1073741824</merge_tree_max_bytes_to_use_cache>
            <constraints>
                <readonly>
                    <readonly/>
                </readonly>
                <allow_ddl>
                    <readonly/>
                </allow_ddl>
            </constraints>
        </readonly_profile>
    </profiles>

    <users>
        <default>
            <password>password123</password>
            <networks>
                <ip>10.48.0.0/16</ip>
                <ip>127.0.0.1</ip>
            </networks>
{{- if $is_writer }}
            <profile>writer_profile</profile>
{{- else }}
            <profile>reader_profile</profile>
{{- end }}
            <quota>default</quota>
{{- if $is_writer }}
            <access_management>1</access_management>
{{- end }}
        </default>
        <interserver>
            <password>password123</password>
            <networks>
                <ip>10.48.0.0/16</ip>
            </networks>
            <profile>writer_profile</profile>
            <quota>default</quota>
        </interserver>
        <readonly>
            <password>ReadonlyPass1</password>
            <networks>
                <ip>10.48.0.0/16</ip>
                <ip>127.0.0.1</ip>
            </networks>
            <profile>readonly_profile</profile>
            <quota>default</quota>
            <grants>
                <query>GRANT SELECT ON *.*</query>
            </grants>
        </readonly>
    </users>

    <quotas>
        <default>
            <interval>
                <duration>3600</duration>
                <queries>0</queries>
                <errors>0</errors>
                <result_rows>0</result_rows>
                <read_rows>0</read_rows>
                <execution_time>0</execution_time>
            </interval>
        </default>
    </quotas>
</clickhouse>
