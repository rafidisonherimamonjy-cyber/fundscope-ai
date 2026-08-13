"""
Factory qui fournit une instance de `AIProvider` selon la configuration
(`settings.AI_PROVIDER`). C'est le SEUL endroit de l'application qui décide
quel fournisseur concret utiliser — tout le reste du code appelle
`get_ai_provider()` et manipule uniquement l'interface abstraite.

Pour ajouter un nouveau fournisseur (Mistral, Anthropic, un modèle local...) :
  1. Créer une classe qui hérite de AIProvider dans ce même dossier.
  2. L'enregistrer dans le dict `_PROVIDERS` ci-dessous.
  3. Ajouter la valeur correspondante à AI_PROVIDER dans le fichier .env.
Aucun autre fichier de l'application n'a besoin d'être modifié.
"""
from functools import lru_cache

from app.core.config import settings
from app.services.ai.base import AIProvider
from app.services.ai.mock_provider import MockAIProvider


def _build_openai_provider() -> AIProvider:
    from app.services.ai.openai_provider import OpenAIProvider  # import paresseux

    return OpenAIProvider()


_PROVIDERS = {
    "mock": lambda: MockAIProvider(),
    "openai": _build_openai_provider,
}


@lru_cache
def get_ai_provider() -> AIProvider:
    """Retourne (et met en cache) l'instance du fournisseur IA actif."""
    builder = _PROVIDERS.get(settings.AI_PROVIDER, _PROVIDERS["mock"])
    try:
        return builder()
    except Exception:  # noqa: BLE001 - si le fournisseur configuré échoue à s'initialiser, on ne bloque pas l'app
        import logging

        logging.getLogger(__name__).exception(
            "Impossible d'initialiser le fournisseur IA '%s', repli sur 'mock'.", settings.AI_PROVIDER
        )
        return MockAIProvider()
