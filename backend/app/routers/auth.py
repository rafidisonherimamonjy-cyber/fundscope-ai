"""Endpoints d'authentification : inscription, connexion, rafraîchissement de token."""
import jwt
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import create_access_token, create_refresh_token, decode_token, hash_password, verify_password
from app.models.activity import ActivityLog
from app.models.organization import Organization
from app.models.preference import UserPreference
from app.models.user import User
from app.schemas.auth import ForgotPasswordRequest, LoginRequest, RefreshTokenRequest, RegisterRequest, TokenResponse
from app.schemas.user import UserOut

router = APIRouter(prefix="/auth", tags=["Authentification"])


@router.post("/register", response_model=UserOut, status_code=status.HTTP_201_CREATED)
def register(payload: RegisterRequest, db: Session = Depends(get_db)):
    """Crée un compte utilisateur ainsi que son organisation."""
    existing = db.query(User).filter(User.email == payload.email).first()
    if existing:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Un compte existe déjà avec cet email")

    organization = Organization(
        name=payload.organization_name,
        org_type=payload.org_type,
        country_id=payload.country_id,
        sector_id=payload.sector_id,
    )
    db.add(organization)
    db.flush()  # récupère organization.id sans committer

    user = User(
        full_name=payload.full_name,
        email=payload.email,
        phone=payload.phone,
        password_hash=hash_password(payload.password),
        organization_id=organization.id,
        country_id=payload.country_id,
        role="user",
    )
    db.add(user)
    db.flush()

    # Préférences vides créées par défaut ; complétées lors de l'onboarding
    db.add(UserPreference(user_id=user.id, sector_ids=[], country_ids=[], funding_types=[]))
    db.add(ActivityLog(user_id=user.id, action="register", details=f"Inscription de {user.email}"))

    db.commit()
    db.refresh(user)
    return user


@router.post("/login", response_model=TokenResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    """Authentifie un utilisateur et retourne une paire de tokens JWT (access + refresh)."""
    user = db.query(User).filter(User.email == payload.email).first()
    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Email ou mot de passe incorrect")
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Compte désactivé")

    db.add(ActivityLog(user_id=user.id, action="login"))
    db.commit()

    return TokenResponse(
        access_token=create_access_token(user.id, role=user.role),
        refresh_token=create_refresh_token(user.id),
    )


@router.post("/refresh", response_model=TokenResponse)
def refresh_token(payload: RefreshTokenRequest, db: Session = Depends(get_db)):
    """Émet un nouveau couple de tokens à partir d'un refresh token valide."""
    try:
        data = decode_token(payload.refresh_token)
        if data.get("type") != "refresh":
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token invalide")
        user_id = int(data["sub"])
    except (jwt.PyJWTError, KeyError, ValueError):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Refresh token invalide ou expiré")

    user = db.query(User).filter(User.id == user_id).first()
    if not user or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Utilisateur introuvable ou inactif")

    return TokenResponse(
        access_token=create_access_token(user.id, role=user.role),
        refresh_token=create_refresh_token(user.id),
    )


@router.post("/forgot-password", status_code=status.HTTP_202_ACCEPTED)
def forgot_password(payload: ForgotPasswordRequest, db: Session = Depends(get_db)):
    """
    Déclenche la procédure de réinitialisation de mot de passe.
    Pour le MVP, cet endpoint simule l'envoi d'email (journalisé côté serveur)
    plutôt que d'intégrer un vrai fournisseur SMTP — à brancher en production.
    """
    user = db.query(User).filter(User.email == payload.email).first()
    # Toujours répondre 202, même si l'email n'existe pas, pour ne pas divulguer
    # l'existence d'un compte (bonne pratique de sécurité).
    if user:
        db.add(ActivityLog(user_id=user.id, action="forgot_password_requested"))
        db.commit()
    return {"message": "Si un compte existe avec cet email, des instructions ont été envoyées."}
