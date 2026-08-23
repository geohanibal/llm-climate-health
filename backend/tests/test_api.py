"""Integration tests for the FastAPI endpoints in app.main.

Note: test_integrate_end_to_end_dengue_thailand hits the real Open-Meteo
climate API (no way to test the actual pipeline without it) and therefore
needs internet access. Everything else here is network-free.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

import io
from datetime import date, timedelta
from unittest.mock import patch

import pandas as pd
import pytest
import requests
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health():
    resp = client.get("/api/health")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}


def test_options_shape():
    resp = client.get("/api/options")
    assert resp.status_code == 200
    body = resp.json()
    assert "dengue" in body["diseases"]
    assert "Thailand" in body["regions"]
    assert "temperature" in body["variables"]


def _valid_request(**overrides):
    req = {
        "disease": "dengue",
        "region": "Thailand",
        "variables": ["temperature", "precipitation"],
        "start_date": "2020-01-01",
        "end_date": "2020-03-01",
        "aggregation": "native",
        "climate_source": "open-meteo-era5",
        "case_data_source": "builtin",
    }
    req.update(overrides)
    return req


def test_integrate_rejects_unknown_region():
    resp = client.post("/api/integrate", json=_valid_request(region="Atlantis"))
    assert resp.status_code == 400


def test_integrate_rejects_unknown_disease():
    resp = client.post("/api/integrate", json=_valid_request(disease="not-a-disease"))
    assert resp.status_code == 400


def test_integrate_rejects_start_after_end():
    resp = client.post(
        "/api/integrate", json=_valid_request(start_date="2021-01-01", end_date="2020-01-01")
    )
    assert resp.status_code == 400


def test_integrate_rejects_custom_url_without_url():
    resp = client.post("/api/integrate", json=_valid_request(case_data_source="custom_url"))
    assert resp.status_code == 400


def test_integrate_rejects_tmd_source_for_non_thailand_region():
    resp = client.post(
        "/api/integrate",
        json=_valid_request(region="Kenya", disease="malaria", climate_source="tmd"),
    )
    assert resp.status_code == 400


def test_integrate_with_tmd_source_returns_clear_error_without_credentials(monkeypatch):
    """Without TMD_API_UID/TMD_API_UKEY configured, this must surface a
    clear 503 (local misconfiguration, not an upstream/TMD failure) with an
    actionable message — not a 502 or an opaque 500."""
    monkeypatch.setattr("app.services.tmd.TMD_API_UID", "")
    monkeypatch.setattr("app.services.tmd.TMD_API_UKEY", "")
    resp = client.post("/api/integrate", json=_valid_request(climate_source="tmd"))
    assert resp.status_code == 503
    assert "TMD_API_UID" in resp.json()["detail"]


def test_integrate_rejects_future_end_date():
    resp = client.post(
        "/api/integrate",
        json=_valid_request(end_date=(date.today() + timedelta(days=1)).isoformat()),
    )
    assert resp.status_code == 400
    assert "future" in resp.json()["detail"]


@patch("app.main.run_integration")
def test_integrate_wraps_upstream_network_failure_as_502(mock_run):
    mock_run.side_effect = requests.exceptions.ConnectionError("no route to host")
    resp = client.post("/api/integrate", json=_valid_request(region="Kenya", disease="malaria"))
    assert resp.status_code == 502
    assert "upstream" in resp.json()["detail"]


def test_options_exposes_region_coverage_for_dengue():
    resp = client.get("/api/options")
    body = resp.json()
    coverage = body["diseases"]["dengue"]["region_coverage"]
    assert coverage["Thailand"][0] <= coverage["Thailand"][1]


@patch("app.services.etl.fetch_climate")
def test_integrate_out_of_coverage_window_is_accepted_but_returns_no_cases(mock_climate):
    """Pins current (intentional) behavior: DISEASE_REGION_COVERAGE is
    advisory only — the frontend warns, but the backend still runs the
    query rather than hard-rejecting it. Italy's real dengue rows only
    start in 2024, so a pre-2024 window must come back 200 with every
    case_count null instead of a validation error."""
    mock_climate.return_value = pd.DataFrame(
        {"period": ["2000-01", "2000-02"], "temperature_2m_mean": [10.0, 11.0], "precipitation_sum": [5.0, 6.0]}
    )
    resp = client.post(
        "/api/integrate",
        json=_valid_request(
            region="Italy", start_date="2000-01-01", end_date="2000-06-01"
        ),
    )
    assert resp.status_code == 200
    body = resp.json()
    assert all(row["case_count"] is None for row in body["data"])


@patch("app.services.source_discovery.hdx.search_case_datasets")
@patch("app.services.source_discovery.who_gho.search_indicators")
def test_search_case_sources_endpoint_returns_combined_results(mock_who, mock_hdx):
    mock_who.return_value = [{"code": "MALARIA_EST_CASES", "name": "Estimated malaria cases"}]
    mock_hdx.return_value = []
    resp = client.get("/api/search-case-sources", params={"disease": "malaria", "region": "Kenya"})
    assert resp.status_code == 200
    body = resp.json()
    assert body[0]["source_type"] == "who_gho"


def test_search_case_sources_rejects_unknown_disease():
    resp = client.get("/api/search-case-sources", params={"disease": "not-a-disease", "region": "Kenya"})
    assert resp.status_code == 400


def test_search_case_sources_rejects_unknown_region():
    resp = client.get("/api/search-case-sources", params={"disease": "malaria", "region": "Atlantis"})
    assert resp.status_code == 400


@patch("app.services.etl.fetch_climate")
def test_integrate_upload_runs_pipeline_with_uploaded_csv(mock_climate):
    mock_climate.return_value = pd.DataFrame(
        {"period": ["2020-01", "2020-02"], "temperature_2m_mean": [25.0, 26.0], "precipitation_sum": [1.0, 2.0]}
    )
    file_content = b"month,cases\n2020-01,5\n2020-02,7\n"
    resp = client.post(
        "/api/integrate/upload",
        data={
            "disease": "dengue",
            "region": "Thailand",
            "variables": "temperature,precipitation",
            "start_date": "2020-01-01",
            "end_date": "2020-03-01",
        },
        files={"file": ("cases.csv", io.BytesIO(file_content), "text/csv")},
    )
    assert resp.status_code == 200
    body = resp.json()
    assert "cases.csv" in body["sources"][1]
    assert any(row["case_count"] is not None for row in body["data"])


def test_integrate_upload_rejects_unknown_region():
    resp = client.post(
        "/api/integrate/upload",
        data={
            "disease": "dengue",
            "region": "Atlantis",
            "variables": "temperature",
            "start_date": "2020-01-01",
            "end_date": "2020-03-01",
        },
        files={"file": ("cases.csv", io.BytesIO(b"month,cases\n2020-01,5\n"), "text/csv")},
    )
    assert resp.status_code == 400


def test_integrate_rejects_custom_upload_source_on_json_endpoint():
    resp = client.post("/api/integrate", json=_valid_request(case_data_source="custom_upload"))
    assert resp.status_code == 400


@pytest.mark.network
def test_integrate_end_to_end_dengue_thailand():
    resp = client.post("/api/integrate", json=_valid_request())
    assert resp.status_code == 200
    body = resp.json()
    assert body["resolution"] == "month"
    assert body["explanation_source"] in ("llm", "fallback")
    assert len(body["data"]) > 0
