#!/bin/bash
set -euo pipefail

: "${POSTGRES_USER:?POSTGRES_USER is not set}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is not set}"
: "${POSTGRES_DB:?POSTGRES_DB is not set}"

export PGPASSWORD="$POSTGRES_PASSWORD"
HOST="db"

echo "=========================================="
echo " Starting Cheese Factory DB Migration"
echo "=========================================="

run_sql "/sql/00_init/setup.sql"

run_sql "/sql/01_structure/types.sql"
run_sql "/sql/01_structure/domains.sql"
run_sql "/sql/01_structure/tables.sql"
run_sql "/sql/01_structure/views.sql"

run_sql "/sql/02_logic/triggers.sql"
run_sql "/sql/02_logic/auth.sql"
run_sql "/sql/02_logic/admin.sql"
run_sql "/sql/02_logic/client.sql"
run_sql "/sql/02_logic/staff.sql"

run_sql "/sql/03_data/seed.sql"

echo "=========================================="
echo " Migration completed successfully!"
echo "=========================================="