"""
Moteur de recommandation simple, basé sur des règles pondérées.

Le score (0 à 100) combine plusieurs signaux issus des préférences
utilisateur (renseignées à l'onboarding) :
  - secteur d'activité      -> poids 40
  - pays cible               -> poids 25
  - type de financement      -> poids 20
  - montant recherché        -> poids 15

Cette approche "rule-based" est volontairement simple pour le MVP : elle
est rapide, explicable et ne nécessite aucune donnée d'entraînement. Elle
est isolée dans son propre service pour pouvoir être remplacée plus tard
par un modèle de scoring plus avancé (ex: collaborative filtering, embeddings
sémantiques) sans changer les routers qui l'utilisent.
"""
from typing import TYPE_CHECKING, Optional

# Les modèles ne sont importés que pour l'annotation de type (pas à l'exécution).
# Cela permet de tester ce module en isolation, avec de simples objets factices,
# sans dépendre de SQLAlchemy.
if TYPE_CHECKING:
    from app.models.funding import FundingCall
    from app.models.preference import UserPreference

_WEIGHT_SECTOR = 40
_WEIGHT_COUNTRY = 25
_WEIGHT_FUNDING_TYPE = 20
_WEIGHT_AMOUNT = 15


def compute_relevance_score(preference: Optional["UserPreference"], call: "FundingCall") -> float:
    """Calcule un score de pertinence (0-100) entre les préférences d'un utilisateur et un appel."""
    if preference is None:
        return 50.0  # score neutre par défaut si l'utilisateur n'a pas encore fait l'onboarding

    score = 0.0

    # Secteur
    if preference.sector_ids and call.category_id in preference.sector_ids:
        score += _WEIGHT_SECTOR

    # Pays (un appel sans pays défini = international -> considéré comme compatible)
    if call.country_id is None:
        score += _WEIGHT_COUNTRY
    elif preference.country_ids and call.country_id in preference.country_ids:
        score += _WEIGHT_COUNTRY

    # Type de financement
    if preference.funding_types and call.funding_type in preference.funding_types:
        score += _WEIGHT_FUNDING_TYPE

    # Montant recherché : bonus si l'intervalle de l'appel chevauche celui recherché
    if preference.amount_min is not None or preference.amount_max is not None:
        user_min = preference.amount_min or 0
        user_max = preference.amount_max or float("inf")
        call_min = call.amount_min or 0
        call_max = call.amount_max or float("inf")
        overlap = call_min <= user_max and call_max >= user_min
        if overlap:
            score += _WEIGHT_AMOUNT
    else:
        score += _WEIGHT_AMOUNT  # pas de préférence de montant -> pas de pénalité

    return round(score, 1)


def sort_by_relevance(calls_with_scores):
    """Trie une liste de tuples (FundingCall, score) par score décroissant, puis par deadline proche."""
    return sorted(calls_with_scores, key=lambda pair: (-pair[1], pair[0].deadline))
