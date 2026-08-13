"""Schémas Pydantic liés à l'authentification."""
from typing import Optional

from pydantic import BaseModel, EmailStr, Field


class RegisterRequest(BaseModel):
    full_name: str = Field(..., min_length=2, max_length=150)
    organization_name: str = Field(..., min_length=2, max_length=200)
    org_type: str = Field(default="startup")
    country_id: int
    sector_id: Optional[int] = None
    email: EmailStr
    phone: Optional[str] = None
    password: str = Field(..., min_length=6)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshTokenRequest(BaseModel):
    refresh_token: str
