"""Unit tests for app.services.tmd.

NOTE: `_parse_tmd_response`'s expected field names are a best-effort read of
TMD's public docs (see module docstring in tmd.py) and have not been
verified against a live response — this test fixture encodes that same
best guess, so it will need updating alongside the parser once we've run a
real request with TMD_API_UID/TMD_API_UKEY configured.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

import pytest

from app.services.tmd import _parse_tmd_response, is_available


def test_is_available_false_without_credentials(monkeypatch):
    monkeypatch.setattr("app.services.tmd.TMD_API_UID", "")
    monkeypatch.setattr("app.services.tmd.TMD_API_UKEY", "")
    assert is_available() is False


def test_is_available_true_with_credentials(monkeypatch):
    monkeypatch.setattr("app.services.tmd.TMD_API_UID", "demo")
    monkeypatch.setattr("app.services.tmd.TMD_API_UKEY", "demokey")
    assert is_available() is True


def test_parse_tmd_response_extracts_monthly_rainfall():
    payload = {
        "Stations": [
            {"year": 2020, "month": 1, "rainfall": 12.5},
            {"year": 2020, "month": 2, "rainfall": 45.0},
        ]
    }
    df = _parse_tmd_response(payload)
    assert list(df["period"]) == ["2020-01", "2020-02"]
    assert list(df["precipitation_sum"]) == [12.5, 45.0]
    assert df["temperature_2m_mean"].isna().all()


def test_parse_tmd_response_raises_on_unrecognized_shape():
    with pytest.raises(RuntimeError):
        _parse_tmd_response({"unexpected": "shape"})


def test_parse_tmd_response_raises_when_records_have_no_usable_rows():
    with pytest.raises(RuntimeError):
        _parse_tmd_response({"Stations": [{"note": "no year/month here"}]})
