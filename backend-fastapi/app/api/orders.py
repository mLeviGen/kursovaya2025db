import json
from typing import List

from fastapi import APIRouter, Depends, HTTPException
from fastapi.encoders import jsonable_encoder
from pydantic import BaseModel, Field
from psycopg import AsyncConnection
from psycopg.types.json import Json
from psycopg.rows import dict_row

from ..db import get_conn

router = APIRouter(tags=["orders"])


class OrderItemIn(BaseModel):
    product_id: int
    qty: float = Field(gt=0)


class CreateOrderIn(BaseModel):
    customer_id: int
    status: str = "NEW"
    comments: str | None = None
    items: List[OrderItemIn]


@router.post("/orders")
async def create_order(payload: CreateOrderIn, conn: AsyncConnection = Depends(get_conn)):
    items = [i.model_dump() for i in payload.items]

    async with conn.cursor() as cur:
        try:
            items_json = json.dumps([i.model_dump() for i in payload.items])
            await cur.execute(
                """
                SELECT public.create_order(
                    %s::int,
                    %s::varchar,
                    %s::text,
                    %s::jsonb
                );
                """,
                (payload.customer_id, payload.status, payload.comments, items_json),
            )
            row = await cur.fetchone()
            if row is None:
                raise RuntimeError("create_order returned no rows")
            order_id = row[0]

        except Exception as e:
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


@router.get("/orders")
async def list_orders(
    limit: int = 100,
    offset: int = 0,
    conn: AsyncConnection = Depends(get_conn),
):
    async with conn.cursor(row_factory=dict_row) as cur:
        await cur.execute("SELECT * FROM public.orders_view LIMIT %s OFFSET %s;", (limit, offset))
        rows = await cur.fetchall()
    return jsonable_encoder(rows)