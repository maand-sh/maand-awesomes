.PHONY: start stop restart fix-data-perms

fix-data-perms:
	mkdir -p ./data
	chmod 0755 ./data || true

# Host network: listen port comes from command/env, not published ports. Compose
# may skip recreation on plain `up -d`; force-recreate picks up bucket port changes.
start: fix-data-perms
	docker compose up -d --force-recreate --remove-orphans

stop:
	docker compose down

restart: fix-data-perms
	docker compose up -d --force-recreate --remove-orphans
