"""Pydantic request/response schemas for the ETL API.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

from datetime import date
from typing import Literal

from pydantic import BaseModel, Field


class IntegrationRequest(BaseModel):
    disease: str = Field(examples=["dengue"])
    region: str = Field(examples=["Thailand"])
    variables: list[Literal["temperature", "precipitation"]] = Field(
        default=["temperature", "precipitation"], min_length=1
    )
    start_date: date
    end_date: date
    scenario: Literal["historical"] = "historical"
    aggregation: Literal["native", "yearly", "decadal"] = "native"
    climate_source: Literal["open-meteo-era5", "nasa-power", "tmd"] = "open-meteo-era5"
    case_data_source: Literal["builtin", "custom_url", "custom_upload", "who_gho"] = "builtin"
    custom_source_url: str | None = None
    who_indicator_code: str | None = None
    who_indicator_name: str | None = None


class PeriodRecord(BaseModel):
    period: str
    case_count: float | None = None
    temperature_mean_c: float | None = None
    precipitation_sum_mm: float | None = None


class IntegrationResponse(BaseModel):
    request_echo: IntegrationRequest
    resolution: Literal["month", "year", "decade"]
    steps: list[str]
    explanation: str
    explanation_source: Literal["llm", "fallback"]
    data: list[PeriodRecord]
    sources: list[str]
    cached: bool = False
    last_verified: str


class DiscoveredSource(BaseModel):
    """One candidate case-data source found by `/api/search-case-sources`,
    from either WHO GHO (an official statistical indicator) or HDX (a
    downloadable dataset). Every field is real data echoed back from the
    source API — nothing here is generated or guessed."""

    source_type: Literal["who_gho", "hdx"]
    title: str
    organization: str
    description: str
    citation: str
    dataset_url: str
    resource_url: str | None = None  # HDX only: direct CSV/XLSX download link
    indicator_code: str | None = None  # WHO GHO only


class ParsedRequest(BaseModel):
    """Best-effort extraction of an `IntegrationRequest` from a free-text
    user description. Every field is optional: the LLM leaves a field `None`
    rather than guessing when the text doesn't pin it down, and explains any
    assumptions/omissions in `notes` so the user can review before running
    the (unchanged, deterministic) pipeline."""

    disease: str | None = None
    region: str | None = None
    variables: list[Literal["temperature", "precipitation"]] | None = None
    start_date: date | None = None
    end_date: date | None = None
    aggregation: Literal["native", "yearly", "decadal"] | None = None
    climate_source: Literal["open-meteo-era5", "nasa-power", "tmd"] | None = None
    notes: str
