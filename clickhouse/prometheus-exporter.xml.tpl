<clickhouse>
    <prometheus>
        <endpoint>/metrics</endpoint>
        <port>{{ get "maand/bucket" "clickhouse_port_metrics" }}</port>
        <metrics>true</metrics>
        <events>true</events>
        <asynchronous_metrics>true</asynchronous_metrics>
        <status_info>true</status_info>
    </prometheus>
</clickhouse>
