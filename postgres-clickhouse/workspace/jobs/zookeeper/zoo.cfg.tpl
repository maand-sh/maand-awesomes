# Rendered per allocation — 3-node ZooKeeper ensemble for Patroni DCS.
tickTime=2000
initLimit=10
syncLimit=5
dataDir=/data
clientPort={{ get "maand" "zookeeper_port_client" }}
maxClientCnxns=256
# Host networking: bind quorum ports on all local IPs (avoids BindException when
# the address in server.N is not assigned to an interface on this host).
quorumListenOnAllIPs=true
metricsProvider.className=org.apache.zookeeper.metrics.prometheus.PrometheusMetricsProvider
metricsProvider.httpPort={{ get "maand" "zookeeper_port_metrics" }}
{{- range $index, $ip := split (get "maand/job/zookeeper" "workers") "," }}
server.{{ add $index 1 }}={{ $ip }}:{{ get "maand" "zookeeper_port_follower" }}:{{ get "maand" "zookeeper_port_election" }};{{ get "maand" "zookeeper_port_client" }}
{{- end }}
