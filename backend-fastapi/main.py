from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from src.middleware.rate_limit import RateLimitMiddleware, RateLimitRule

from src.routes.auth import router as auth_router
from src.routes.admin import router as admin_router
from src.routes.worker import router as worker_router
from src.routes.authorized import router as authorized_router
from src.routes.public import router as public_router

app = FastAPI(title="Cheese Factory API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Basic anti-spam rate limits (per IP). For a distributed deployment use Redis, etc.
app.add_middleware(
    RateLimitMiddleware,
    rules=[
        RateLimitRule(method="POST", path_prefix="/auth/login", limit=10, window_sec=60, name="auth_login"),
        RateLimitRule(method="POST", path_prefix="/auth/register", limit=3, window_sec=60, name="auth_register"),
        RateLimitRule(method="POST", path_prefix="/client/orders", limit=20, window_sec=60, name="client_orders"),
    ],
)

app.include_router(auth_router)
app.include_router(public_router)
app.include_router(authorized_router)
app.include_router(worker_router)
app.include_router(admin_router)

@app.get("/health")
async def health():
    return {"status": "ok"}
