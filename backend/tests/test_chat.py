"""Unit tests for the Climate-Health Copilot chat service and endpoint.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

from unittest.mock import MagicMock, patch
from fastapi.testclient import TestClient

from app.main import app
from app.services.chat import _detect_language_fallback, _sanitize_action

client = TestClient(app)


def test_language_detection():
    assert _detect_language_fallback("გამარჯობა, რა მონაცემები გაქვს?") == "ka"
    assert _detect_language_fallback("Hallo, welche Daten gibt es für Dengue?") == "de"
    assert _detect_language_fallback("Hello, what data do you have for malaria?") == "en"


def test_chat_endpoint_fallback_georgian():
    payload = {
        "messages": [
            {"role": "user", "content": "გამარჯობა, რა მონაცემები გაქვს დენგეზე?"}
        ],
        "context": None,
    }
    with patch("app.services.chat.get_client", return_value=None):
        resp = client.post("/api/chat", json=payload)
        assert resp.status_code == 200
        data = resp.json()
        assert "Climate-Health Copilot" in data["reply"]
        assert len(data["suggested_prompts"]) > 0


def test_chat_endpoint_fallback_german():
    payload = {
        "messages": [
            {"role": "user", "content": "Hallo, welche Daten gibt es für Malaria?"}
        ],
        "context": None,
    }
    with patch("app.services.chat.get_client", return_value=None):
        resp = client.post("/api/chat", json=payload)
        assert resp.status_code == 200
        data = resp.json()
        assert "Klima- und Gesundheitsdaten" in data["reply"] or "Copilot" in data["reply"]


def test_chat_endpoint_with_active_result():
    payload = {
        "messages": [
            {"role": "user", "content": "ამიხსენი ეს შედეგები"}
        ],
        "context": {
            "current_disease": "dengue",
            "current_region": "Thailand",
            "active_result": {
                "disease": "dengue",
                "region": "Thailand",
                "total_cases": 15000,
                "peak_period": "2019-07",
                "peak_cases": 4500,
                "mean_temperature_c": 28.5,
                "mean_precipitation_mm": 180.2,
            },
        },
    }
    with patch("app.services.chat.get_client", return_value=None):
        resp = client.post("/api/chat", json=payload)
        assert resp.status_code == 200
        data = resp.json()
        assert "15000" in data["reply"]
        assert "2019-07" in data["reply"]


def test_chat_endpoint_mock_llm():
    mock_client = MagicMock()
    mock_resp = MagicMock()
    mock_resp.text = (
        '{"reply": "დენგეს და ნალექს შორის Lag 1 თვეზე შეინიშნება ძლიერი კორელაცია.", '
        '"suggested_action": {"disease": "dengue", "region": "Thailand", "variables": ["temperature", "precipitation"]}, '
        '"suggested_prompts": ["რატომ Lag 1?", "როგორ იმოქმედა ტემპერატურამ?"]}'
    )
    mock_client.models.generate_content.return_value = mock_resp

    payload = {
        "messages": [{"role": "user", "content": "როგორ მოქმედებს ნალექი დენგეზე?"}],
        "context": None,
    }
    with patch("app.services.chat.get_client", return_value=mock_client), \
         patch("app.services.chat.wait_for_rate_limit_slot"):
        resp = client.post("/api/chat", json=payload)
        assert resp.status_code == 200
        data = resp.json()
        assert "Lag 1" in data["reply"]
        assert data["suggested_action"] is not None
        assert data["suggested_action"]["disease"] == "dengue"
        assert len(data["suggested_prompts"]) == 2


def test_sanitize_action():
    valid = {
        "disease": "dengue",
        "region": "Thailand",
        "variables": ["temperature"],
        "aggregation": "native",
        "climate_source": "open-meteo-era5",
    }
    act = _sanitize_action(valid)
    assert act is not None
    assert act.disease == "dengue"
    assert act.region == "Thailand"

    invalid = {
        "disease": "unknown_disease_xyz",
        "region": "Atlantis",
    }
    assert _sanitize_action(invalid) is None
