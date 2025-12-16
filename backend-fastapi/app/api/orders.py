from typing import List
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from psycopg import AsyncConnection
import json

from ..db import get_conn

router = APIRouter(tags=["orders"])


class OrderItemIn(BaseModel):
    product_id: int
    qty: float = Field(gt=0)


class CreateOrderIn(BaseModel):
    customer_id: int
    items: List[OrderItemIn]


@router.post("/orders")
async def create_order(payload: CreateOrderIn, conn: AsyncConnection = Depends(get_conn)):
    items_json = json.dumps([i.model_dump() for i in payload.items])

    async with conn.cursor() as cur:
        try:
            await cur.execute(
                "SELECT public.create_order(%s, %s::jsonb);",
                (payload.customer_id, items_json),
            )
            order_id = (await cur.fetchone())[0]
        except Exception as e:
            # тут можно точнее разбирать ошибки PostgreSQL по pgcode,
            # но пока достаточно текста
            raise HTTPException(status_code=400, detail=str(e))

    return {"order_id": order_id}


@router.post("/orders/{order_id}/cancel")
async def cancel_order(order_id: int, reason: str = "client request", conn: AsyncConnection = Depends(get_conn)):
    async with conn.cursor() as cur:
        try:
            await cur.execute("CALL public.cancel_order(%s, %s);", (order_id, reason))
        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))
    return {"status": "cancelled", "order_id": order_id}
