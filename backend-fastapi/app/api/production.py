from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from psycopg import AsyncConnection

from ..db import get_conn

router = APIRouter(tags=["production"])


class CreateBatchIn(BaseModel):
    product_id: int
    code: str
    prod_date: str  # YYYY-MM-DD
    qty_kg: float = Field(gt=0)


@router.post("/batches")
async def create_batch(payload: CreateBatchIn, conn: AsyncConnection = Depends(get_conn)):
    async with conn.cursor() as cur:
        try:
            await cur.execute(
                "SELECT public.create_batch(%s, %s, %s::date, %s);",
                (payload.product_id, payload.code, payload.prod_date, payload.qty_kg),
            )
            batch_id = (await cur.fetchone())[0]
        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))
    return {"batch_id": batch_id}
