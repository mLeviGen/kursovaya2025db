from __future__ import annotations

from datetime import datetime, timedelta, timezone
from jose import JWTError, jwt

from config import JWT_SECRET_KEY, JWT_ALGORITHM, JWT_TOKEN_LIFETIME
from src.schemas.auth import TokenDataSchema


class CryptoUtil:
    @staticmethod
    def create_access_token(data: TokenDataSchema) -> str:
        to_encode = data.model_dump()
        expire = datetime.now(timezone.utc) + timedelta(minutes=JWT_TOKEN_LIFETIME)
        to_encode.update({"exp": expire})
        return jwt.encode(to_encode, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)

    @staticmethod
    def verify_access_token(token: str) -> TokenDataSchema | None:
        try:
            payload = jwt.decode(token, JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM])
            return TokenDataSchema(**payload)
        except JWTError:
            return None
