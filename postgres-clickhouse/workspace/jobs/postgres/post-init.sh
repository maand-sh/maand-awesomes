#!/bin/bash
set -euo pipefail
psql -v ON_ERROR_STOP=1 -U postgres -d postgres -c "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;"
