"""
Préférences utilisateur, renseignées lors de l'onboarding et modifiables
depuis le profil. Elles alimentent directement le moteur de recommandation
(app/services/recommendation.py).

Les listes (secteurs, pays, types de financement) sont stockées en JSON :
compatible SQLite (dev) et PostgreSQL (prod) sans changement de code.
"""
from sqlalchemy import Column, ForeignKey, Integer, JSON, String
from sqlalchemy.orm import relationship

from app.core.database import Base


class UserPreference(Base):
    __tablename__ = "user_preferences"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)

    sector_ids = Column(JSON, nullable=False, default=list)       # ex: [1, 3]
    country_ids = Column(JSON, nullable=False, default=list)      # ex: [1, 2, 5]
    funding_types = Column(JSON, nullable=False, default=list)    # ex: ["grant", "prize"]
    amount_min = Column(Integer, nullable=True)
    amount_max = Column(Integer, nullable=True)
    language = Column(String(5), nullable=False, default="fr")

    user = relationship("User", back_populates="preferences")

    def __repr__(self) -> str:
        return f"<UserPreference user_id={self.user_id}>"
