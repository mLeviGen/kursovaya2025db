from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from psycopg import AsyncConnection

from ..db import get_conn

router = APIRouter(tags=["quality"])


class RecordQualityTestIn(BaseModel):
    batch_id: int
    inspector_id: int | None = None
    ph: float | None = Field(default=None, ge=0, le=14)
    moisture_pct: float | None = Field(default=None, ge=0, le=100)
    micro_bio: str | None = None
    status: str  # PASS/FAIL


@router.post("/quality-tests")
async def record_quality_test(payload: RecordQualityTestIn, conn: AsyncConnection = Depends(get_conn)):
    async with conn.cursor() as cur:
        try:
            await cur.execute(
                "SELECT public.record_quality_test(%s, %s, %s, %s, %s, %s);",
                (
                    payload.batch_id,
                    payload.inspector_id,
                    payload.ph,
                    payload.moisture_pct,
                    payload.micro_bio,
                    payload.status,
                ),
            )
            row = await cur.fetchone()
            if row is None:
                raise RuntimeError("record_quality_test returned no rows")
            test_id = row[0]
        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))

    return {"test_id": test_id}
