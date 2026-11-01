"""Pydantic request/response schemas for the ETL API.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

from datetime import date
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator


ClimateVariable = Literal["temperature", "precipitation", "temperature_min", "temperature_max"]


class IntegrationRequest(BaseModel):
    disease: str = Field(examples=["dengue"])
    region: str = Field(examples=["Thailand"])
    variables: list[ClimateVariable] = Field(
        default=["temperature", "precipitation"], min_length=1
    )
    start_date: date
    end_date: date
    scenario: Literal["historical"] = "historical"
    aggregation: Literal["native", "daily", "yearly", "decadal"] = "native"
    climate_source: Literal["open-meteo-era5", "nasa-power", "tmd", "custom_upload"] = "open-meteo-era5"
    case_data_source: Literal["builtin", "custom_url", "custom_upload", "who_gho"] = "builtin"
    population_source: Literal["worldbank", "un_wpp", "worldbank_indicator", "custom_url", "custom_upload"] = "worldbank"
    custom_source_url: str | None = None
    who_indicator_code: str | None = None
    who_indicator_name: str | None = None
    custom_population_url: str | None = None
    population_indicator_code: str | None = None
    population_indicator_name: str | None = None
    lag_periods: list[int] = Field(default_factory=list)

    @field_validator("lag_periods")
    @classmethod
    def validate_lag_periods(cls, v: list[int]) -> list[int]:
        if not v:
            return []
        for lag in v:
            if not isinstance(lag, int) or lag < 1 or lag > 6:
                raise ValueError("lag_periods elements must be integers between 1 and 6.")
        return sorted(list(set(v)))


class PeriodRecord(BaseModel):
    model_config = ConfigDict(extra="allow")
    period: str
    case_count: float | None = None
    population: float | None = None
    incidence_rate_per_100k: float | None = None
    temperature_mean_c: float | None = None
    temperature_min_c: float | None = None
    temperature_max_c: float | None = None
    precipitation_sum_mm: float | None = None


class DataTransformationAudit(BaseModel):
    """Audit trail of data harmonization and transformations applied to
    user-supplied or external case datasets."""

    original_columns: list[str] = Field(default_factory=list)
    selected_date_column: str | None = None
    selected_value_column: str | None = None
    total_rows_received: int = 0
    valid_rows_retained: int = 0
    dropped_rows_count: int = 0
    transformations_applied: list[str] = Field(default_factory=list)
    human_explanation: str = ""


class CorrelationMetric(BaseModel):
    variable: str
    lag_periods: int
    pearson_r: float | None = None
    pearson_p: float | None = None
    spearman_rho: float | None = None
    spearman_p: float | None = None
    significant: bool = False
    sample_size: int = 0


class StatisticalSummary(BaseModel):
    sample_size: int
    correlations: list[CorrelationMetric] = Field(default_factory=list)
    peak_period: str | None = None
    peak_cases: float | None = None
    peak_incidence_per_100k: float | None = None
    mean_temperature_c: float | None = None
    mean_precipitation_mm: float | None = None
    total_cases: float | None = None
    scientific_disclaimer: str = ""


class MissingRange(BaseModel):
    start: str
    end: str


class DataCoverage(BaseModel):
    column: str
    total_periods: int
    periods_with_value: int
    missing_count: int
    missing_percent: float
    missing_ranges: list[MissingRange] = Field(default_factory=list)
    first_available: str | None = None
    last_available: str | None = None
    reason: Literal[
        "outside_source_coverage",
        "gaps_inside_source",
        "not_provided_by_source",
        "unknown",
    ] | None = None
    available_range: dict[str, str] | None = None


class IntegrationResponse(BaseModel):
    request_echo: IntegrationRequest
    resolution: Literal["day", "month", "year", "decade"]
    steps: list[str]
    explanation: str
    explanation_source: Literal["llm", "fallback"]
    data: list[PeriodRecord]
    sources: list[str]
    # Provenance for exports (FR-25): licence of each source (same order as
    # `sources`) and the software version that produced the dataset.
    licenses: list[str] = Field(default_factory=list)
    system_version: str = "unknown"
    cached: bool = False
    last_verified: str
    transformation_audit: DataTransformationAudit | None = None
    statistical_summary: StatisticalSummary | None = None
    data_coverage: list[DataCoverage] = Field(default_factory=list)


class DiscoveredSource(BaseModel):
    """One candidate case-data source found by `/api/search-case-sources`,
    from either WHO GHO (an official statistical indicator) or HDX (a
    downloadable dataset). Every field is real data echoed back from the
    source API — nothing here is generated or guessed."""

    source_type: Literal["who_gho", "hdx", "worldbank"]
    title: str
    organization: str
    description: str
    citation: str
    dataset_url: str
    resource_url: str | None = None  # HDX only: direct CSV/XLSX download link
    indicator_code: str | None = None  # WHO GHO / World Bank only


class ParsedRequest(BaseModel):
    """Best-effort extraction of an `IntegrationRequest` from a free-text
    user description. Every field is optional: the LLM leaves a field `None`
    rather than guessing when the text doesn't pin it down, and explains any
    assumptions/omissions in `notes` so the user can review before running
    the (unchanged, deterministic) pipeline."""

    disease: str | None = None
    region: str | None = None
    variables: list[ClimateVariable] | None = None
    start_date: date | None = None
    end_date: date | None = None
    aggregation: Literal["native", "daily", "yearly", "decadal"] | None = None
    climate_source: Literal["open-meteo-era5", "nasa-power", "tmd", "custom_upload"] | None = None
    notes: str


class ChatMessage(BaseModel):
    role: Literal["user", "assistant"]
    content: str


class FormPrefillAction(BaseModel):
    disease: str | None = None
    region: str | None = None
    variables: list[ClimateVariable] | None = None
    start_date: str | None = None
    end_date: str | None = None
    aggregation: Literal["native", "daily", "yearly", "decadal"] | None = None
    climate_source: Literal["open-meteo-era5", "nasa-power", "tmd", "custom_upload"] | None = None


class ActiveResultSummary(BaseModel):
    disease: str | None = None
    region: str | None = None
    resolution: str | None = None
    sample_size: int | None = None
    total_cases: float | None = None
    peak_period: str | None = None
    peak_cases: float | None = None
    peak_incidence_per_100k: float | None = None
    mean_temperature_c: float | None = None
    mean_precipitation_mm: float | None = None
    correlations_summary: list[str] | None = None
    explanation: str | None = None


class ChatContext(BaseModel):
    current_disease: str | None = None
    current_region: str | None = None
    current_start_date: str | None = None
    current_end_date: str | None = None
    active_result: ActiveResultSummary | None = None
    language: str | None = None
    literature_source: str | None = None


class ChatRequest(BaseModel):
    messages: list[ChatMessage]
    context: ChatContext | None = None


class ChatResponse(BaseModel):
    reply: str
    suggested_action: FormPrefillAction | None = None
    suggested_prompts: list[str] = Field(default_factory=list)

