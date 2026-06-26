<clickhouse>
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
</clickhouse>
