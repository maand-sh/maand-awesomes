.PHONY: build start stop restart fix-certs-perms

# postgres:16 image UID
# https://github.com/ParminCloud/Containers
POSTGRES_UID := 999

fix-certs-perms:
	@mkdir -p ./data
	@chmod 0755 ./post-init.sh 2>/dev/null || true
	@if [ -d ./certs ]; then \
		chmod 0644 ./certs/*.crt 2>/dev/null || true; \
		chmod 0600 ./certs/server.key ./certs/zookeeper_client.key 2>/dev/null || true; \
	fi
	@chown -R $(POSTGRES_UID):$(POSTGRES_UID) ./certs ./data 2>/dev/null || true
	@chmod 700 ./data 2>/dev/null || true

build:
	docker compose build

start: fix-certs-perms build
	docker compose up -d --remove-orphans

stop:
	docker compose down --remove-orphans

restart: fix-certs-perms build
	docker compose up -d --force-recreate --remove-orphans
