"""
Modèles d'activité utilisateur : Favoris, Notifications et Journal d'activité.
"""
from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class Favorite(Base):
    __tablename__ = "favorites"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    funding_call_id = Column(Integer, ForeignKey("funding_calls.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="favorites")
    funding_call = relationship("FundingCall", back_populates="favorited_by")

    def __repr__(self) -> str:
        return f"<Favorite user={self.user_id} call={self.funding_call_id}>"


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    funding_call_id = Column(Integer, ForeignKey("funding_calls.id"), nullable=True)

    title = Column(String(200), nullable=False)
    body = Column(String(500), nullable=False)
    is_read = Column(Boolean, nullable=False, default=False)
    is_sent = Column(Boolean, nullable=False, default=False)  # push FCM effectivement envoyé

    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="notifications")
    funding_call = relationship("FundingCall")

    def __repr__(self) -> str:
        return f"<Notification user={self.user_id} title={self.title!r}>"


class ActivityLog(Base):
    """Journal léger des actions utilisateur, utile pour l'analytics du dashboard admin."""

    __tablename__ = "activity_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    action = Column(String(100), nullable=False)  # ex: "login", "view_call", "add_favorite"
    details = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="activity_logs")

    def __repr__(self) -> str:
        return f"<ActivityLog {self.action} user={self.user_id}>"
