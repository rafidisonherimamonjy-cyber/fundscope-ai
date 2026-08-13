"""Tests unitaires du fournisseur IA local (MockAIProvider) — aucune dépendance externe."""
from app.services.ai.mock_provider import MockAIProvider

SAMPLE_TDR = (
    "Cet appel à projets vise à soutenir les coopératives agricoles innovantes. "
    "Sont éligibles les coopératives enregistrées depuis plus de 12 mois. "
    "Le budget alloué par projet varie entre 8 000 et 45 000 USD. "
    "Les dossiers doivent inclure un business plan, un budget prévisionnel et les statuts. "
    "Date limite : 30/11/2026."
)


def test_analyze_call_extracts_documents():
    provider = MockAIProvider()
    result = provider.analyze_call(SAMPLE_TDR, title="Appel test")
    assert "Business plan" in result.documents_required
    assert "Statuts" in result.documents_required


def test_analyze_call_extracts_objective_and_eligibility():
    provider = MockAIProvider()
    result = provider.analyze_call(SAMPLE_TDR, title="Appel test")
    assert "coopératives agricoles" in result.objective
    assert "éligibles" in result.eligibility


def test_analyze_call_detects_amount_hint():
    provider = MockAIProvider()
    result = provider.analyze_call(SAMPLE_TDR, title="Appel test")
    assert result.budget_hint is not None
    assert "45" in result.budget_hint or "USD" in result.budget_hint


def test_analyze_call_suggests_agriculture_sector():
    provider = MockAIProvider()
    result = provider.analyze_call(SAMPLE_TDR, title="Appel agricole")
    assert result.suggested_sector == "Agriculture"


def test_generate_executive_summary_not_empty():
    provider = MockAIProvider()
    summary = provider.generate_executive_summary(SAMPLE_TDR, title="Appel test")
    assert len(summary) > 0
    assert "Appel test" in summary


def test_generate_executive_summary_handles_empty_text():
    provider = MockAIProvider()
    summary = provider.generate_executive_summary("", title="Sans texte")
    assert "Sans texte" in summary


def test_difficulty_is_one_of_expected_values():
    provider = MockAIProvider()
    result = provider.analyze_call(SAMPLE_TDR, title="Appel test")
    assert result.difficulty in {"facile", "moyen", "difficile"}
