"""Unit tests for app.services.source_discovery. The underlying WHO GHO and
HDX searches are mocked so these never touch the network.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

from unittest.mock import patch

from app.services.source_discovery import search_case_sources

_HDX_RESULT = [
    {
        "title": "Malaria cases Kenya",
        "organization": "MoH Kenya",
        "notes": "Annual counts",
        "dataset_url": "https://data.humdata.org/dataset/malaria-kenya",
        "resource_url": "https://example.org/data.csv",
    }
]


@patch("app.services.source_discovery.hdx.search_case_datasets")
@patch("app.services.source_discovery.who_gho.search_indicators")
def test_combines_who_and_hdx_results(mock_who, mock_hdx):
    mock_who.return_value = [{"code": "MALARIA_EST_CASES", "name": "Estimated malaria cases"}]
    mock_hdx.return_value = _HDX_RESULT
    results = search_case_sources("Malaria", "Kenya")
    assert {r.source_type for r in results} == {"who_gho", "hdx"}


@patch("app.services.source_discovery.hdx.search_case_datasets")
@patch("app.services.source_discovery.who_gho.search_indicators")
def test_survives_who_failure(mock_who, mock_hdx):
    mock_who.side_effect = RuntimeError("WHO API down")
    mock_hdx.return_value = _HDX_RESULT
    results = search_case_sources("Malaria", "Kenya")
    assert [r.source_type for r in results] == ["hdx"]


@patch("app.services.source_discovery.hdx.search_case_datasets")
@patch("app.services.source_discovery.who_gho.search_indicators")
def test_survives_hdx_failure(mock_who, mock_hdx):
    mock_who.return_value = [{"code": "MALARIA_EST_CASES", "name": "Estimated malaria cases"}]
    mock_hdx.side_effect = RuntimeError("HDX API down")
    results = search_case_sources("Malaria", "Kenya")
    assert [r.source_type for r in results] == ["who_gho"]


@patch("app.services.source_discovery.hdx.search_case_datasets")
@patch("app.services.source_discovery.who_gho.search_indicators")
def test_returns_empty_list_when_both_fail(mock_who, mock_hdx):
    mock_who.side_effect = RuntimeError("WHO API down")
    mock_hdx.side_effect = RuntimeError("HDX API down")
    assert search_case_sources("Malaria", "Kenya") == []


@patch("app.services.source_discovery.hdx.search_case_datasets")
@patch("app.services.source_discovery.who_gho.search_indicators")
def test_falls_back_to_disease_only_hdx_search_on_empty_first_result(mock_who, mock_hdx):
    """`hdx.search_case_datasets(f"{disease} {region}") or
    hdx.search_case_datasets(disease)` — an empty (not just a raised) first
    result must still trigger the disease-only fallback search."""
    mock_who.return_value = []
    mock_hdx.side_effect = [[], _HDX_RESULT]
    results = search_case_sources("Malaria", "Kenya")
    assert len(results) == 1
    assert mock_hdx.call_count == 2
