services:
  api:
    build: .
    ports:
      - "8000:8000"
    environment:
      DB_HOST: {{ get "maand/worker" "postgres_0" }}
      DB_PORT: 5432
      DB_NAME: {{ get "vars/job/app1" "postgres_database" }}
      DB_USER: {{ get "vars/job/app1" "postgres_user" }}
      DB_PASSWORD: {{ get "vars/job/app1" "postgres_password" }}