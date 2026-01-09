from __future__ import annotations

from fastapi import APIRouter, HTTPException
from src.services.public import PublicService

router = APIRouter(prefix="/public", tags=["public"])


@router.get("/products")
async def products():
    result = PublicService.get_products()
    if isinstance(result, Exception):
        raise HTTPException(status_code=400, detail=str(result))
    return result


@router.get("/batches")
async def batches():
    result = PublicService.get_batches()
    if isinstance(result, Exception):
        raise HTTPException(status_code=400, detail=str(result))
    return result
