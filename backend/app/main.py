"""
Point d'entrée de l'application FastAPI FundScope AI.

Lancer en local :
    uvicorn app.main:app --reload

Documentation interactive générée automatiquement :
    http://localhost:8000/docs   (Swagger UI)
    http://localhost:8000/redoc  (ReDoc)

Tableau de bord admin :
    http://localhost:8000/admin
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.core.config import settings
from app.core.database import Base, engine
import app.models  # noqa: F401 - assure l'enregistrement de tous les modèles avant create_all

from app.routers import admin, admin_dashboard, auth, favorites, notifications, opportunities, reference, users

app = FastAPI(
    title=settings.APP_NAME,
    description="API du meilleur assistant intelligent de recherche de financements et d'appels à projets.",
    version="0.1.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def on_startup():
    """Crée les tables si elles n'existent pas encore (suffisant pour le MVP).

    En production, préférer un outil de migration (ex: Alembic) pour faire
    évoluer le schéma sans perte de données.
    """
    Base.metadata.create_all(bind=engine)

    # Auto-seed si la base est vide (ex: premier démarrage sur un nouvel
    # environnement type Render, où l'accès Shell manuel n'est pas toujours
    # disponible). `seed()` est idempotent : il ne fait rien si des pays
    # existent déjà, donc c'est sans danger de l'appeler à chaque démarrage.
    from app.seed.seed_data import seed

    seed()


# --- Fichiers statiques du tableau de bord admin ---------------------------
app.mount("/admin/static", StaticFiles(directory="app/static/admin"), name="admin-static")

# --- Routers métier, préfixés par la version de l'API ------------------------
app.include_router(auth.router, prefix=settings.API_V1_PREFIX)
app.include_router(users.router, prefix=settings.API_V1_PREFIX)
app.include_router(reference.router, prefix=settings.API_V1_PREFIX)
app.include_router(opportunities.router, prefix=settings.API_V1_PREFIX)
app.include_router(favorites.router, prefix=settings.API_V1_PREFIX)
app.include_router(notifications.router, prefix=settings.API_V1_PREFIX)
app.include_router(admin.router, prefix=settings.API_V1_PREFIX)

# --- Tableau de bord admin (page HTML, hors préfixe /api) --------------------
app.include_router(admin_dashboard.router)


@app.get("/", tags=["Santé"])
def root():
    """Endpoint racine, utile pour vérifier rapidement que l'API tourne."""
    return {
        "app": settings.APP_NAME,
        "status": "running",
        "docs": "/docs",
        "admin_dashboard": "/admin",
    }


@app.get("/health", tags=["Santé"])
def health_check():
    return {"status": "ok"}
