<clickhouse>
    <interserver_http_port remove="1"/>
    <interserver_https_port>{{ get "maand/bucket" "clickhouse_port_interserver_tls" }}</interserver_https_port>
    <interserver_http_host>{{ .WorkerIP }}</interserver_http_host>
    <interserver_http_credentials>
        <user>interserver</user>
        <password>${CLICKHOUSE_INTERSERVER_PASSWORD}</password>
    </interserver_http_credentials>
</clickhouse>
