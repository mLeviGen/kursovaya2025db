from __future__ import annotations

from pydantic import BaseModel, Field


class LoginSchema(BaseModel):
    login: str = Field(min_length=1, max_length=64)
    password: str = Field(min_length=1, max_length=256)


class RegisterSchema(BaseModel):
    login: str = Field(min_length=1, max_length=64)
    password: str = Field(min_length=8, max_length=256)
    email: str = Field(min_length=3, max_length=128)
    phone: str | None = Field(default=None, max_length=32)
    first_name: str = Field(min_length=1, max_length=32)
    last_name: str = Field(min_length=1, max_length=32)


class AdminCreateUserSchema(BaseModel):
    login: str = Field(min_length=1, max_length=64)
    password: str = Field(min_length=8, max_length=256)
    email: str = Field(min_length=3, max_length=128)
    phone: str | None = Field(default=None, max_length=32)
    first_name: str = Field(min_length=1, max_length=32)
    last_name: str = Field(min_length=1, max_length=32)
    role: str = Field(default="client")  # user_role_type in DB


class TokenSchema(BaseModel):
    access_token: str
    token_type: str = "bearer"


class TokenDataSchema(BaseModel):
    # Stored inside JWT + used by dependencies
    id: int
    login: str
    role: str
    exp: int | None = None  # jose will put exp as int timestamp


class AuthenticateResponse(BaseModel):
    id: int
    role: str
