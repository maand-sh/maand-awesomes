.PHONY: start stop restart fix-data-perms fix-certs-perms

JMX_EXPORTER_VERSION := 1.0.1
JMX_EXPORTER_JAR := jmx/jmx_prometheus_javaagent-$(JMX_EXPORTER_VERSION).jar
JMX_EXPORTER_URL := https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/$(JMX_EXPORTER_VERSION)/jmx_prometheus_javaagent-$(JMX_EXPORTER_VERSION).jar

fix-data-perms:
	mkdir -p ./data
	chmod 0755 ./data || true

fix-certs-perms:
	@if [ -d ./certs ]; then \
		chmod 0644 ./certs/*.crt 2>/dev/null || true; \
		chmod 0600 ./certs/internode.key 2>/dev/null || true; \
	fi

$(JMX_EXPORTER_JAR):
	mkdir -p jmx
	curl -fsSL -o $@ $(JMX_EXPORTER_URL)

start: fix-data-perms fix-certs-perms $(JMX_EXPORTER_JAR)
	docker compose up -d --remove-orphans

stop:
	-docker exec cassandra nodetool drain
	docker compose down

restart: stop fix-data-perms fix-certs-perms start
