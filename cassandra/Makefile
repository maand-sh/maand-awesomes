.PHONY: start stop restart fix-data-perms

fix-data-perms:
	mkdir -p ./data
	chmod 0755 ./data || true

start: fix-data-perms
	docker compose up -d --remove-orphans

stop:
	-docker exec cassandra nodetool drain
	docker compose down

restart: stop fix-data-perms start
