"""
Fonctions de sécurité : hachage des mots de passe et gestion des JSON Web Tokens (JWT).

Le hachage utilise bcrypt (via passlib). Les tokens sont signés avec PyJWT.
Deux types de tokens sont émis : "access" (courte durée) et "refresh" (longue durée),
ce qui permettra plus tard d'implémenter un renouvellement de session sans
redemander le mot de passe.
"""
from datetime import datetime, timedelta, timezone
from typing import Any, Optional

import jwt
from passlib.context import CryptContext

from app.core.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    """Retourne le hash bcrypt d'un mot de passe en clair."""
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Vérifie qu'un mot de passe en clair correspond à son hash."""
    return pwd_context.verify(plain_password, hashed_password)


def _create_token(subject: str, expires_delta: timedelta, token_type: str, extra_claims: Optional[dict] = None) -> str:
    now = datetime.now(timezone.utc)
    payload: dict[str, Any] = {
        "sub": subject,
        "type": token_type,
        "iat": now,
        "exp": now + expires_delta,
    }
    if extra_claims:
        payload.update(extra_claims)
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def create_access_token(user_id: int, role: str = "user") -> str:
    return _create_token(
        subject=str(user_id),
        expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
        token_type="access",
        extra_claims={"role": role},
    )


def create_refresh_token(user_id: int) -> str:
    return _create_token(
        subject=str(user_id),
        expires_delta=timedelta(minutes=settings.REFRESH_TOKEN_EXPIRE_MINUTES),
        token_type="refresh",
    )


def decode_token(token: str) -> dict:
    """Décode et valide un token JWT. Lève jwt.PyJWTError si invalide/expiré."""
    return jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
