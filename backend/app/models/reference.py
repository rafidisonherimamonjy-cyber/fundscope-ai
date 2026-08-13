"""
Tables de référence : Pays et Secteurs (Catégories).

Ce sont des tables "de vocabulaire" réutilisées par plusieurs autres tables
(utilisateurs, organisations, appels à projets) afin de garder des données
cohérentes et faciles à filtrer / traduire plus tard.
"""
from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship

from app.core.database import Base


class Country(Base):
    __tablename__ = "countries"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String(2), unique=True, nullable=False, index=True)  # ISO 3166-1 alpha-2, ex: "SN"
    name = Column(String(100), unique=True, nullable=False)
    region = Column(String(100), nullable=True)  # ex: "Afrique de l'Ouest"

    def __repr__(self) -> str:
        return f"<Country {self.code} {self.name}>"


class Category(Base):
    """Secteur d'activité / domaine d'intervention (ex: Agriculture, Santé, Éducation...)."""

    __tablename__ = "categories"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, nullable=False)
    description = Column(String(500), nullable=True)
    icon = Column(String(50), nullable=True)  # nom d'icône Material pour l'UI

    def __repr__(self) -> str:
        return f"<Category {self.name}>"
