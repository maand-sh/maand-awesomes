.PHONY: start stop restart fix-data-perms fix-certs-perms

start: fix-data-perms fix-certs-perms
	docker compose up -d --remove-orphans

stop:
	docker compose down

restart: fix-data-perms fix-certs-perms
	docker compose up -d --force-recreate --remove-orphans

fix-data-perms:
	mkdir -p ./data ./logs
	chmod 700 ./data ./logs || true

fix-certs-perms:
	@if [ -d ./certs ]; then \
		chmod 0644 ./certs/*.crt 2>/dev/null || true; \
		chmod 0600 ./certs/quorum.key 2>/dev/null || true; \
	fi
