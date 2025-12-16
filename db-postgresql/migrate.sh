#!/bin/bash
set -e 

export PGPASSWORD="$POSTGRES_PASSWORD"

echo "Starting migration..."

psql -h db -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 \
  -f /sql/migrations/tables.sql \
  -f /sql/migrations/functions.sql \
  -f /sql/migrations/triggers.sql \
  -f /sql/migrations/views.sql \
  -f /sql/migrations/seed.sql

echo "Migration completed successfully."