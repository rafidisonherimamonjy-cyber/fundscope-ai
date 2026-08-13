"""
Cœur métier de FundScope AI : les bailleurs de fonds (FundingSource) et les
appels à projets / opportunités de financement (FundingCall).

FundingCall centralise à la fois les données "brutes" (texte du TDR fourni
par l'admin) et les données enrichies par l'IA (résumé exécutif, éléments
extraits, score de difficulté), ce qui évite de recalculer l'analyse à
chaque affichage.
"""
from sqlalchemy import Column, DateTime, Float, ForeignKey, Integer, JSON, String, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class FundingSource(Base):
    """Un bailleur de fonds : fondation, agence de développement, banque, concours..."""

    __tablename__ = "funding_sources"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(200), nullable=False)
    logo_url = Column(String(500), nullable=True)
    website = Column(String(300), nullable=True)
    description = Column(Text, nullable=True)
    country_id = Column(Integer, ForeignKey("countries.id"), nullable=True)

    country = relationship("Country")
    calls = relationship("FundingCall", back_populates="funding_source")

    def __repr__(self) -> str:
        return f"<FundingSource {self.name}>"


class FundingCall(Base):
    """Un appel à projets / appel à candidatures / concours de financement."""

    __tablename__ = "funding_calls"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(300), nullable=False, index=True)

    funding_source_id = Column(Integer, ForeignKey("funding_sources.id"), nullable=False)
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=False)
    country_id = Column(Integer, ForeignKey("countries.id"), nullable=True)  # NULL = international / multi-pays

    # Type de financement : grant (subvention), loan (prêt), equity (investissement),
    # prize (concours/prix), technical_assistance (assistance technique)
    funding_type = Column(String(30), nullable=False, default="grant")

    amount_min = Column(Integer, nullable=True)
    amount_max = Column(Integer, nullable=True)
    currency = Column(String(10), nullable=False, default="USD")

    duration_months = Column(Integer, nullable=True)
    deadline = Column(DateTime(timezone=True), nullable=False, index=True)

    # Contenu brut (saisi par l'admin, potentiellement collé depuis un TDR/PDF)
    raw_text = Column(Text, nullable=True)
    source_url = Column(String(500), nullable=True)

    # Champs structurés (saisis manuellement OU extraits automatiquement par l'IA)
    objective = Column(Text, nullable=True)
    eligibility = Column(Text, nullable=True)
    documents_required = Column(JSON, nullable=False, default=list)  # liste de chaînes

    # Champs générés par le service IA (voir app/services/ai)
    ai_summary = Column(Text, nullable=True)           # résumé exécutif
    ai_difficulty = Column(String(20), nullable=True)  # "facile" | "moyen" | "difficile"
    ai_processed_at = Column(DateTime(timezone=True), nullable=True)

    status = Column(String(20), nullable=False, default="published")  # draft | published | closed
    view_count = Column(Integer, nullable=False, default=0)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    funding_source = relationship("FundingSource", back_populates="calls")
    category = relationship("Category")
    country = relationship("Country")
    favorited_by = relationship("Favorite", back_populates="funding_call", cascade="all, delete-orphan")

    def __repr__(self) -> str:
        return f"<FundingCall {self.title[:40]!r}>"
