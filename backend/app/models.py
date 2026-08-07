"""Pydantic request/response schemas for the ETL API.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

from datetime import date
from typing import Literal

from pydantic import BaseModel, Field


class IntegrationRequest(BaseModel):
    disease: str = Field(examples=["dengue"])
    region: str = Field(examples=["Thailand"])
    variables: list[Literal["temperature", "precipitation"]] = [
        "temperature",
        "precipitation",
    ]
    start_date: date
    end_date: date
    scenario: Literal["historical"] = "historical"
    aggregation: Literal["native", "yearly", "decadal"] = "native"
    climate_source: Literal["open-meteo-era5", "nasa-power"] = "open-meteo-era5"
    case_data_source: Literal["builtin", "custom_url", "custom_upload"] = "builtin"
    custom_source_url: str | None = None


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
    data: list[PeriodRecord]
    sources: list[str]
    cached: bool = False
    last_verified: str
