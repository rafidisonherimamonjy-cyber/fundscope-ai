"""
Endpoints des opportunités de financement (appels à projets) : liste
personnalisée avec score de pertinence, recherche/filtre, détail enrichi
par l'IA.
"""
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.activity import ActivityLog, Favorite
from app.models.funding import FundingCall
from app.models.user import User
from app.schemas.funding import FundingCallCardOut, FundingCallDetailOut
from app.services.recommendation import compute_relevance_score

router = APIRouter(prefix="/opportunities", tags=["Opportunités"])


def _favorite_ids(db: Session, user_id: int) -> set:
    rows = db.query(Favorite.funding_call_id).filter(Favorite.user_id == user_id).all()
    return {r[0] for r in rows}


def _to_card(call: FundingCall, score: float, is_favorite: bool) -> FundingCallCardOut:
    card = FundingCallCardOut.model_validate(call)
    card.relevance_score = score
    card.is_favorite = is_favorite
    return card


@router.get("", response_model=list[FundingCallCardOut])
def list_opportunities(
    search: Optional[str] = Query(None, description="Recherche plein texte sur le titre"),
    sector_id: Optional[int] = None,
    country_id: Optional[int] = None,
    funding_type: Optional[str] = None,
    deadline_within_days: Optional[int] = Query(None, description="Filtrer les appels dont la date limite approche"),
    only_favorites: bool = False,
    sort: str = Query("relevance", pattern="^(relevance|deadline|newest)$"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Liste les opportunités publiées, avec :
    - recherche par mot-clé,
    - filtres (secteur, pays, type de financement, échéance proche, favoris),
    - tri par pertinence (par défaut, basé sur les préférences utilisateur), par
      date limite ou par nouveauté,
    - pagination.
    """
    query = db.query(FundingCall).filter(FundingCall.status == "published")

    if search:
        query = query.filter(or_(FundingCall.title.ilike(f"%{search}%"), FundingCall.objective.ilike(f"%{search}%")))
    if sector_id:
        query = query.filter(FundingCall.category_id == sector_id)
    if country_id:
        query = query.filter(FundingCall.country_id == country_id)
    if funding_type:
        query = query.filter(FundingCall.funding_type == funding_type)
    if deadline_within_days is not None:
        limit_date = datetime.now(timezone.utc) + timedelta(days=deadline_within_days)
        query = query.filter(FundingCall.deadline <= limit_date)

    favorite_ids = _favorite_ids(db, current_user.id)
    if only_favorites:
        if not favorite_ids:
            return []
        query = query.filter(FundingCall.id.in_(favorite_ids))

    if sort == "deadline":
        query = query.order_by(FundingCall.deadline.asc())
    elif sort == "newest":
        query = query.order_by(FundingCall.created_at.desc())

    calls = query.all()

    scored = [(call, compute_relevance_score(current_user.preferences, call)) for call in calls]
    if sort == "relevance":
        scored.sort(key=lambda pair: (-pair[1], pair[0].deadline))

    start = (page - 1) * page_size
    page_items = scored[start : start + page_size]

    return [_to_card(call, score, call.id in favorite_ids) for call, score in page_items]


@router.get("/{call_id}", response_model=FundingCallDetailOut)
def get_opportunity(call_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Retourne le détail complet d'un appel à projets, y compris le résumé IA."""
    call = db.query(FundingCall).filter(FundingCall.id == call_id).first()
    if not call:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Opportunité introuvable")

    call.view_count = (call.view_count or 0) + 1
    db.add(ActivityLog(user_id=current_user.id, action="view_call", details=f"call_id={call.id}"))
    db.commit()
    db.refresh(call)

    favorite_ids = _favorite_ids(db, current_user.id)
    score = compute_relevance_score(current_user.preferences, call)

    detail = FundingCallDetailOut.model_validate(call)
    detail.relevance_score = score
    detail.is_favorite = call.id in favorite_ids
    return detail
