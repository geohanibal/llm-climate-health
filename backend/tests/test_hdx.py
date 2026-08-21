"""Unit tests for app.services.hdx. requests.get is mocked throughout so
these never touch the network.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

from unittest.mock import MagicMock, patch

from app.services.hdx import search_case_datasets


def _mock_response(payload: dict) -> MagicMock:
    resp = MagicMock()
    resp.raise_for_status = MagicMock()
    resp.json.return_value = payload
    return resp


@patch("app.services.hdx.requests.get")
def test_search_case_datasets_returns_first_tabular_resource(mock_get):
    mock_get.return_value = _mock_response(
        {
            "success": True,
            "result": {
                "results": [
                    {
                        "title": "Dengue cases Thailand",
                        "organization": {"title": "MoH Thailand"},
                        "notes": "Monthly counts",
                        "name": "dengue-thailand",
                        "resources": [
                            {"format": "PDF", "url": "https://example.org/report.pdf"},
                            {"format": "CSV", "url": "https://example.org/data.csv"},
                        ],
                    }
                ]
            },
        }
    )
    results = search_case_datasets("dengue")
    assert len(results) == 1
    assert results[0]["resource_url"] == "https://example.org/data.csv"
    assert results[0]["title"] == "Dengue cases Thailand"


@patch("app.services.hdx.requests.get")
def test_search_case_datasets_skips_packages_without_tabular_resource(mock_get):
    mock_get.return_value = _mock_response(
        {
            "success": True,
            "result": {
                "results": [
                    {
                        "title": "PDF-only report",
                        "organization": {"title": "Org"},
                        "notes": "",
                        "name": "pdf-only",
                        "resources": [{"format": "PDF", "url": "https://example.org/report.pdf"}],
                    }
                ]
            },
        }
    )
    assert search_case_datasets("dengue") == []


@patch("app.services.hdx.requests.get")
def test_search_case_datasets_returns_empty_on_unsuccessful_response(mock_get):
    mock_get.return_value = _mock_response({"success": False})
    assert search_case_datasets("dengue") == []
