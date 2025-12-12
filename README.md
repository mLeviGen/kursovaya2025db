# Cheese IS

Monorepo:
- db-postgresql: schema, functions, triggers, views, seed
- backend-fastapi: API
- frontend-vite-ts: simple admin UI

## Run DB
cd db-postgresql
docker compose up -d

## Run backend
cd backend-fastapi
# create venv, install deps, run uvicorn...

## Run frontend
cd frontend-vite-ts
npm i
npm run dev
