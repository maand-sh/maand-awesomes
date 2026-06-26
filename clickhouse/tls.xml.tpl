<clickhouse>
    <http_port remove="1"/>
    <tcp_port remove="1"/>
    <mysql_port remove="1"/>
    <postgresql_port remove="1"/>
    <https_port>{{ get "maand" "clickhouse_port_https" }}</https_port>
    <tcp_port_secure>{{ get "maand" "clickhouse_port_native_tls" }}</tcp_port_secure>

    <openSSL>
        <server>
            <certificateFile>/etc/clickhouse-server/certs/server.crt</certificateFile>
            <privateKeyFile>/etc/clickhouse-server/certs/server.key</privateKeyFile>
            <caConfig>/etc/clickhouse-server/certs/ca.crt</caConfig>
            <verificationMode>none</verificationMode>
            <loadDefaultCAFile>false</loadDefaultCAFile>
            <cacheSessions>true</cacheSessions>
            <disableProtocols>sslv2,sslv3</disableProtocols>
            <preferServerCiphers>true</preferServerCiphers>
        </server>
        <client>
            <loadDefaultCAFile>false</loadDefaultCAFile>
            <caConfig>/etc/clickhouse-server/certs/ca.crt</caConfig>
            <cacheSessions>true</cacheSessions>
            <disableProtocols>sslv2,sslv3</disableProtocols>
            <preferServerCiphers>true</preferServerCiphers>
            <verificationMode>none</verificationMode>
            <invalidCertificateHandler>
                <name>AcceptCertificateHandler</name>
            </invalidCertificateHandler>
        </client>
    </openSSL>
</clickhouse>
