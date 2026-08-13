"""
Sert la page HTML du tableau de bord administrateur (Single Page App légère,
sans framework, en HTML/CSS/JS vanilla — voir app/static/admin/).

Cette route ne nécessite PAS d'authentification côté serveur : la page se
charge, puis le JavaScript demande à l'utilisateur de se connecter via
POST /api/v1/auth/login (le compte doit avoir le rôle "admin"), stocke le
token JWT reçu, et l'utilise pour appeler les endpoints protégés
/api/v1/admin/*. C'est la page elle-même qui est publique, pas les données.
"""
from pathlib import Path

from fastapi import APIRouter
from fastapi.responses import FileResponse

router = APIRouter(tags=["Dashboard Admin"])

_STATIC_DIR = Path(__file__).resolve().parent.parent / "static" / "admin"


@router.get("/admin", include_in_schema=False)
def admin_dashboard_page():
    return FileResponse(_STATIC_DIR / "index.html")
