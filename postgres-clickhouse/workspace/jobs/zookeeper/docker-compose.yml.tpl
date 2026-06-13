services:

  zookeeper:
    image: zookeeper:3.9
    container_name: zookeeper
    hostname: "{{ .WorkerIP }}"
    network_mode: host
    restart: always
    environment:
      ZOO_MY_ID: {{ add (int (get (printf "maand/job/zookeeper/worker/%s" .WorkerIP) "zookeeper_allocation_index")) 1 }}
      JVMFLAGS: "-Xms512m -Xmx512m"
      ZOO_METRICS_PROVIDER_CLASS_NAME: org.apache.zookeeper.metrics.prometheus.PrometheusMetricsProvider
      ZOO_4LW_COMMANDS_WHITELIST: "mntr, conf, ruok, stat"
    volumes:
      - ./zoo.cfg:/conf/zoo.cfg:ro
      - ./data:/data
