"""Schémas Pydantic divers : favoris, notifications, statistiques admin."""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class NotificationOut(BaseModel):
    id: int
    title: str
    body: str
    is_read: bool
    funding_call_id: Optional[int] = None
    created_at: datetime

    class Config:
        from_attributes = True


class AdminStatsOut(BaseModel):
    total_users: int
    total_funding_calls: int
    total_funding_sources: int
    total_favorites: int
    calls_expiring_soon: int  # date limite dans les 7 prochains jours
    users_by_country: dict
    calls_by_sector: dict
