from __future__ import annotations

from fastapi import Depends, HTTPException, status

from src.schemas.auth import TokenDataSchema
from src.dependencies.require_auth import require_auth


def require_roles(*allowed_roles: str):
    def dependency(user: TokenDataSchema = Depends(require_auth)) -> TokenDataSchema:
        if user.role not in allowed_roles:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
        return user
    return dependency
