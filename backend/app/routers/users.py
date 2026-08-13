"""Endpoints liés au profil de l'utilisateur connecté et à ses préférences."""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.preference import UserPreference
from app.models.user import User
from app.schemas.user import UserOut, UserPreferenceIn, UserPreferenceOut, UserUpdate

router = APIRouter(prefix="/users", tags=["Utilisateurs"])


@router.get("/me", response_model=UserOut)
def get_me(current_user: User = Depends(get_current_user)):
    """Retourne le profil complet de l'utilisateur connecté."""
    return current_user


@router.put("/me", response_model=UserOut)
def update_me(payload: UserUpdate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Met à jour les informations modifiables du profil (écran Profil)."""
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(current_user, field, value)
    db.commit()
    db.refresh(current_user)
    return current_user


@router.put("/me/preferences", response_model=UserPreferenceOut)
def update_preferences(
    payload: UserPreferenceIn,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Enregistre les préférences de recherche (secteurs, pays, type de
    financement, montant, langue). Utilisé à la fois par l'écran
    Onboarding (première fois) et par l'écran Profil (modification).
    """
    preference = db.query(UserPreference).filter(UserPreference.user_id == current_user.id).first()
    if preference is None:
        preference = UserPreference(user_id=current_user.id)
        db.add(preference)

    for field, value in payload.model_dump().items():
        setattr(preference, field, value)

    current_user.onboarding_completed = True
    db.commit()
    db.refresh(preference)
    return preference
