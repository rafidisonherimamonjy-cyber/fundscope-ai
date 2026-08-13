"""
Initialisation de la connexion base de données avec SQLAlchemy.

Fournit :
- `engine`      : le moteur de connexion (PostgreSQL en production, SQLite en dev)
- `SessionLocal`: une factory de sessions
- `Base`        : la classe de base déclarative dont héritent tous les modèles
- `get_db`      : une dépendance FastAPI qui fournit une session par requête
"""
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

from app.core.config import settings

# `connect_args` n'est nécessaire que pour SQLite (permet le multi-threading avec FastAPI)
connect_args = {"check_same_thread": False} if settings.DATABASE_URL.startswith("sqlite") else {}

engine = create_engine(settings.DATABASE_URL, connect_args=connect_args)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db():
    """Dépendance FastAPI : ouvre une session DB et la ferme à la fin de la requête."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
