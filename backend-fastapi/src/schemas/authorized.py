from __future__ import annotations
from pydantic import BaseModel, Field


class OrderItemIn(BaseModel):
    product: str = Field(min_length=1, max_length=128)
    qty: int = Field(gt=0)


class CreateOrderSchema(BaseModel):
    items: list[OrderItemIn]
    comments: str | None = None
