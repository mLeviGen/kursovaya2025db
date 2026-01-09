from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import JSONResponse

from src.controllers.database import DatabaseController
from src.schemas.auth import LoginSchema, RegisterSchema, TokenSchema, TokenDataSchema
from src.dependencies.require_auth import require_auth
from src.utils.crypto import CryptoUtil
from src.services.auth import AuthService

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login", response_model=TokenSchema)
async def login(data: LoginSchema) -> TokenSchema:
    result = AuthService.authenticate(data)

    if isinstance(result, Exception):
        raise HTTPException(status_code=400, detail=str(result))

    if not result:
        raise HTTPException(status_code=401, detail="Invalid credentials")

    db = DatabaseController()
    db.connect(username=data.login, password=data.password)

    token_data = TokenDataSchema(id=int(result["id"]), login=data.login, role=str(result["role"]))
    token = CryptoUtil.create_access_token(token_data)
    return TokenSchema(access_token=token)


@router.post("/register")
async def register(data: RegisterSchema):
    result = AuthService.register(data)

    if isinstance(result, Exception):
        raise HTTPException(status_code=400, detail=str(result))

    # for convenience we also return (id, role) after registration
    auth = AuthService.authenticate(LoginSchema(login=data.login, password=data.password))
    if isinstance(auth, Exception) or not auth:
        return JSONResponse(status_code=201, content={"detail": "Registered"})
    return JSONResponse(status_code=201, content={"detail": "Registered", "id": int(auth["id"]), "role": str(auth["role"])})


@router.post("/logout")
async def logout(current_user: TokenDataSchema = Depends(require_auth)):
    AuthService.logout(current_user.login)
    return JSONResponse(status_code=200, content={"detail": "Logged out successfully"})


@router.get("/me")
async def me(current_user: TokenDataSchema = Depends(require_auth)):
    db = DatabaseController()
    result = db.execute(
        "SELECT * FROM public.me()",
        executor_username=current_user.login,
        fetch_count=1,
        require_session=True,
    )
    if isinstance(result, Exception):
        raise HTTPException(status_code=400, detail=str(result))
    if isinstance(result, RuntimeError):
        raise HTTPException(status_code=401, detail=str(result))
    return result
