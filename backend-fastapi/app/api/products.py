from fastapi import APIRouter, Depends
from psycopg import AsyncConnection

from ..db import get_conn

router = APIRouter(tags=["products"])


@router.get("/products")
async def list_products(conn: AsyncConnection = Depends(get_conn)):
    async with conn.cursor() as cur:
        await cur.execute("""
            SELECT id, name, cheese_type, aging_days, base_price, is_active
            FROM products_view
            ORDER BY id
        """)
        rows = await cur.fetchall()

    return [
        {
            "id": r[0],
            "name": r[1],
            "cheese_type": r[2],
            "aging_days": r[3],
            "base_price": str(r[4]),
            "is_active": r[5],
        }
        for r in rows
    ]
