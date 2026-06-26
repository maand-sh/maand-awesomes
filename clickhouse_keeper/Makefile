.PHONY: start stop restart fix-data-perms

# clickhouse/clickhouse-server runs as clickhouse (101)
CLICKHOUSE_UID := 101

fix-data-perms:
	mkdir -p ./data/coordination/log ./data/coordination/snapshots ./certs
	chown -R $(CLICKHOUSE_UID):$(CLICKHOUSE_UID) ./data ./certs || true
	chmod -R 0750 ./data || chmod -R 0777 ./data
	chmod 0755 ./certs || true
	chmod 0640 ./certs/*.crt ./certs/*.key ./certs/ca.crt 2>/dev/null || true

start: fix-data-perms
	docker compose up -d --remove-orphans

stop:
	docker compose down

restart: stop fix-data-perms start