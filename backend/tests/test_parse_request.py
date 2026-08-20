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
