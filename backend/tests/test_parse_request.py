"""Tests for POST /api/parse-request.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

from fastapi.testclient import TestClient

from app.main import app
from app.services import llm as llm_module

client = TestClient(app)


def test_parse_request_returns_503_when_llm_unavailable(monkeypatch):
    monkeypatch.setattr(llm_module, "_client", None)
    resp = client.post("/api/parse-request", json={"text": "dengue in Thailand"})
    assert resp.status_code == 503

from unittest.mock import MagicMock


def test_parse_request_endpoint_recognizes_tmin_tmax(monkeypatch):
    """LLM parsing extracts temperature_min and temperature_max variables."""
    fake_client = MagicMock()
    fake_client.models.generate_content.return_value = MagicMock(
        text=(
            '{"disease": "dengue", "region": "Thailand", '
            '"variables": ["temperature_min", "temperature_max"], '
            '"start_date": "2015-01-01", "end_date": "2020-01-01", "aggregation": "native", '
            '"climate_source": "open-meteo-era5", "notes": "parsed min and max temperature"}'
        )
    )
    monkeypatch.setattr(llm_module, "_client", fake_client)

    resp = client.post(
        "/api/parse-request",
        json={"text": "Dengue in Thailand with minimum and maximum temperature from 2015 to 2020"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["disease"] == "dengue"
    assert data["region"] == "Thailand"
    assert data["variables"] == ["temperature_min", "temperature_max"]
