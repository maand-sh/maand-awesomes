.PHONY: start stop restart fix-data-perms reinit-ensemble

# Wipe local ZK data after ensemble membership changes (add/remove/replace a node).
# Run on EVERY zookeeper allocation before redeploying the job together.
reinit-ensemble:
	docker compose down
	rm -rf ./data/*
	$(MAKE) start

start: fix-data-perms
	docker compose up -d --remove-orphans

stop:
	docker compose down

restart: fix-data-perms
	docker compose up -d --force-recreate --remove-orphans

fix-data-perms:
	mkdir -p ./data
	chmod 700 ./data || true
