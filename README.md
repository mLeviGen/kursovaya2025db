# Cheese Information System (monorepo)

Folders:
- db-postgresql: PostgreSQL roles, privileges, schema (tables), functions, triggers, views, seed
- backend-fastapi: FastAPI backend (thin API over DB business logic) — WIP
- frontend-vite-ts: Vite + TS admin UI — WIP

## Requirements
- Docker + Docker Compose

## First run (DB only)
1) Create env:
```bash
cp db-postgresql/.env.example db-postgresql/.env
