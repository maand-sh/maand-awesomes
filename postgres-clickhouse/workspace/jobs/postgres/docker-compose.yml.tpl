services:

  patroni:
    build:
      context: .
      dockerfile: Containerfile
      args:
        PGVERSION: "16"
        PATRONI_VERSION: "4.0.6"
    image: patroni:4.0.6-pg16
    container_name: patroni
    hostname: "{{ .WorkerIP }}"
    user: "0:0"
    network_mode: host
    restart: always
    shm_size: 32gb
    environment:
      PATRONI_CONFIG: /etc/patroni.yml
      PGDATA: /var/lib/postgresql/pgdata/data
    tmpfs:
      - /var/lib/postgresql/pgdata:uid=999,gid=999,mode=0700
    volumes:
      - ./patroni.yml:/etc/patroni.yml:ro
      - ./post-init.sh:/etc/patroni/post-init.sh:ro
      - ./certs:/etc/patroni/certs:ro
    stop_grace_period: 60s

  postgres-exporter:
    image: prometheuscommunity/postgres-exporter
    hostname: "{{ .WorkerIP }}-exporter"
    restart: always
    network_mode: host
    environment:
      DATA_SOURCE_NAME: "postgresql://postgres:postgres@{{ .WorkerIP }}:{{ get "maand" "postgres_port_pg" }}/postgres?sslmode=disable"
    depends_on:
      - patroni
