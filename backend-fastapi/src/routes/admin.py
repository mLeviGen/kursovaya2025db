from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException

from src.schemas.auth import TokenDataSchema, AdminCreateUserSchema
from src.dependencies.has_role import require_roles
from src.services.admin import AdminService
from src.services.auth import AdminService as AdminUsersService

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/users")
async def users(user: TokenDataSchema = Depends(require_roles("admin"))):
    result = AdminService.get_users(user.login)
    if isinstance(result, RuntimeError):
        raise HTTPException(status_code=401, detail=str(result))
    if isinstance(result, Exception):
        raise HTTPException(status_code=400, detail=str(result))
    return result


@router.post("/users")
async def create_user(data: AdminCreateUserSchema, user: TokenDataSchema = Depends(require_roles("admin"))):
    result = AdminUsersService.create_user(data)
    if isinstance(result, Exception):
        raise HTTPException(status_code=400, detail=str(result))
    return {"detail": "created"}


@router.get("/reports/clients")
async def clients_report(user: TokenDataSchema = Depends(require_roles("admin"))):
    result = AdminService.clients_stats(user.login)
    if isinstance(result, RuntimeError):
        raise HTTPException(status_code=401, detail=str(result))
    if isinstance(result, Exception):
        raise HTTPException(status_code=400, detail=str(result))
    return result


@router.get("/reports/product-sales")
async def product_sales(user: TokenDataSchema = Depends(require_roles("admin"))):
    result = AdminService.product_sales(user.login)
    if isinstance(result, RuntimeError):
        raise HTTPException(status_code=401, detail=str(result))
    if isinstance(result, Exception):
        raise HTTPException(status_code=400, detail=str(result))
    return result


@router.get("/reports/production")
async def production(user: TokenDataSchema = Depends(require_roles("admin"))):
    result = AdminService.production_stats(user.login)
    if isinstance(result, RuntimeError):
        raise HTTPException(status_code=401, detail=str(result))
    if isinstance(result, Exception):
        raise HTTPException(status_code=400, detail=str(result))
    return result


@router.get("/reports/quality")
async def quality(user: TokenDataSchema = Depends(require_roles("admin"))):
    result = AdminService.quality_log(user.login)
    if isinstance(result, RuntimeError):
        raise HTTPException(status_code=401, detail=str(result))
    if isinstance(result, Exception):
        raise HTTPException(status_code=400, detail=str(result))
    return result
