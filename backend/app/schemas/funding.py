"""Schémas Pydantic liés aux bailleurs et aux appels à projets."""
from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field

from app.schemas.user import CategoryOut, CountryOut


class FundingSourceOut(BaseModel):
    id: int
    name: str
    logo_url: Optional[str] = None
    website: Optional[str] = None
    description: Optional[str] = None

    class Config:
        from_attributes = True


class FundingSourceCreate(BaseModel):
    name: str
    logo_url: Optional[str] = None
    website: Optional[str] = None
    description: Optional[str] = None
    country_id: Optional[int] = None


class FundingCallCardOut(BaseModel):
    """Version allégée utilisée pour les listes (écran Accueil, Favoris)."""

    id: int
    title: str
    funding_source: FundingSourceOut
    category: CategoryOut
    country: Optional[CountryOut] = None
    funding_type: str
    amount_min: Optional[int] = None
    amount_max: Optional[int] = None
    currency: str
    deadline: datetime
    relevance_score: Optional[float] = None  # calculé dynamiquement, pas stocké
    is_favorite: Optional[bool] = None

    class Config:
        from_attributes = True


class FundingCallDetailOut(FundingCallCardOut):
    """Version complète utilisée pour l'écran de détail."""

    objective: Optional[str] = None
    eligibility: Optional[str] = None
    documents_required: List[str] = Field(default_factory=list)
    duration_months: Optional[int] = None
    source_url: Optional[str] = None
    ai_summary: Optional[str] = None
    ai_difficulty: Optional[str] = None
    status: str
    created_at: datetime


class FundingCallCreate(BaseModel):
    """Payload utilisé par le dashboard admin pour créer/modifier un appel à projets."""

    title: str
    funding_source_id: int
    category_id: int
    country_id: Optional[int] = None
    funding_type: str = "grant"
    amount_min: Optional[int] = None
    amount_max: Optional[int] = None
    currency: str = "USD"
    duration_months: Optional[int] = None
    deadline: datetime
    raw_text: Optional[str] = None
    source_url: Optional[str] = None
    objective: Optional[str] = None
    eligibility: Optional[str] = None
    documents_required: List[str] = Field(default_factory=list)
    status: str = "published"
    run_ai_analysis: bool = True  # si vrai, déclenche l'analyse IA à la création


class FundingCallUpdate(BaseModel):
    title: Optional[str] = None
    funding_source_id: Optional[int] = None
    category_id: Optional[int] = None
    country_id: Optional[int] = None
    funding_type: Optional[str] = None
    amount_min: Optional[int] = None
    amount_max: Optional[int] = None
    currency: Optional[str] = None
    duration_months: Optional[int] = None
    deadline: Optional[datetime] = None
    raw_text: Optional[str] = None
    source_url: Optional[str] = None
    objective: Optional[str] = None
    eligibility: Optional[str] = None
    documents_required: Optional[List[str]] = None
    status: Optional[str] = None
