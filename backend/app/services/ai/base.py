"""
Contrat abstrait d'un fournisseur d'intelligence artificielle.

Toute l'application ne dépend QUE de cette interface (`AIProvider`), jamais
directement d'OpenAI ou d'un autre SDK. Pour changer de fournisseur (Mistral,
Anthropic, un modèle open-source auto-hébergé...), il suffit d'écrire une
nouvelle classe qui hérite de `AIProvider` et de la brancher dans
`ai_service.get_ai_provider()` — aucun autre fichier de l'application n'a
besoin d'être modifié. C'est le pattern "Strategy".
"""
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import List, Optional


@dataclass
class AIAnalysisResult:
    """Résultat structuré de l'analyse IA d'un appel à projets (TDR)."""

    executive_summary: str                     # résumé exécutif (3-5 phrases)
    objective: str                              # objectif du financement
    eligibility: str                            # critères d'éligibilité
    budget_hint: Optional[str] = None           # montant détecté en texte libre, si trouvé
    deadline_hint: Optional[str] = None         # date limite détectée en texte libre, si trouvée
    documents_required: List[str] = field(default_factory=list)
    suggested_sector: Optional[str] = None      # nom de secteur suggéré par l'IA
    difficulty: str = "moyen"                   # "facile" | "moyen" | "difficile"


class AIProvider(ABC):
    """Interface que doit implémenter tout fournisseur d'IA (OpenAI, mock, autre...)."""

    @abstractmethod
    def analyze_call(self, raw_text: str, title: str = "") -> AIAnalysisResult:
        """
        Analyse le texte brut d'un appel à projets (TDR) et retourne les
        informations structurées : résumé, objectif, éligibilité, budget,
        date limite, documents requis, secteur suggéré, niveau de difficulté.
        """
        raise NotImplementedError

    @abstractmethod
    def generate_executive_summary(self, raw_text: str, title: str = "") -> str:
        """Génère uniquement un résumé exécutif court (utilisé pour un ré-résumé rapide)."""
        raise NotImplementedError
