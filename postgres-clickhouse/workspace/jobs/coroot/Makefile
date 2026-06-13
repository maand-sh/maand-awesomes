.PHONY: start stop restart fix-data-perms

fix-data-perms:
	mkdir -p ./data/coroot
	chmod -R 0755 ./data/coroot || true

start: fix-data-perms
	docker compose up -d --remove-orphans

stop:
	docker compose down

restart: stop fix-data-perms start
