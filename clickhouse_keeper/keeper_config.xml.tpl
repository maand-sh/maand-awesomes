<clickhouse>
    <listen_host>0.0.0.0</listen_host>

    <logger>
        <level>information</level>
        <console>1</console>
        <log remove="1"/>
        <errorlog remove="1"/>
        <levels>
            <logger>
                <name>PrometheusRequestHandler</name>
                <level>warning</level>
            </logger>
        </levels>
    </logger>

    <keeper_path>/var/lib/clickhouse-keeper</keeper_path>

    <max_connections>4096</max_connections>

    <keeper_server>
        <tcp_port_secure>{{ get "maand/bucket" "clickhouse_keeper_port_client_tls" }}</tcp_port_secure>
        <server_id>{{ add (int (get (printf "maand/worker/%s" .WorkerIP) "clickhouse_keeper_allocation_index")) 1 }}</server_id>
        <log_storage_path>/var/lib/clickhouse-keeper/coordination/log</log_storage_path>
        <snapshot_storage_path>/var/lib/clickhouse-keeper/coordination/snapshots</snapshot_storage_path>

        <coordination_settings>
            <operation_timeout_ms>30000</operation_timeout_ms>
            <session_timeout_ms>60000</session_timeout_ms>
        </coordination_settings>

        <four_letter_word_allow_list>ruok,mntr,stat</four_letter_word_allow_list>

        <raft_configuration>
            {{- range $index, $keeper_ip := split (get "maand/worker" "clickhouse_keeper_workers") "," -}}
            <server>
                <id>{{ add $index 1 }}</id>
                <hostname>{{ $keeper_ip }}</hostname>
                <port>{{ get "maand/bucket" "clickhouse_keeper_port_raft" }}</port>
            </server>
            {{- end -}}
        </raft_configuration>
    </keeper_server>

    <openSSL>
        <server>
            <certificateFile>/etc/clickhouse-keeper/certs/server.crt</certificateFile>
            <privateKeyFile>/etc/clickhouse-keeper/certs/server.key</privateKeyFile>
            <caConfig>/etc/clickhouse-keeper/certs/ca.crt</caConfig>
            <verificationMode>none</verificationMode>
            <loadDefaultCAFile>false</loadDefaultCAFile>
            <cacheSessions>true</cacheSessions>
            <disableProtocols>sslv2,sslv3</disableProtocols>
            <preferServerCiphers>true</preferServerCiphers>
        </server>
        <client>
            <loadDefaultCAFile>false</loadDefaultCAFile>
            <caConfig>/etc/clickhouse-keeper/certs/ca.crt</caConfig>
            <cacheSessions>true</cacheSessions>
            <disableProtocols>sslv2,sslv3</disableProtocols>
            <preferServerCiphers>true</preferServerCiphers>
            <verificationMode>none</verificationMode>
            <invalidCertificateHandler>
                <name>AcceptCertificateHandler</name>
            </invalidCertificateHandler>
        </client>
    </openSSL>

    <prometheus>
        <endpoint>/metrics</endpoint>
        <port>{{ get "maand/bucket" "clickhouse_keeper_port_metrics" }}</port>
        <metrics>true</metrics>
        <events>true</events>
        <asynchronous_metrics>true</asynchronous_metrics>
        <status_info>true</status_info>
    </prometheus>
</clickhouse>
