"""
Modèle Utilisateur.

Le rôle ("user" ou "admin") sert de base à un contrôle d'accès simple.
Une architecture RBAC plus fine (rôles multiples, permissions) pourra être
ajoutée plus tard sans casser ce modèle.
"""
from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String(150), nullable=False)
    email = Column(String(150), unique=True, nullable=False, index=True)
    phone = Column(String(30), nullable=True)
    password_hash = Column(String(255), nullable=False)

    organization_id = Column(Integer, ForeignKey("organizations.id"), nullable=True)
    country_id = Column(Integer, ForeignKey("countries.id"), nullable=True)

    role = Column(String(20), nullable=False, default="user")  # "user" | "admin"
    language = Column(String(5), nullable=False, default="fr")
    is_active = Column(Boolean, nullable=False, default=True)
    onboarding_completed = Column(Boolean, nullable=False, default=False)

    fcm_token = Column(String(255), nullable=True)  # jeton Firebase Cloud Messaging pour push

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    organization = relationship("Organization", back_populates="users")
    country = relationship("Country")
    preferences = relationship("UserPreference", back_populates="user", uselist=False, cascade="all, delete-orphan")
    favorites = relationship("Favorite", back_populates="user", cascade="all, delete-orphan")
    notifications = relationship("Notification", back_populates="user", cascade="all, delete-orphan")
    activity_logs = relationship("ActivityLog", back_populates="user", cascade="all, delete-orphan")

    def __repr__(self) -> str:
        return f"<User {self.email}>"
