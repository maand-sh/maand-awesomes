.PHONY: start stop restart fix-data-perms

fix-data-perms:
	mkdir -p ./data/traces
	chmod -R 0777 ./data || true

start: fix-data-perms
	docker compose up -d --remove-orphans

stop:
	docker compose down

restart: stop fix-data-perms start
