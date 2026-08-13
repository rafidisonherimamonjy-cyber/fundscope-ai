"""Schémas Pydantic liés à l'utilisateur, son organisation et ses préférences."""
from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, EmailStr, Field


class CountryOut(BaseModel):
    id: int
    code: str
    name: str
    region: Optional[str] = None

    class Config:
        from_attributes = True


class CategoryOut(BaseModel):
    id: int
    name: str
    description: Optional[str] = None
    icon: Optional[str] = None

    class Config:
        from_attributes = True


class OrganizationOut(BaseModel):
    id: int
    name: str
    org_type: str
    website: Optional[str] = None
    country: Optional[CountryOut] = None
    sector: Optional[CategoryOut] = None

    class Config:
        from_attributes = True


class UserPreferenceIn(BaseModel):
    sector_ids: List[int] = Field(default_factory=list)
    country_ids: List[int] = Field(default_factory=list)
    funding_types: List[str] = Field(default_factory=list)
    amount_min: Optional[int] = None
    amount_max: Optional[int] = None
    language: str = "fr"


class UserPreferenceOut(UserPreferenceIn):
    class Config:
        from_attributes = True


class UserOut(BaseModel):
    id: int
    full_name: str
    email: EmailStr
    phone: Optional[str] = None
    role: str
    language: str
    onboarding_completed: bool
    organization: Optional[OrganizationOut] = None
    country: Optional[CountryOut] = None
    preferences: Optional[UserPreferenceOut] = None
    created_at: datetime

    class Config:
        from_attributes = True


class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    phone: Optional[str] = None
    country_id: Optional[int] = None
    language: Optional[str] = None
    fcm_token: Optional[str] = None
