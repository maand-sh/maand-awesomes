{{- $memMB := int (get "maand/job/postgres" "memory") -}}
{{- $sharedMB := div $memMB 4 -}}
{{- $shmMB := add $sharedMB 1024 -}}
services:
  postgres:
    build:
      context: .
      dockerfile: Containerfile
      args:
        PGVERSION: "16"
        PATRONI_VERSION: "4.0.6"
    image: patroni:4.0.6-pg16
    container_name: postgres
    hostname: "{{ .WorkerIP }}"
    network_mode: host
    restart: always
    shm_size: {{ if ge $shmMB 1024 }}{{ div $shmMB 1024 }}gb{{ else }}{{ $shmMB }}mb{{ end }}
    environment:
      PATRONI_CONFIG: /etc/patroni.yml
      PGDATA: /var/lib/postgresql/pgdata/data
      PATRONI_SUPERUSER_PASSWORD: ${PATRONI_SUPERUSER_PASSWORD}
      PATRONI_REPLICATION_PASSWORD: ${PATRONI_REPLICATION_PASSWORD}
      PATRONI_RESTAPI_USERNAME: ${PATRONI_RESTAPI_USERNAME}
      PATRONI_RESTAPI_PASSWORD: ${PATRONI_RESTAPI_PASSWORD}
    deploy:
      resources:
        limits:
          memory: {{ get "maand/job/postgres" "memory" }}m
        reservations:
          memory: {{ get "maand/job/postgres" "min_memory_mb" }}m
    volumes:
      - ./data:/var/lib/postgresql/pgdata
      - ./patroni.yml:/etc/patroni.yml:ro
      - ./post-init.sh:/etc/patroni/post-init.sh:ro
      - ./certs:/etc/patroni/certs:ro
    stop_grace_period: 60s

  postgres-exporter:
    image: prometheuscommunity/postgres-exporter
    hostname: "{{ .WorkerIP }}"
    container_name: postgres-exporter
    restart: always
    network_mode: host
    command:
      - --web.listen-address=0.0.0.0:{{ get "maand" "postgres_port_postgres_exporter" }}
    environment:
      DATA_SOURCE_NAME: "postgresql://postgres:${PATRONI_SUPERUSER_PASSWORD}@{{ .WorkerIP }}:{{ get "maand" "postgres_port_pg" }}/postgres?sslmode=require"
    depends_on:
      - postgres
