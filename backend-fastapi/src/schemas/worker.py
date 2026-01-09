from __future__ import annotations
from pydantic import BaseModel, Field


class CreateBatchSchema(BaseModel):
    product_name: str = Field(min_length=1, max_length=128)
    batch_code: str = Field(min_length=1, max_length=64)
    qty_kg: float = Field(gt=0)


class SetBatchStatusSchema(BaseModel):
    batch_code: str = Field(min_length=1, max_length=64)
    status: str = Field(min_length=1, max_length=64)


class RecordQualityTestSchema(BaseModel):
    batch_code: str = Field(min_length=1, max_length=64)
    result: str = Field(min_length=1, max_length=32)  # public.test_result
    ph: float | None = None
    moisture_pct: float | None = None
    comments: str | None = None


class UpsertSupplySchema(BaseModel):
    supplier_name: str = Field(min_length=1, max_length=128)
    raw_material_name: str = Field(min_length=1, max_length=128)
    unit: str = Field(min_length=1, max_length=32)
    cost_numeric: float = Field(gt=0)
    lead_time_days: int = Field(ge=0)
