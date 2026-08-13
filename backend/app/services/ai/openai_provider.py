"""
Fournisseur IA basé sur l'API OpenAI.

Utilisé quand AI_PROVIDER=openai dans la configuration. Le SDK `openai`
est importé de façon paresseuse (dans __init__) pour que le reste de
l'application puisse tourner même si le package n'est pas installé
(cas où l'on utilise uniquement le fournisseur "mock").

Le prompt demande explicitement une réponse JSON stricte afin de pouvoir
la parser de façon fiable et remplir un `AIAnalysisResult`.
"""
import json
import logging

from app.core.config import settings
from app.services.ai.base import AIAnalysisResult, AIProvider
from app.services.ai.mock_provider import MockAIProvider

logger = logging.getLogger(__name__)

_SYSTEM_PROMPT = (
    "Tu es un expert en ingénierie de projets et en recherche de financements pour "
    "entrepreneurs, startups, PME, ONG et associations en Afrique et dans le monde. "
    "Tu analyses des termes de référence (TDR) d'appels à projets et tu réponds "
    "UNIQUEMENT en JSON valide, sans texte autour, avec exactement ces clés : "
    '{"executive_summary": str, "objective": str, "eligibility": str, '
    '"budget_hint": str|null, "deadline_hint": str|null, '
    '"documents_required": [str], "suggested_sector": str|null, '
    '"difficulty": "facile"|"moyen"|"difficile"}'
)


class OpenAIProvider(AIProvider):
    """Implémentation de AIProvider s'appuyant sur l'API OpenAI (Chat Completions)."""

    def __init__(self):
        try:
            from openai import OpenAI  # import paresseux : évite une dépendance dure
        except ImportError as exc:
            raise RuntimeError(
                "Le package 'openai' n'est pas installé. Exécutez `pip install openai` "
                "ou utilisez AI_PROVIDER=mock."
            ) from exc

        if not settings.OPENAI_API_KEY:
            raise RuntimeError("OPENAI_API_KEY manquant : impossible d'utiliser AI_PROVIDER=openai.")

        self._client = OpenAI(api_key=settings.OPENAI_API_KEY)
        # Fallback local utilisé si l'appel réseau échoue, pour ne jamais casser la démo.
        self._fallback = MockAIProvider()

    def analyze_call(self, raw_text: str, title: str = "") -> AIAnalysisResult:
        user_prompt = f"Titre de l'appel à projets : {title}\n\nTexte du TDR :\n{raw_text[:6000]}"
        try:
            response = self._client.chat.completions.create(
                model=settings.OPENAI_MODEL,
                messages=[
                    {"role": "system", "content": _SYSTEM_PROMPT},
                    {"role": "user", "content": user_prompt},
                ],
                response_format={"type": "json_object"},
                temperature=0.3,
            )
            data = json.loads(response.choices[0].message.content)
            return AIAnalysisResult(
                executive_summary=data.get("executive_summary", ""),
                objective=data.get("objective", ""),
                eligibility=data.get("eligibility", ""),
                budget_hint=data.get("budget_hint"),
                deadline_hint=data.get("deadline_hint"),
                documents_required=data.get("documents_required") or [],
                suggested_sector=data.get("suggested_sector"),
                difficulty=data.get("difficulty", "moyen"),
            )
        except Exception:  # noqa: BLE001 - on ne veut jamais planter la création d'un appel
            logger.exception("Échec de l'appel OpenAI, repli sur le fournisseur local (mock).")
            return self._fallback.analyze_call(raw_text, title)

    def generate_executive_summary(self, raw_text: str, title: str = "") -> str:
        try:
            response = self._client.chat.completions.create(
                model=settings.OPENAI_MODEL,
                messages=[
                    {"role": "system", "content": "Résume ce TDR en un résumé exécutif de 3 à 5 phrases, en français."},
                    {"role": "user", "content": f"{title}\n\n{raw_text[:6000]}"},
                ],
                temperature=0.3,
            )
            return response.choices[0].message.content.strip()
        except Exception:  # noqa: BLE001
            logger.exception("Échec de l'appel OpenAI, repli sur le fournisseur local (mock).")
            return self._fallback.generate_executive_summary(raw_text, title)
