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

echo "Processing: /sql/run_all.sql"
psql -h "$HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f "/sql/run_all.sql"

echo "=========================================="
echo " Migration completed successfully!"
echo "=========================================="
