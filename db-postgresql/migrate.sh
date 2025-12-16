#!/bin/bash
set -euo pipefail

: "${POSTGRES_USER:?POSTGRES_USER is not set}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is not set}"
: "${POSTGRES_DB:?POSTGRES_DB is not set}"

export PGPASSWORD="$POSTGRES_PASSWORD"

echo "Starting migration..."
psql -h db -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 \
  -f /sql/migrations/tables.sql \
  -f /sql/migrations/functions.sql \
  -f /sql/migrations/procedures_extra.sql \
  -f /sql/migrations/views.sql \
  -f /sql/migrations/triggers.sql \
  -f /sql/migrations/shop_tables.sql \
  -f /sql/migrations/shop_functions.sql \
  -f /sql/migrations/shop_views.sql \
  -f /sql/migrations/shop_triggers.sql \
  -f /sql/migrations/seed.sql \
  -f /sql/migrations/shop_seed.sql


echo "Migration completed successfully."
