#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if [[ ! -f ".env" ]]; then
  echo "ERROR: .env not found in $(pwd)"
  echo "Create it first, e.g.: cp .env.example .env"
  exit 1
fi

HOST="${APP_HOST:-0.0.0.0}"
PORT="${APP_PORT:-8000}"

echo "Starting backend on ${HOST}:${PORT} ..."
poetry run uvicorn app.main:app --reload --host "${HOST}" --port "${PORT}"
