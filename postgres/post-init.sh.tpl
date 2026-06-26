#!/bin/bash
set -euo pipefail
psql -p {{ get "maand" "postgres_port_pg" }} -v ON_ERROR_STOP=1 -U postgres -d postgres -c "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;"
