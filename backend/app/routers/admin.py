"""
Endpoints réservés à l'administration : CRUD des appels à projets et des
bailleurs, consultation des utilisateurs, statistiques globales.

Ces endpoints alimentent le tableau de bord web minimal (voir
app/templates/admin/ et GET /admin/dashboard) mais peuvent aussi être
consommés par n'importe quel autre client (ex: un futur back-office React).
"""
from collections import Counter
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_admin
from app.models.funding import FundingCall, FundingSource
from app.models.activity import Favorite
from app.models.user import User
from app.schemas.funding import FundingCallCreate, FundingCallDetailOut, FundingCallUpdate, FundingSourceCreate, FundingSourceOut
from app.schemas.misc import AdminStatsOut
from app.schemas.user import UserOut
from app.services.ai.ai_service import get_ai_provider
from app.services.notification_service import notify_matching_users

router = APIRouter(prefix="/admin", tags=["Administration"], dependencies=[Depends(get_current_admin)])


# --- Bailleurs ------------------------------------------------------------


@router.get("/funding-sources", response_model=list[FundingSourceOut])
def list_funding_sources(db: Session = Depends(get_db)):
    return db.query(FundingSource).order_by(FundingSource.name).all()


@router.post("/funding-sources", response_model=FundingSourceOut, status_code=status.HTTP_201_CREATED)
def create_funding_source(payload: FundingSourceCreate, db: Session = Depends(get_db)):
    source = FundingSource(**payload.model_dump())
    db.add(source)
    db.commit()
    db.refresh(source)
    return source


# --- Appels à projets -------------------------------------------------------


@router.get("/opportunities", response_model=list[FundingCallDetailOut])
def admin_list_opportunities(db: Session = Depends(get_db)):
    calls = db.query(FundingCall).order_by(FundingCall.created_at.desc()).all()
    return [FundingCallDetailOut.model_validate(c) for c in calls]


@router.post("/opportunities", response_model=FundingCallDetailOut, status_code=status.HTTP_201_CREATED)
def create_opportunity(payload: FundingCallCreate, db: Session = Depends(get_db)):
    """
    Crée un nouvel appel à projets. Si `run_ai_analysis` est vrai et qu'un
    `raw_text` (TDR) est fourni, le service IA est appelé pour générer le
    résumé exécutif et pré-remplir les champs structurés manquants.
    Déclenche ensuite les notifications pour les utilisateurs concernés.
    """
    data = payload.model_dump(exclude={"run_ai_analysis"})
    call = FundingCall(**data)

    if payload.run_ai_analysis and payload.raw_text:
        analysis = get_ai_provider().analyze_call(payload.raw_text, title=payload.title)
        call.ai_summary = analysis.executive_summary
        call.ai_difficulty = analysis.difficulty
        call.ai_processed_at = datetime.now(timezone.utc)
        if not call.objective:
            call.objective = analysis.objective
        if not call.eligibility:
            call.eligibility = analysis.eligibility
        if not call.documents_required:
            call.documents_required = analysis.documents_required

    db.add(call)
    db.commit()
    db.refresh(call)

    notify_matching_users(db, call)
    return FundingCallDetailOut.model_validate(call)


@router.put("/opportunities/{call_id}", response_model=FundingCallDetailOut)
def update_opportunity(call_id: int, payload: FundingCallUpdate, db: Session = Depends(get_db)):
    call = db.query(FundingCall).filter(FundingCall.id == call_id).first()
    if not call:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Opportunité introuvable")

    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(call, field, value)

    db.commit()
    db.refresh(call)
    return FundingCallDetailOut.model_validate(call)


@router.post("/opportunities/{call_id}/analyze", response_model=FundingCallDetailOut)
def reanalyze_opportunity(call_id: int, db: Session = Depends(get_db)):
    """Relance l'analyse IA (résumé + extraction) sur un appel existant."""
    call = db.query(FundingCall).filter(FundingCall.id == call_id).first()
    if not call:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Opportunité introuvable")
    if not call.raw_text:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Aucun texte de TDR à analyser")

    analysis = get_ai_provider().analyze_call(call.raw_text, title=call.title)
    call.ai_summary = analysis.executive_summary
    call.ai_difficulty = analysis.difficulty
    call.ai_processed_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(call)
    return FundingCallDetailOut.model_validate(call)


@router.delete("/opportunities/{call_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_opportunity(call_id: int, db: Session = Depends(get_db)):
    call = db.query(FundingCall).filter(FundingCall.id == call_id).first()
    if call:
        db.delete(call)
        db.commit()
    return None


# --- Utilisateurs -----------------------------------------------------------


@router.get("/users", response_model=list[UserOut])
def admin_list_users(db: Session = Depends(get_db)):
    return db.query(User).order_by(User.created_at.desc()).all()


# --- Statistiques -------------------------------------------------------------


@router.get("/stats", response_model=AdminStatsOut)
def admin_stats(db: Session = Depends(get_db)):
    users = db.query(User).all()
    calls = db.query(FundingCall).all()
    soon = datetime.now(timezone.utc) + timedelta(days=7)

    users_by_country = Counter(u.country.name for u in users if u.country)
    calls_by_sector = Counter(c.category.name for c in calls if c.category)

    return AdminStatsOut(
        total_users=len(users),
        total_funding_calls=len(calls),
        total_funding_sources=db.query(FundingSource).count(),
        total_favorites=db.query(Favorite).count(),
        calls_expiring_soon=sum(1 for c in calls if c.deadline <= soon and c.status == "published"),
        users_by_country=dict(users_by_country),
        calls_by_sector=dict(calls_by_sector),
    )
