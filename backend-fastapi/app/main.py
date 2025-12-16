from contextlib import asynccontextmanager

from fastapi import FastAPI

from .db import open_pool, close_pool
from .api.health import router as health_router
from .api.products import router as products_router
from .api.orders import router as orders_router
from .api.production import router as production_router
from .api.quality import router as quality_router
from .api.supplies import router as supplies_router
from .api.reports import router as reports_router


@asynccontextmanager
async def lifespan(_: FastAPI):
    await open_pool()
    yield
    await close_pool()


app = FastAPI(title="Cheese IS API", version="0.1.0", lifespan=lifespan)

app.include_router(health_router, prefix="/api")
app.include_router(products_router, prefix="/api")
app.include_router(orders_router, prefix="/api")
app.include_router(production_router, prefix="/api")
app.include_router(quality_router, prefix="/api")
app.include_router(supplies_router, prefix="/api")
app.include_router(reports_router, prefix="/api")