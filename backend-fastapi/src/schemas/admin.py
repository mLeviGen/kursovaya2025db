from __future__ import annotations
from pydantic import BaseModel


class SetOrderStatusSchema(BaseModel):
    order_id: int
    status: str  # public.order_status
