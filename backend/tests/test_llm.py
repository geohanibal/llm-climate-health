"""Unit tests for app.services.llm. The module-level Gemini `_client` is
monkeypatched rather than relying on GEMINI_API_KEY being unset in the test
environment, since a developer's local .env may well have a real key.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

from unittest.mock import MagicMock

import pytest

from app.models import PeriodRecord
from app.services import llm as llm_module
from app.services.llm import (
    FALLBACK_EXPLANATION,
    _coerce_parsed_json,
    build_prompt,
    explain_pipeline,
    parse_request,
)


def test_build_prompt_includes_disease_region_and_steps():
    records = [
        PeriodRecord(
            period="2020-01", case_count=5, temperature_mean_c=25.0, precipitation_sum_mm=10.0
        )
    ]
    prompt = build_prompt("dengue", "Thailand", ["step one"], records)
    assert "dengue" in prompt
    assert "Thailand" in prompt
    assert "step one" in prompt


def test_explain_pipeline_falls_back_when_llm_unavailable(monkeypatch):
    monkeypatch.setattr(llm_module, "_client", None)
    text, source = explain_pipeline("dengue", "Thailand", ["a step"], [])
    assert text == FALLBACK_EXPLANATION
    assert source == "fallback"


def test_explain_pipeline_returns_llm_text_on_success(monkeypatch):
    fake_client = MagicMock()
    fake_client.models.generate_content.return_value = MagicMock(text="  A plain-language summary.  ")
    monkeypatch.setattr(llm_module, "_client", fake_client)

    text, source = explain_pipeline("dengue", "Thailand", ["a step"], [])
    assert text == "A plain-language summary."
    assert source == "llm"


def test_explain_pipeline_falls_back_when_the_llm_call_raises(monkeypatch):
    """A bug in the SDK/network call must still degrade gracefully, the
    same as an unavailable client — never propagate to the caller."""
    fake_client = MagicMock()
    fake_client.models.generate_content.side_effect = RuntimeError("boom")
    monkeypatch.setattr(llm_module, "_client", fake_client)

    text, source = explain_pipeline("dengue", "Thailand", ["a step"], [])
    assert text == FALLBACK_EXPLANATION
    assert source == "fallback"


def test_parse_request_raises_when_llm_unavailable(monkeypatch):
    monkeypatch.setattr(llm_module, "_client", None)
    with pytest.raises(RuntimeError):
        parse_request(
            "dengue in Thailand",
            diseases={"dengue": "Dengue"},
            regions=["Thailand"],
            variables=["temperature", "precipitation"],
            aggregations=["native"],
            climate_sources=["open-meteo-era5"],
        )


def test_parse_request_returns_coerced_result_on_success(monkeypatch):
    fake_client = MagicMock()
    fake_client.models.generate_content.return_value = MagicMock(
        text=(
            '{"disease": "dengue", "region": "Thailand", "variables": ["temperature"], '
            '"start_date": "2015-01-01", "end_date": "2020-01-01", "aggregation": "yearly", '
            '"climate_source": "open-meteo-era5", "notes": "ok"}'
        )
    )
    monkeypatch.setattr(llm_module, "_client", fake_client)

    result = parse_request(
        "dengue in Thailand since 2015",
        diseases={"dengue": "Dengue"},
        regions=["Thailand"],
        variables=["temperature", "precipitation"],
        aggregations=["native", "yearly"],
        climate_sources=["open-meteo-era5"],
    )
    assert result.disease == "dengue"
    assert result.region == "Thailand"
    assert result.aggregation == "yearly"


def test_coerce_parsed_json_passes_through_valid_payload():
    raw = {
        "disease": "dengue",
        "region": "Thailand",
        "variables": ["temperature", "precipitation"],
        "start_date": "2015-01-01",
        "end_date": "2023-12-01",
        "aggregation": "yearly",
        "climate_source": "nasa-power",
        "notes": "all good",
    }
    result = _coerce_parsed_json(
        raw, {"dengue", "malaria", "cholera"}, {"Thailand", "Kenya"}, {"open-meteo-era5", "nasa-power"}
    )
    assert result.disease == "dengue"
    assert result.region == "Thailand"
    assert result.variables == ["temperature", "precipitation"]
    assert result.aggregation == "yearly"
    assert result.climate_source == "nasa-power"
    assert result.notes == "all good"


def test_coerce_parsed_json_drops_unrecognized_disease_and_region():
    raw = {"disease": "not-a-real-disease", "region": "Atlantis", "notes": ""}
    result = _coerce_parsed_json(raw, {"dengue"}, {"Thailand"}, {"open-meteo-era5"})
    assert result.disease is None
    assert result.region is None
    assert "unrecognized disease" in result.notes
    assert "unrecognized region" in result.notes


def test_coerce_parsed_json_drops_invalid_dates_and_enums():
    raw = {
        "start_date": "not-a-date",
        "aggregation": "monthly",  # not a valid literal
        "climate_source": "made-up-source",
        "variables": ["temperature", "wind"],  # wind isn't supported
        "notes": "",
    }
    result = _coerce_parsed_json(raw, {"dengue"}, {"Thailand"}, {"open-meteo-era5"})
    assert result.start_date is None
    assert result.aggregation is None
    assert result.climate_source is None
    assert result.variables == ["temperature"]
