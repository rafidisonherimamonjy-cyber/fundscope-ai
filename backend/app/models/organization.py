"""
Organisation de l'utilisateur : entreprise, startup, ONG, association, etc.
Un utilisateur peut être rattaché à une organisation pour affiner le
scoring de recommandation (type de structure éligible aux financements).
"""
from sqlalchemy import Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class Organization(Base):
    __tablename__ = "organizations"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(200), nullable=False)
    # Type de structure : startup, pme, ong, association, cooperative, structure_appui, consultant, autre
    org_type = Column(String(50), nullable=False, default="startup")
    country_id = Column(Integer, ForeignKey("countries.id"), nullable=True)
    sector_id = Column(Integer, ForeignKey("categories.id"), nullable=True)
    website = Column(String(300), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    country = relationship("Country")
    sector = relationship("Category")
    users = relationship("User", back_populates="organization")

    def __repr__(self) -> str:
        return f"<Organization {self.name}>"
