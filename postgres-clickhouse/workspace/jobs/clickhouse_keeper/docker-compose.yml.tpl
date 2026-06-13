services:

  keeper-1:
    image: clickhouse/clickhouse-server:26.5
    container_name: clickhouse-keeper
    hostname: "{{ .WorkerIP }}"
    network_mode: host
    user: "101:101"
    restart: always
    stop_grace_period: 120s
    volumes:
      - ./keeper_config.xml:/etc/clickhouse-keeper/keeper_config.xml:ro
      - ./certs:/etc/clickhouse-keeper/certs:ro
      - ./data:/var/lib/clickhouse-keeper
    entrypoint: ["clickhouse-keeper", "--config-file=/etc/clickhouse-keeper/keeper_config.xml"]
