# Rendered per allocation — ZooKeeper ensemble for Patroni DCS.
tickTime=2000
initLimit=10
syncLimit=5
dataDir=/data
dataLogDir=/logs
secureClientPort={{ get "maand/bucket" "zookeeper_port_client" }}
4lw.commands.whitelist=srvr,stat,mntr,ruok,conf
maxClientCnxns=256

# Auto-purge: retain 10 snapshots and purge every 1 hour
autopurge.snapRetainCount=10
autopurge.purgeInterval=1

# Disable standalone mode to ensure cluster quorum is always required
standaloneEnabled=false
reconfigEnabled=false

# Quorum TLS (leader election + ZAB) and TLS-only client port (Patroni).
serverCnxnFactory=org.apache.zookeeper.server.NettyServerCnxnFactory
sslQuorum=true
leader.closeSocketAsync=true
learner.closeSocketAsync=true
ssl.quorum.keyStore.location=/data/tls/quorum.pem
ssl.quorum.keyStore.type=PEM
ssl.quorum.trustStore.location=/data/tls/ca.crt
ssl.quorum.trustStore.type=PEM
ssl.quorum.clientAuth=need
ssl.quorum.hostnameVerification=false
ssl.keyStore.location=/data/tls/quorum.pem
ssl.keyStore.type=PEM
ssl.trustStore.location=/data/tls/ca.crt
ssl.trustStore.type=PEM
ssl.clientAuth=need
ssl.hostnameVerification=false
ssl.clientHostnameVerification=false

# Host networking: bind quorum ports on all local IPs (avoids BindException when
# the address in server.N is not assigned to an interface on this host).
quorumListenOnAllIPs=true
metricsProvider.className=org.apache.zookeeper.metrics.prometheus.PrometheusMetricsProvider
metricsProvider.httpPort={{ get "maand/bucket" "zookeeper_port_metrics" }}
{{- range $index, $ip := split (get "maand/job/zookeeper" "workers") "," }}
server.{{ add $index 1 }}={{ $ip }}:{{ get "maand/bucket" "zookeeper_port_follower" }}:{{ get "maand/bucket" "zookeeper_port_election" }}
{{- end }}
