"""
Tests unitaires du moteur de recommandation.
Utilise des objets simples (SimpleNamespace) pour simuler les modèles
SQLAlchemy sans avoir besoin d'une base de données réelle.
"""
from types import SimpleNamespace

from app.services.recommendation import compute_relevance_score


def _preference(**kwargs):
    defaults = dict(sector_ids=[], country_ids=[], funding_types=[], amount_min=None, amount_max=None)
    defaults.update(kwargs)
    return SimpleNamespace(**defaults)


def _call(**kwargs):
    defaults = dict(category_id=1, country_id=1, funding_type="grant", amount_min=10000, amount_max=50000)
    defaults.update(kwargs)
    return SimpleNamespace(**defaults)


def test_no_preference_returns_neutral_score():
    call = _call()
    assert compute_relevance_score(None, call) == 50.0


def test_full_match_gives_max_score():
    pref = _preference(sector_ids=[1], country_ids=[1], funding_types=["grant"])
    call = _call()
    score = compute_relevance_score(pref, call)
    assert score == 100.0


def test_no_match_gives_low_score():
    pref = _preference(sector_ids=[9], country_ids=[9], funding_types=["loan"])
    call = _call()
    score = compute_relevance_score(pref, call)
    assert score == 0.0


def test_international_call_always_matches_country():
    pref = _preference(sector_ids=[1], country_ids=[9], funding_types=["grant"])
    call = _call(country_id=None)
    score = compute_relevance_score(pref, call)
    # secteur (40) + pays international considéré compatible (25) + type (20) + pas de préférence montant (15)
    assert score == 100.0


def test_amount_overlap_detection():
    pref = _preference(amount_min=60000, amount_max=100000)
    call = _call(amount_min=10000, amount_max=50000)  # aucun chevauchement avec la préférence
    score = compute_relevance_score(pref, call)
    assert score == 0.0  # secteur/pays/type non renseignés -> pas de bonus, montant hors plage -> pas de bonus
