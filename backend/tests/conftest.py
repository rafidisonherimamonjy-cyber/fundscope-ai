"""
Fixtures pytest partagées : base de données SQLite en mémoire (isolée par
test), client de test FastAPI avec la dépendance get_db substituée.
"""
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.database import Base, get_db
from app.main import app
from app import models  # noqa: F401 - enregistre tous les modèles


@pytest.fixture()
def db_session():
    # StaticPool est indispensable ici : TestClient exécute les endpoints (sync)
    # dans un thread différent de celui du test. Sans lui, chaque thread récupère
    # une connexion SQLite ":memory:" distincte, donc une base vide sans les tables
    # créées ci-dessous (erreur "no such table").
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    Base.metadata.create_all(bind=engine)
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()


@pytest.fixture()
def client(db_session):
    def _override_get_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = _override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


@pytest.fixture()
def seeded_country(db_session):
    from app.models.reference import Country

    country = Country(code="SN", name="Sénégal", region="Afrique de l'Ouest")
    db_session.add(country)
    db_session.commit()
    db_session.refresh(country)
    return country
