.PHONY: start stop restart

start:
	docker compose up -d --remove-orphans

stop:
	docker compose down

restart:
	docker compose up -d --remove-orphans
	docker compose restart haproxy
