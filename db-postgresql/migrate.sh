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

run_sql() {
    local file=$1
    echo "Processing: $file"
    psql -h "$HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f "$file"
}

run_sql "/sql/_structure/01_roles_and_schemas.sql"

run_sql "/sql/public/types.sql"
run_sql "/sql/public/utils.sql"
run_sql "/sql/public/auth.sql"

run_sql "/sql/private/tables.sql"
run_sql "/sql/private/triggers.sql"

run_sql "/sql/admin/user_management.sql"
run_sql "/sql/admin/analytics_views.sql"

run_sql "/sql/workers/production.sql"
run_sql "/sql/authorized/client_orders.sql"

run_sql "/sql/seed/seed.sql"

echo "=========================================="
echo " Migration completed successfully!"
echo "=========================================="