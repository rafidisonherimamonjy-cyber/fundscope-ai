"""
Abstraction du canal d'envoi de notifications push, sur le même principe
que le service IA (pattern Strategy) : le reste de l'application dépend
uniquement de `PushClient`, jamais directement du SDK Firebase.

- `MockPushClient` : journalise l'envoi (utile en dev/démo, aucune
  dépendance externe requise).
- `FCMPushClient`  : envoie réellement la notification via Firebase Cloud
  Messaging (nécessite `firebase-admin` et un fichier de credentials).
"""
import logging
from abc import ABC, abstractmethod
from functools import lru_cache
from typing import Optional

from app.core.config import settings

logger = logging.getLogger(__name__)


class PushClient(ABC):
    @abstractmethod
    def send(self, token: str, title: str, body: str, data: Optional[dict] = None) -> bool:
        """Envoie une notification push à un jeton d'appareil. Retourne True si envoyé/simulé avec succès."""
        raise NotImplementedError


class MockPushClient(PushClient):
    """Ne fait aucun appel réseau : journalise simplement l'envoi. Utilisé pour la démo."""

    def send(self, token: str, title: str, body: str, data: Optional[dict] = None) -> bool:
        logger.info("[PUSH-MOCK] -> token=%s | %s: %s", token, title, body)
        return True


class FCMPushClient(PushClient):
    """Envoi réel via Firebase Admin SDK."""

    def __init__(self):
        try:
            import firebase_admin
            from firebase_admin import credentials
        except ImportError as exc:
            raise RuntimeError(
                "Le package 'firebase-admin' n'est pas installé. "
                "Exécutez `pip install firebase-admin` ou utilisez NOTIFICATION_PROVIDER=mock."
            ) from exc

        if not settings.FCM_CREDENTIALS_FILE:
            raise RuntimeError("FCM_CREDENTIALS_FILE manquant : impossible d'utiliser NOTIFICATION_PROVIDER=fcm.")

        if not firebase_admin._apps:
            cred = credentials.Certificate(settings.FCM_CREDENTIALS_FILE)
            firebase_admin.initialize_app(cred)
        self._firebase_admin = firebase_admin

    def send(self, token: str, title: str, body: str, data: Optional[dict] = None) -> bool:
        from firebase_admin import messaging

        message = messaging.Message(
            token=token,
            notification=messaging.Notification(title=title, body=body),
            data={k: str(v) for k, v in (data or {}).items()},
        )
        try:
            messaging.send(message)
            return True
        except Exception:  # noqa: BLE001
            logger.exception("Échec de l'envoi FCM pour le token %s", token)
            return False


@lru_cache
def get_push_client() -> PushClient:
    if settings.NOTIFICATION_PROVIDER == "fcm":
        try:
            return FCMPushClient()
        except Exception:  # noqa: BLE001
            logger.exception("Impossible d'initialiser FCM, repli sur MockPushClient.")
            return MockPushClient()
    return MockPushClient()
