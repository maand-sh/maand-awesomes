services:

  haproxy:
    image: haproxy:3.0-alpine
    container_name: haproxy
    hostname: "{{ .WorkerIP }}"
    network_mode: host
    restart: always
    volumes:
      - ./haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro
