from __future__ import annotations
from pydantic import BaseModel, Field


class OrderItemIn(BaseModel):
    # Use stable product_id instead of product name (avoids typos / ambiguity).
    product_id: int = Field(gt=0)
    qty: int = Field(gt=0)


class CreateOrderSchema(BaseModel):
    items: list[OrderItemIn]
    comments: str | None = None
