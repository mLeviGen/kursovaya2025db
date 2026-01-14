from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException

from src.schemas.auth import TokenDataSchema
from src.schemas.authorized import CreateOrderSchema
from src.dependencies.has_role import require_roles
from src.services.authorized import AuthorizedService

router = APIRouter(prefix="/client", tags=["client"])


@router.get("/orders")
async def my_orders(user: TokenDataSchema = Depends(require_roles("client", "admin"))):
    result = AuthorizedService.get_my_orders(user.login)
    if isinstance(result, RuntimeError):
        raise HTTPException(status_code=401, detail=str(result))
    if isinstance(result, Exception):
        raise HTTPException(status_code=400, detail=str(result))
    return result


@router.post("/orders")
async def make_order(data: CreateOrderSchema, user: TokenDataSchema = Depends(require_roles("client", "admin"))):
    items = [{"product_id": i.product_id, "qty": i.qty} for i in data.items]
    result = AuthorizedService.make_order(user.login, items=items, comments=data.comments)
    if isinstance(result, RuntimeError):
        raise HTTPException(status_code=401, detail=str(result))
    if isinstance(result, Exception):
        raise HTTPException(status_code=400, detail=str(result))
    return result


@router.post("/orders/{order_id}/cancel")
async def cancel_order(order_id: int, user: TokenDataSchema = Depends(require_roles("client", "admin"))):
    result = AuthorizedService.cancel_my_order(user.login, order_id)
    if isinstance(result, RuntimeError):
        raise HTTPException(status_code=401, detail=str(result))
    if isinstance(result, Exception):
        raise HTTPException(status_code=400, detail=str(result))
    return {"detail": "cancelled"}
