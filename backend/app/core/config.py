"""
Configuration centralisée de l'application FundScope AI.

Toutes les valeurs sensibles ou dépendantes de l'environnement (base de
données, clés API, secrets JWT...) sont lues depuis des variables
d'environnement (fichier .env en local). Cela permet de déployer la même
base de code sur différents environnements (dev, staging, production)
sans modifier le code source.
"""
from functools import lru_cache
from typing import List

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # --- Général ---
    APP_NAME: str = "FundScope AI"
    APP_ENV: str = "development"
    API_V1_PREFIX: str = "/api/v1"
    DEBUG: bool = True

    # --- Sécurité / JWT ---
    SECRET_KEY: str = "CHANGE_ME_IN_PRODUCTION_super_secret_key"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 24h
    REFRESH_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 30  # 30 jours

    # --- Base de données ---
    # En production, utiliser une URL PostgreSQL, ex:
    # postgresql+psycopg2://user:password@localhost:5432/fundscope
    # Par défaut, SQLite est utilisé pour permettre de lancer le prototype
    # immédiatement, sans installer de serveur PostgreSQL.
    DATABASE_URL: str = "sqlite:///./fundscope.db"

    # --- CORS ---
    CORS_ORIGINS: List[str] = ["*"]

    # --- IA ---
    # "mock"   -> moteur local déterministe (aucune clé API requise, idéal pour la démo)
    # "openai" -> utilise l'API OpenAI (nécessite OPENAI_API_KEY)
    AI_PROVIDER: str = "mock"
    OPENAI_API_KEY: str = ""
    OPENAI_MODEL: str = "gpt-4o-mini"

    # --- Notifications push (Firebase Cloud Messaging) ---
    # "mock" -> les notifications sont journalisées en base sans envoi réel (démo)
    # "fcm"  -> envoi réel via Firebase Admin SDK (nécessite FCM_CREDENTIALS_FILE)
    NOTIFICATION_PROVIDER: str = "mock"
    FCM_CREDENTIALS_FILE: str = ""

    # --- Admin (compte créé automatiquement lors du seed) ---
    ADMIN_EMAIL: str = "admin@fundscope.ai"
    ADMIN_PASSWORD: str = "Admin123!"

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")


@lru_cache
def get_settings() -> Settings:
    """Retourne une instance unique (singleton) des settings, mise en cache."""
    return Settings()


settings = get_settings()
