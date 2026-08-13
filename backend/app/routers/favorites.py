"""Endpoints de gestion des favoris (enregistrer / retirer / lister)."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.activity import ActivityLog, Favorite
from app.models.funding import FundingCall
from app.models.user import User
from app.schemas.funding import FundingCallCardOut
from app.services.recommendation import compute_relevance_score

router = APIRouter(prefix="/favorites", tags=["Favoris"])


@router.get("", response_model=list[FundingCallCardOut])
def list_favorites(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Retourne la liste des appels à projets enregistrés en favoris par l'utilisateur."""
    favorites = (
        db.query(FundingCall)
        .join(Favorite, Favorite.funding_call_id == FundingCall.id)
        .filter(Favorite.user_id == current_user.id)
        .order_by(Favorite.created_at.desc())
        .all()
    )
    result = []
    for call in favorites:
        card = FundingCallCardOut.model_validate(call)
        card.relevance_score = compute_relevance_score(current_user.preferences, call)
        card.is_favorite = True
        result.append(card)
    return result


@router.post("/{call_id}", status_code=status.HTTP_201_CREATED)
def add_favorite(call_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Ajoute un appel à projets aux favoris de l'utilisateur."""
    call = db.query(FundingCall).filter(FundingCall.id == call_id).first()
    if not call:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Opportunité introuvable")

    existing = (
        db.query(Favorite).filter(Favorite.user_id == current_user.id, Favorite.funding_call_id == call_id).first()
    )
    if existing:
        return {"message": "Déjà en favoris"}

    db.add(Favorite(user_id=current_user.id, funding_call_id=call_id))
    db.add(ActivityLog(user_id=current_user.id, action="add_favorite", details=f"call_id={call_id}"))
    db.commit()
    return {"message": "Ajouté aux favoris"}


@router.delete("/{call_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_favorite(call_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Retire un appel à projets des favoris de l'utilisateur."""
    favorite = (
        db.query(Favorite).filter(Favorite.user_id == current_user.id, Favorite.funding_call_id == call_id).first()
    )
    if favorite:
        db.delete(favorite)
        db.add(ActivityLog(user_id=current_user.id, action="remove_favorite", details=f"call_id={call_id}"))
        db.commit()
    return None
