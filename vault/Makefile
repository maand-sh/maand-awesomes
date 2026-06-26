.PHONY: start stop restart fix-data-perms

# Deploy lifecycle is the default path: deploy_parallel_count=1 / update_parallel_count=1
# start/restart one node at a time (leader vault_0 first); command_node_up
# (after_allocation_started) initializes the leader and unseals each node.

start: fix-data-perms
	docker compose up -d --remove-orphans

stop:
	docker compose down

# Recreate container without compose down — keeps other cluster nodes serving during rolling upgrade.
restart: fix-data-perms
	docker compose up -d --force-recreate --remove-orphans

fix-data-perms:
	mkdir -p ./data
	chmod 700 ./data || true
