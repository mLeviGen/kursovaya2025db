from fastapi import APIRouter, Depends
from psycopg import AsyncConnection
from ..db import get_conn

router = APIRouter(tags=["health"])

@router.get("/health")
async def health():
    return {"status": "ok"}

@router.get("/db/ping")
async def db_ping(conn: AsyncConnection = Depends(get_conn)):
    async with conn.cursor() as cur:
        await cur.execute("SELECT 1;")
        row = await cur.fetchone()
        if row is None:
            raise RuntimeError("DB ping returned no rows")
        val = row[0]
    return {"db": "ok", "value": val}
