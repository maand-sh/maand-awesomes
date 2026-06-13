.PHONY: start stop restart clean-volumes

start:
	docker compose up -d --remove-orphans

stop:
	docker compose down -v --remove-orphans

clean-volumes:
	docker compose down -v --remove-orphans
	-docker volume rm prometheus_clickhouse_data prometheus_prometheus_data clickhouse_data prometheus_data

restart: stop start
