<clickhouse>
    <!-- Drop default plain interserver port from the base image config -->
    <interserver_http_port remove="1"/>
    <interserver_https_port>9010</interserver_https_port>
    <interserver_http_host>{{ .WorkerIP }}</interserver_http_host>
    <interserver_http_credentials>
        <user>interserver</user>
        <password>password123</password>
    </interserver_http_credentials>
</clickhouse>
