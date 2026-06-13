<clickhouse>
    <hostname>{{ .WorkerIP }}</hostname>
    <!-- Drop default IPv6 listeners from the base image config -->
    <listen_host remove="1">::</listen_host>
    <listen_host remove="1">::1</listen_host>
    <listen_host>0.0.0.0</listen_host>
</clickhouse>
