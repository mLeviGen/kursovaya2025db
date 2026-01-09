# backend-fastapi (taxi-style) — Cheese Factory DB

Этот бек повторяет паттерн такси-проекта:
- FastAPI
- JWT
- токен читается из заголовка `token` (как в такси) + поддержка `Authorization: Bearer`
- после `/auth/login` сервер создаёт **постоянное соединение к Postgres под логином пользователя**  
  (как в такси: права режутся на уровне БД)

> Важно: если сервер перезапустится — активные DB-сессии (соединения) пропадут, и нужно будет перелогиниться.

## Быстрый старт

1) Запусти БД (`db-postgresql`) и убедись, что порт наружу, например `5433`.

2) Настрой переменные окружения:
```bash
cd backend-fastapi
cp .env.example .env
```

3) Установи зависимости:
```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

4) Запуск:
```bash
uvicorn main:app --reload --port 8000
```

## API (основное)

### Auth
- `POST /auth/login`  body: `{ "login": "...", "password": "..." }`
  - создаёт JWT + DB connection под этим логином
- `POST /auth/register`  (sign_up → client)
- `GET /auth/me` (нужен token)

Токен можно передавать так:
- `token: <JWT>`  (как в такси)
- или `Authorization: Bearer <JWT>`

### Public
- `GET /public/products`

### Client
- `GET /client/orders`
- `POST /client/orders` body:
```json
{
  "items": [{"product":"Gouda","qty":2}],
  "comments": "..."
}
```
- `POST /client/orders/{id}/cancel`

### Worker
- `POST /worker/batches`
- `POST /worker/quality-tests`
- `GET /worker/supplies`
- `POST /worker/supplies`

### Admin
- `GET /admin/users`
- `POST /admin/users`
- `GET /admin/reports/*`

## Seed логины (если ты не менял seed)
- technologist: `tech_ivan / Pass1234`
- inspector: `insp_oleh / Pass1234`
- manager: `mgr_anna / Pass1234`
- client: `client_petro / ClientPass1`, `client_iryna / ClientPass1`
