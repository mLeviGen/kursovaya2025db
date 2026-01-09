from __future__ import annotations

from fastapi import Depends, HTTPException, status
from typing import Optional

from src.schemas.auth import TokenDataSchema
from src.dependencies.get_current_user import get_current_user


def require_auth(
    user: Optional[TokenDataSchema] = Depends(get_current_user),
) -> TokenDataSchema:
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")
    return user
