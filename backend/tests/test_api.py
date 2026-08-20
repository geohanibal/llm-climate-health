"""Integration tests for the FastAPI endpoints in app.main.

Note: test_integrate_end_to_end_dengue_thailand hits the real Open-Meteo
climate API (no way to test the actual pipeline without it) and therefore
needs internet access. Everything else here is network-free.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

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
    clear 502 with an actionable message — not an opaque 500."""
    monkeypatch.setattr("app.services.tmd.TMD_API_UID", "")
    monkeypatch.setattr("app.services.tmd.TMD_API_UKEY", "")
    resp = client.post("/api/integrate", json=_valid_request(climate_source="tmd"))
    assert resp.status_code == 502
    assert "TMD_API_UID" in resp.json()["detail"]


def test_integrate_end_to_end_dengue_thailand():
    resp = client.post("/api/integrate", json=_valid_request())
    assert resp.status_code == 200
    body = resp.json()
    assert body["resolution"] == "month"
    assert body["explanation_source"] in ("llm", "fallback")
    assert len(body["data"]) > 0
