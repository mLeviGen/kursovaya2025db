from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException

from src.schemas.auth import TokenDataSchema
from src.schemas.worker import (
    CreateBatchSchema,
    RecordQualityTestSchema,
    SetBatchStatusSchema,
    UpsertSupplySchema,
)
from src.dependencies.has_role import require_roles
from src.services.worker import WorkerService

router = APIRouter(prefix="/worker", tags=["worker"])


@router.get("/orders")
async def orders(user: TokenDataSchema = Depends(require_roles("technologist", "inspector", "manager", "admin"))):
    result = WorkerService.get_orders(user.login)
    if isinstance(result, RuntimeError):
        raise HTTPException(status_code=401, detail=str(result))
    if isinstance(result, Exception):
        raise HTTPException(status_code=400, detail=str(result))
    return result


@router.post("/orders/{order_id}/status")
async def set_order_status(order_id: int, status: str, user: TokenDataSchema = Depends(require_roles("manager", "admin"))):
    result = WorkerService.set_order_status(user.login, order_id=order_id, status=status)
    if isinstance(result, RuntimeError):
        raise HTTPException(status_code=401, detail=str(result))
    if isinstance(result, Exception):
        raise HTTPException(status_code=400, detail=str(result))
    return {"detail": "ok"}


@router.get("/batches")
async def batches(user: TokenDataSchema = Depends(require_roles("technologist", "inspector", "manager", "admin"))):
    result = WorkerService.get_batches(user.login)
    if isinstance(result, RuntimeError):
        raise HTTPException(status_code=401, detail=str(result))
    if isinstance(result, Exception):
        raise HTTPException(status_code=400, detail=str(result))
    return result


@router.post("/batches")
async def create_batch(data: CreateBatchSchema, user: TokenDataSchema = Depends(require_roles("technologist", "manager", "admin"))):
    result = WorkerService.create_batch(user.login, data.product_name, data.batch_code, data.qty_kg)
    if isinstance(result, RuntimeError):
        raise HTTPException(status_code=401, detail=str(result))
    if isinstance(result, Exception):
        raise HTTPException(status_code=400, detail=str(result))
    return result


@router.post("/batches/status")
async def set_batch_status(data: SetBatchStatusSchema, user: TokenDataSchema = Depends(require_roles("manager", "admin"))):
    result = WorkerService.set_batch_status(user.login, data.batch_code, data.status)
    if isinstance(result, RuntimeError):
        raise HTTPException(status_code=401, detail=str(result))
    if isinstance(result, Exception):
        raise HTTPException(status_code=400, detail=str(result))
    return {"detail": "ok"}


@router.post("/quality-tests")
async def record_quality_test(data: RecordQualityTestSchema, user: TokenDataSchema = Depends(require_roles("inspector", "admin"))):
    result = WorkerService.record_quality_test(
        user.login,
        batch_code=data.batch_code,
        result=data.result,
        ph=data.ph,
        moisture_pct=data.moisture_pct,
        comments=data.comments,
    )
    if isinstance(result, RuntimeError):
        raise HTTPException(status_code=401, detail=str(result))
    if isinstance(result, Exception):
        raise HTTPException(status_code=400, detail=str(result))
    return result


@router.get("/quality-tests/{batch_code}")
async def quality_tests(batch_code: str, user: TokenDataSchema = Depends(require_roles("inspector", "manager", "admin"))):
    result = WorkerService.get_quality_tests(user.login, batch_code)
    if isinstance(result, RuntimeError):
        raise HTTPException(status_code=401, detail=str(result))
    if isinstance(result, Exception):
        raise HTTPException(status_code=400, detail=str(result))
    return result


@router.get("/supplies")
async def supplies(user: TokenDataSchema = Depends(require_roles("technologist", "manager", "admin"))):
    result = WorkerService.get_supplies(user.login)
    if isinstance(result, RuntimeError):
        raise HTTPException(status_code=401, detail=str(result))
    if isinstance(result, Exception):
        raise HTTPException(status_code=400, detail=str(result))
    return result


@router.post("/supplies")
async def upsert_supply(data: UpsertSupplySchema, user: TokenDataSchema = Depends(require_roles("technologist", "manager", "admin"))):
    result = WorkerService.upsert_supply(
        user.login,
        supplier_name=data.supplier_name,
        raw_material_name=data.raw_material_name,
        unit=data.unit,
        cost_numeric=data.cost_numeric,
        lead_time_days=data.lead_time_days,
    )
    if isinstance(result, RuntimeError):
        raise HTTPException(status_code=401, detail=str(result))
    if isinstance(result, Exception):
        raise HTTPException(status_code=400, detail=str(result))
    return result
