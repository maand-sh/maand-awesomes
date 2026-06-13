services:

  node-agent:
    image: ghcr.io/coroot/coroot-node-agent:latest
    hostname: "{{ .WorkerIP }}"
    network_mode: host
    restart: always
    privileged: true
    pid: "host"
    environment:
      LISTEN: 0.0.0.0:{{ get "maand" "node_agent_port_metrics" }}
    volumes:
      - /sys/kernel/tracing:/sys/kernel/tracing
      - /sys/kernel/debug:/sys/kernel/debug
      - /sys/fs/cgroup:/host/sys/fs/cgroup
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./data:/data
    command:
      - --listen=0.0.0.0:{{ get "maand" "node_agent_port_metrics" }}
      - --cgroupfs-root=/host/sys/fs/cgroup
      - --traces-endpoint=http://{{ get "maand/worker" "coroot_0" }}:{{ get "maand" "coroot_port_http" }}/v1/traces
      - --logs-endpoint=http://{{ get "maand/worker" "coroot_0" }}:{{ get "maand" "coroot_port_http" }}/v1/logs
      - --profiles-endpoint=http://{{ get "maand/worker" "coroot_0" }}:{{ get "maand" "coroot_port_http" }}/v1/profiles
      - --wal-dir=/data
