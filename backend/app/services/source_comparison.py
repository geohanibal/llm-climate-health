"""Source comparison service (FR-27, A19).

Compares two data sources (ERA5 vs NASA POWER for climate; builtin vs custom_url
for cases) over their overlapping period. Computes Pearson r, mean difference (B - A),
mean absolute difference, and relative MAD. Assigns deterministic heuristic verdicts
(very_similar / similar / clearly_different) with a clear rule-of-thumb disclaimer
and notes on the shared seasonal cycle (climate) and case definition differences (cases),
per Clarke et al. (2024). Never alters the main dataset or cache.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

from typing import Sequence
import numpy as np
import pandas as pd
from scipy.stats import pearsonr

from app.config import CASE_DATA_SOURCES, CLIMATE_SOURCES
from app.models import (
    PeriodRecord,
    SeriesPoint,
    SourceComparisonRequest,
    SourceComparisonResponse,
    VariableComparison,
)
from app.services.etl import run_integration
from app.services.statistics import format_p_value

# Deterministic heuristic thresholds (for orientation only; not a statistical test)
VERY_SIMILAR_MIN_R = 0.90
VERY_SIMILAR_MAX_REL_MAD = 10.0  # percent
SIMILAR_MIN_R = 0.70
SIMILAR_MAX_REL_MAD = 25.0       # percent
MIN_OVERLAP_POINTS = 6

METHODOLOGY_NOTE = (
    "Rule of thumb, not a statistical test. No significance is claimed. "
    "Differences are reported as alternative (B) minus baseline (A)."
)
SEASONAL_CYCLE_NOTE = (
    "A high r partly reflects the shared seasonal cycle; "
    "the mean difference shows the systematic offset."
)
CASE_DEFINITION_NOTE = (
    "Case definitions and reporting systems may differ between sources; "
    "compare the temporal shape (r) rather than the absolute level."
)


def compute_variable_comparison(
    records_a: Sequence[PeriodRecord],
    records_b: Sequence[PeriodRecord],
    attr_name: str,
    variable_label: str,
    compare_kind: str,
    source_a_name: str,
    source_b_name: str,
) -> VariableComparison:
    """Computes comparison metrics between two series on their temporal overlap."""
    series_a_dict: dict[str, float | None] = {}
    for r in records_a:
        val = getattr(r, attr_name, None)
        series_a_dict[r.period] = float(val) if val is not None and not pd.isna(val) else None

    series_b_dict: dict[str, float | None] = {}
    for r in records_b:
        val = getattr(r, attr_name, None)
        series_b_dict[r.period] = float(val) if val is not None and not pd.isna(val) else None

    all_periods = sorted(set(series_a_dict.keys()) | set(series_b_dict.keys()))
    series_a_points = [SeriesPoint(period=p, value=series_a_dict.get(p)) for p in all_periods]
    series_b_points = [SeriesPoint(period=p, value=series_b_dict.get(p)) for p in all_periods]

    # Find overlapping points where BOTH have values
    overlap = [
        p for p in all_periods
        if series_a_dict.get(p) is not None and series_b_dict.get(p) is not None
    ]
    n_overlap = len(overlap)

    if n_overlap < 2:
        return VariableComparison(
            variable=variable_label,
            overlap_periods=n_overlap,
            too_few_points=True,
            verdict="too_few_points",
            verdict_explanation=f"Too few overlapping points (n = {n_overlap}) for a comparison.",
            series_a=series_a_points,
            series_b=series_b_points,
        )

    vals_a = np.array([series_a_dict[p] for p in overlap], dtype=float)
    vals_b = np.array([series_b_dict[p] for p in overlap], dtype=float)

    # Differences: B - A
    diffs = vals_b - vals_a
    mean_diff = float(np.mean(diffs))
    mad = float(np.mean(np.abs(diffs)))
    mean_abs_a = float(np.mean(np.abs(vals_a)))
    # Relative MAD is undefined when the baseline is ~0 on average (e.g. a
    # completely dry period); reporting 0 % there would look "very similar".
    rel_mad = float(mad / mean_abs_a * 100.0) if mean_abs_a > 1e-9 else None

    # Pearson r is undefined for a constant series (zero variance). It is left
    # empty instead of an invented r = 0 / p = 1.
    if np.std(vals_a) < 1e-9 or np.std(vals_b) < 1e-9:
        r = None
        p_val = None
    else:
        r_calc, p_calc = pearsonr(vals_a, vals_b)
        r = float(r_calc)
        p_val = float(p_calc)
    r_text = f"{r:.2f}" if r is not None else "n/a"
    rel_text = f"{rel_mad:.1f}%" if rel_mad is not None else "n/a"

    formatted_p = format_p_value(p_val)
    too_few = n_overlap < MIN_OVERLAP_POINTS

    # Verdict heuristic
    if too_few:
        verdict = "too_few_points"
        verdict_explanation = (
            f"Too few overlapping points (n = {n_overlap} < {MIN_OVERLAP_POINTS}) "
            f"for a reliable comparison. Pearson r = {r_text} ({formatted_p}), "
            f"mean difference = {mean_diff:+.2f}."
        )
    elif r is None:
        verdict = "very_similar" if mad < 1e-9 else "clearly_different"
    elif r >= VERY_SIMILAR_MIN_R and (rel_mad is None or rel_mad <= VERY_SIMILAR_MAX_REL_MAD):
        verdict = "very_similar"
    elif r >= SIMILAR_MIN_R and (rel_mad is None or rel_mad <= SIMILAR_MAX_REL_MAD):
        verdict = "similar"
    else:
        verdict = "clearly_different"

    if not too_few:
        # Determine descriptive unit / sign explanation
        if compare_kind == "climate":
            unit = "°C" if "temperature" in attr_name else "mm"
            if abs(mean_diff) < 0.05:
                offset_desc = "virtually identical on average"
            elif mean_diff > 0:
                offset_desc = f"{source_b_name} is on average {abs(mean_diff):.2f} {unit} higher"
            else:
                offset_desc = f"{source_b_name} is on average {abs(mean_diff):.2f} {unit} lower"

            verdict_explanation = (
                f"{variable_label}: {source_a_name} and {source_b_name} move with r = {r_text} "
                f"({formatted_p}); {offset_desc}. {SEASONAL_CYCLE_NOTE}"
            )
        else:
            verdict_explanation = (
                f"{variable_label}: correlation is r = {r_text} ({formatted_p}); "
                f"mean difference is {mean_diff:+.1f} cases (relative MAD: {rel_text}). "
                f"{CASE_DEFINITION_NOTE}"
            )

    return VariableComparison(
        variable=variable_label,
        overlap_periods=n_overlap,
        pearson_r=round(r, 4) if r is not None else None,
        p_value=round(p_val, 6) if p_val is not None else None,
        formatted_p_value=formatted_p,
        mean_difference=round(mean_diff, 2),
        mean_absolute_difference=round(mad, 2),
        relative_mean_absolute_difference_percent=round(rel_mad, 1) if rel_mad is not None else None,
        verdict=verdict,
        verdict_explanation=verdict_explanation,
        too_few_points=too_few,
        series_a=series_a_points,
        series_b=series_b_points,
    )


def compare_sources(req: SourceComparisonRequest) -> SourceComparisonResponse:
    """Executes integrations directly for Source A and Source B (bypassing LLM explanation,
    lag_periods=[]) and computes bivariate comparison metrics over their overlapping periods."""
    # 1. Run integration for Source A
    steps_a, records_a, res_a, audit_a, stats_a, cov_a = run_integration(
        disease_key=req.disease,
        region=req.region,
        variables=req.variables,
        start=req.start_date,
        end=req.end_date,
        aggregation=req.aggregation,
        climate_source=req.climate_source,
        case_data_source=req.case_data_source,
        population_source=req.population_source,
        custom_source_url=req.custom_source_url,
        who_indicator_code=req.who_indicator_code,
        who_indicator_name=req.who_indicator_name,
        custom_population_url=req.custom_population_url,
        population_indicator_code=req.population_indicator_code,
        population_indicator_name=req.population_indicator_name,
        lag_periods=[],
    )

    # 2. Determine Source B parameters
    if req.compare_kind == "climate":
        clim_b = req.alternative_climate_source
        if not clim_b or clim_b == req.climate_source:
            clim_b = "nasa-power" if req.climate_source == "open-meteo-era5" else "open-meteo-era5"

        source_a_label = CLIMATE_SOURCES.get(req.climate_source, {}).get("label", req.climate_source)
        source_b_label = CLIMATE_SOURCES.get(clim_b, {}).get("label", clim_b)

        steps_b, records_b, res_b, audit_b, stats_b, cov_b = run_integration(
            disease_key=req.disease,
            region=req.region,
            variables=req.variables,
            start=req.start_date,
            end=req.end_date,
            aggregation=req.aggregation,
            climate_source=clim_b,
            case_data_source=req.case_data_source,
            population_source=req.population_source,
            custom_source_url=req.custom_source_url,
            who_indicator_code=req.who_indicator_code,
            who_indicator_name=req.who_indicator_name,
            custom_population_url=req.custom_population_url,
            population_indicator_code=req.population_indicator_code,
            population_indicator_name=req.population_indicator_name,
            lag_periods=[],
        )
    else:
        # Case comparison
        case_b = req.alternative_case_data_source or "custom_url"
        custom_url_b = req.alternative_custom_source_url or req.custom_source_url
        if case_b == "custom_url" and not custom_url_b:
            raise ValueError("custom_source_url is required when comparing against custom_url cases.")

        source_a_label = CASE_DATA_SOURCES.get(req.case_data_source, {}).get("label", req.case_data_source)
        source_b_label = (
            f"Custom URL ({custom_url_b})"
            if case_b == "custom_url"
            else CASE_DATA_SOURCES.get(case_b, {}).get("label", case_b)
        )

        steps_b, records_b, res_b, audit_b, stats_b, cov_b = run_integration(
            disease_key=req.disease,
            region=req.region,
            variables=req.variables,
            start=req.start_date,
            end=req.end_date,
            aggregation=req.aggregation,
            climate_source=req.climate_source,
            case_data_source=case_b,
            population_source=req.population_source,
            custom_source_url=custom_url_b,
            who_indicator_code=req.alternative_who_indicator_code or req.who_indicator_code,
            who_indicator_name=req.alternative_who_indicator_name or req.who_indicator_name,
            custom_population_url=req.custom_population_url,
            population_indicator_code=req.population_indicator_code,
            population_indicator_name=req.population_indicator_name,
            lag_periods=[],
        )

    # 3. Check resolution consistency
    if res_a != res_b:
        return SourceComparisonResponse(
            compare_kind=req.compare_kind,
            source_a_label=source_a_label,
            source_b_label=source_b_label,
            resolution=res_a,
            variables=[],
            methodology_note=METHODOLOGY_NOTE,
            resolution_mismatch=True,
            resolution_mismatch_message=(
                f"Source A resolves to '{res_a}' while Source B resolves to '{res_b}'. "
                f"Sources with different resolutions cannot be directly compared without "
                f"artificial downscaling/upscaling."
            ),
        )

    # 4. Compare only requested base variables (never lag columns)
    comparisons: list[VariableComparison] = []
    if req.compare_kind == "climate":
        if "temperature" in req.variables:
            comparisons.append(
                compute_variable_comparison(
                    records_a, records_b, "temperature_mean_c", "Temperature (mean)",
                    "climate", source_a_label, source_b_label,
                )
            )
        if "temperature_min" in req.variables:
            comparisons.append(
                compute_variable_comparison(
                    records_a, records_b, "temperature_min_c", "Temperature (min)",
                    "climate", source_a_label, source_b_label,
                )
            )
        if "temperature_max" in req.variables:
            comparisons.append(
                compute_variable_comparison(
                    records_a, records_b, "temperature_max_c", "Temperature (max)",
                    "climate", source_a_label, source_b_label,
                )
            )
        if "precipitation" in req.variables:
            comparisons.append(
                compute_variable_comparison(
                    records_a, records_b, "precipitation_sum_mm", "Precipitation (sum)",
                    "climate", source_a_label, source_b_label,
                )
            )
    else:
        comparisons.append(
            compute_variable_comparison(
                records_a, records_b, "case_count", "Case counts",
                "cases", source_a_label, source_b_label,
            )
        )

    return SourceComparisonResponse(
        compare_kind=req.compare_kind,
        source_a_label=source_a_label,
        source_b_label=source_b_label,
        resolution=res_a,
        variables=comparisons,
        methodology_note=METHODOLOGY_NOTE,
        resolution_mismatch=False,
    )
