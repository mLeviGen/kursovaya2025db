from __future__ import annotations
from pydantic import BaseModel


class ProductView(BaseModel):
    id: int
    name: str
    cheese_type: str | None = None
    aging_days: int | None = None
    base_price: float | None = None
    is_active: bool | None = None
    recipe_name: str | None = None
