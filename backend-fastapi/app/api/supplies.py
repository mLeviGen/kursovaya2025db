from fastapi import APIRouter, Depends
from fastapi.encoders import jsonable_encoder
from psycopg import AsyncConnection
from psycopg.rows import dict_row

from ..db import get_conn

router = APIRouter(tags=["supplies"])

@router.get("/supplies")
async def list_supplies(
    limit: int = 200,
    offset: int = 0,
    conn: AsyncConnection = Depends(get_conn),
):
    async with conn.cursor(row_factory=dict_row) as cur:
        await cur.execute("SELECT * FROM public.supplies_view LIMIT %s OFFSET %s;", (limit, offset))
        rows = await cur.fetchall()
    return jsonable_encoder(rows)
