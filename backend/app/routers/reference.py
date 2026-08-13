"""Endpoints publics des données de référence (pays, secteurs) utilisés par les formulaires du frontend."""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.reference import Category, Country
from app.schemas.user import CategoryOut, CountryOut

router = APIRouter(tags=["Référentiels"])


@router.get("/countries", response_model=list[CountryOut])
def list_countries(db: Session = Depends(get_db)):
    return db.query(Country).order_by(Country.name).all()


@router.get("/categories", response_model=list[CategoryOut])
def list_categories(db: Session = Depends(get_db)):
    return db.query(Category).order_by(Category.name).all()
