from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

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

app.include_router(auth_router)
app.include_router(public_router)
app.include_router(authorized_router)
app.include_router(worker_router)
app.include_router(admin_router)

@app.get("/health")
async def health():
    return {"status": "ok"}
