"""
Fournisseur IA local ("mock"), sans dépendance externe ni clé API.

Il utilise des heuristiques simples (expressions régulières, mots-clés) pour
extraire des informations d'un texte de TDR et générer un résumé exécutif
lisible. Il ne remplace pas un vrai LLM en qualité, mais permet de faire
tourner et de démontrer TOUT le pipeline IA (extraction + résumé + score de
difficulté) sans configuration ni coût, ce qui est idéal pour :
  - le développement local,
  - les tests automatisés,
  - une démo hors-ligne du prototype.

C'est le fournisseur par défaut (AI_PROVIDER=mock dans .env).
"""
import re
from typing import List, Optional

from app.services.ai.base import AIAnalysisResult, AIProvider

_AMOUNT_PATTERN = re.compile(
    r"(?:USD|EUR|FCFA|XOF|\$|€)\s?[\d\s.,]{3,}|[\d\s.,]{3,}\s?(?:USD|EUR|FCFA|XOF|\$|€|dollars?|euros?)",
    re.IGNORECASE,
)
_DEADLINE_PATTERN = re.compile(
    r"(?:date limite|deadline|avant le|jusqu'au|au plus tard le)\s*[:\-]?\s*"
    r"([0-3]?\d[\/\-\.][01]?\d[\/\-\.]\d{2,4}|\d{1,2}\s+\w+\s+\d{4})",
    re.IGNORECASE,
)
_DOCUMENT_KEYWORDS = [
    "cv", "curriculum vitae", "business plan", "plan d'affaires", "statuts",
    "registre de commerce", "budget prévisionnel", "lettre de motivation",
    "pièce d'identité", "états financiers", "attestation fiscale", "rccm",
    "note conceptuelle", "concept note", "lettre de recommandation",
]
_SECTOR_KEYWORDS = {
    "Agriculture": ["agricole", "agriculture", "agroalimentaire", "élevage", "pêche"],
    "Santé": ["santé", "médical", "sanitaire", "hôpital"],
    "Éducation": ["éducation", "formation", "scolaire", "apprentissage"],
    "Numérique & Technologie": ["numérique", "digital", "tech", "informatique", "innovation"],
    "Environnement & Climat": ["environnement", "climat", "durable", "énergie renouvelable", "écologie"],
}


class MockAIProvider(AIProvider):
    """Implémentation locale, déterministe, de l'interface AIProvider."""

    def analyze_call(self, raw_text: str, title: str = "") -> AIAnalysisResult:
        text = raw_text or ""
        sentences = [s.strip() for s in re.split(r"(?<=[.!?])\s+", text) if len(s.strip()) > 15]

        objective = self._extract_by_keywords(sentences, ["objectif", "vise à", "a pour but", "permettra de"])
        eligibility = self._extract_by_keywords(
            sentences, ["éligib", "peuvent candidater", "sont éligibles", "critères", "condition"]
        )
        documents = self._extract_documents(text)
        amount_hint = self._first_match(_AMOUNT_PATTERN, text)
        deadline_hint = self._first_match(_DEADLINE_PATTERN, text)
        sector = self._suggest_sector(text + " " + title)
        difficulty = self._estimate_difficulty(documents, text)
        summary = self.generate_executive_summary(text, title)

        return AIAnalysisResult(
            executive_summary=summary,
            objective=objective or "Objectif non détecté automatiquement — à compléter manuellement.",
            eligibility=eligibility or "Critères d'éligibilité non détectés automatiquement — à compléter manuellement.",
            budget_hint=amount_hint,
            deadline_hint=deadline_hint,
            documents_required=documents,
            suggested_sector=sector,
            difficulty=difficulty,
        )

    def generate_executive_summary(self, raw_text: str, title: str = "") -> str:
        text = (raw_text or "").strip()
        if not text:
            return f"Aucune description détaillée fournie pour « {title} »." if title else "Aucune description fournie."

        sentences = [s.strip() for s in re.split(r"(?<=[.!?])\s+", text) if len(s.strip()) > 15]
        top_sentences = sentences[:3] if sentences else [text[:280]]
        summary = " ".join(top_sentences)
        if len(summary) > 480:
            summary = summary[:480].rsplit(" ", 1)[0] + "…"
        prefix = f"« {title} » — " if title else ""
        return f"{prefix}{summary}"

    # --- Helpers internes -------------------------------------------------

    @staticmethod
    def _extract_by_keywords(sentences: List[str], keywords: List[str]) -> Optional[str]:
        for sentence in sentences:
            lowered = sentence.lower()
            if any(kw in lowered for kw in keywords):
                return sentence
        return None

    @staticmethod
    def _extract_documents(text: str) -> List[str]:
        lowered = text.lower()
        found = [doc for doc in _DOCUMENT_KEYWORDS if doc in lowered]
        acronyms = {"cv", "rccm"}
        # Normalise la casse pour l'affichage (sigles en majuscules, reste en Title Case)
        return [doc.upper() if doc in acronyms else doc[0].upper() + doc[1:] for doc in found]

    @staticmethod
    def _first_match(pattern: re.Pattern, text: str) -> Optional[str]:
        match = pattern.search(text or "")
        return match.group(0).strip() if match else None

    @staticmethod
    def _suggest_sector(text: str) -> Optional[str]:
        lowered = text.lower()
        best_sector, best_score = None, 0
        for sector, keywords in _SECTOR_KEYWORDS.items():
            score = sum(1 for kw in keywords if kw in lowered)
            if score > best_score:
                best_sector, best_score = sector, score
        return best_sector

    @staticmethod
    def _estimate_difficulty(documents: List[str], text: str) -> str:
        """Heuristique simple : plus il y a de documents/contraintes demandés, plus c'est difficile."""
        word_count = len(text.split())
        score = len(documents) + (1 if word_count > 400 else 0)
        if score <= 2:
            return "facile"
        if score <= 5:
            return "moyen"
        return "difficile"
