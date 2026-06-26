.PHONY: start stop restart fix-data-perms

fix-data-perms:
	mkdir -p ./data
	chown 1000:1000 ./data || true
	chmod 0755 ./data || true

start: fix-data-perms
	docker compose up -d --remove-orphans

stop:
	docker compose down

restart: stop start
