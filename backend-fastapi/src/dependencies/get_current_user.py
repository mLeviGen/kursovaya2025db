from __future__ import annotations

from fastapi import Header
from typing import Optional

from src.schemas.auth import TokenDataSchema
from src.utils.crypto import CryptoUtil


def get_current_user(
    token: Optional[str] = Header(None),
    authorization: Optional[str] = Header(None),
) -> Optional[TokenDataSchema]:
    if not token and authorization:
        # also accept Authorization: Bearer <token>
        prefix = "bearer "
        if authorization.lower().startswith(prefix):
            token = authorization[len(prefix):].strip()

    if not token:
        return None

    return CryptoUtil.verify_access_token(token)
