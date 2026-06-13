.PHONY: build start stop restart fix-certs-perms reinit-cluster clean-volumes reset-zk

# postgres:16 image UID
# https://github.com/ParminCloud/Containers
POSTGRES_UID := 999
ZK_SERVER ?= 10.48.200.3:2181

fix-certs-perms:
	@if [ -d ./certs ]; then \
		chmod 0644 ./certs/*.crt 2>/dev/null || true; \
		chmod 0600 ./certs/server.key 2>/dev/null || true; \
		chown -R $(POSTGRES_UID):$(POSTGRES_UID) ./certs 2>/dev/null || true; \
	fi

build:
	docker compose build

start: fix-certs-perms build
	docker compose up -d --remove-orphans

stop:
	docker compose down -v --remove-orphans

clean-volumes:
	docker compose down -v --remove-orphans

reset-zk:
	docker run --rm --network host zookeeper:3.9 \
		zkCli.sh -server $(ZK_SERVER) deleteall /service/postgres

restart: fix-certs-perms build
	docker compose up -d --force-recreate --remove-orphans

reinit-cluster:
	@echo "Stopping Patroni on this node..."
	$(MAKE) clean-volumes
	@echo "If resetting the whole cluster, run 'make reset-zk' once, then:"
	@echo "  1. make start on the clonefrom node (postgres_allocation_index=1)"
	@echo "  2. wait until it is primary: curl -s http://127.0.0.1:8008/cluster | python3 -m json.tool"
	@echo "  3. make start on remaining postgres nodes"