"""Data completeness and gap detection for integrated climate-health series.

Detects temporal data gaps in integrated datasets, computes completeness
metrics, identifies consecutive missing ranges, and determines deterministic
likely reasons (e.g. requested period precedes source coverage in OpenDengue,
or the source does not provide the variable, e.g. temperature from TMD),
per FR-26 (own export check 2026-10-31; Clarke et al. 2024: coverage and
reporting differ between countries and over time). Gaps are only reported,
never filled (RECOMMENDATIONS A20).

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

from datetime import date
from typing import Sequence
import pandas as pd

from app.config import DISEASE_REGION_COVERAGE
from app.models import DataCoverage, MissingRange, PeriodRecord


def _format_period_label(dt: date, resolution: str) -> str:
    if resolution == "decade":
        return f"{dt.year // 10 * 10}s"
    if resolution == "year":
        return dt.strftime("%Y")
    if resolution == "day":
        return dt.strftime("%Y-%m-%d")
    return dt.strftime("%Y-%m")


def analyze_data_coverage(
    records: Sequence[PeriodRecord],
    disease_key: str,
    region: str,
    variables: list[str],
    case_data_source: str,
    climate_source: str,
    population_source: str,
    start_date: date,
    end_date: date,
    resolution: str = "month",
) -> tuple[list[DataCoverage], str]:
    """Analyzes data completeness for each relevant column in the integrated
    table. Excludes lag-buffer periods by clamping strictly to the requested
    start_date and end_date.
    
    Returns:
        (coverage_list, summary_step_text)
    """
    if not records:
        return [], "Checked data completeness: no records produced."

    # Clamp to requested period range (excluding any Task B climate lag buffer)
    start_period = _format_period_label(start_date, resolution)
    end_period = _format_period_label(end_date, resolution)
    eval_records = [r for r in records if start_period <= r.period <= end_period]
    if not eval_records:
        eval_records = list(records)

    total_periods = len(eval_records)

    # Columns to evaluate: (column_name, attribute_name, variable_category)
    columns_to_eval = [
        ("case_count", "case_count", "cases"),
        ("population", "population", "population"),
        ("incidence_rate_per_100k", "incidence_rate_per_100k", "incidence"),
    ]
    if "temperature" in variables:
        columns_to_eval.append(("temperature_mean_c", "temperature_mean_c", "climate_temp"))
    if "temperature_min" in variables:
        columns_to_eval.append(("temperature_min_c", "temperature_min_c", "climate_temp_min"))
    if "temperature_max" in variables:
        columns_to_eval.append(("temperature_max_c", "temperature_max_c", "climate_temp_max"))
    if "precipitation" in variables:
        columns_to_eval.append(("precipitation_sum_mm", "precipitation_sum_mm", "climate_precip"))

    # Known source coverage for built-in case source
    builtin_case_cov = DISEASE_REGION_COVERAGE.get(disease_key, {}).get(region)
    available_case_range = (
        {"start": builtin_case_cov[0], "end": builtin_case_cov[1]}
        if builtin_case_cov
        else None
    )

    coverage_list: list[DataCoverage] = []
    gaps_for_step: list[str] = []

    for col_name, attr_name, category in columns_to_eval:
        missing_count = 0
        missing_ranges: list[MissingRange] = []
        range_start: str | None = None
        prev_period: str | None = None
        first_avail: str | None = None
        last_avail: str | None = None

        for r in eval_records:
            val = getattr(r, attr_name, None)
            is_present = val is not None and not pd.isna(val)

            if is_present:
                if first_avail is None:
                    first_avail = r.period
                last_avail = r.period

                if range_start is not None and prev_period is not None:
                    missing_ranges.append(MissingRange(start=range_start, end=prev_period))
                    range_start = None
            else:
                missing_count += 1
                if range_start is None:
                    range_start = r.period

            prev_period = r.period

        if range_start is not None and prev_period is not None:
            missing_ranges.append(MissingRange(start=range_start, end=prev_period))

        periods_with_val = total_periods - missing_count
        missing_pct = round((missing_count / total_periods) * 100.0, 1) if total_periods > 0 else 0.0

        # Determine reason
        reason = None
        col_available_range = None

        # Check for sources that fundamentally do not provide the variable (TMD has no temperature)
        if climate_source == "tmd" and category in ("climate_temp", "climate_temp_min", "climate_temp_max"):
            if periods_with_val == 0:
                reason = "not_provided_by_source"
        elif missing_count > 0:
            if category in ("cases", "incidence"):
                if case_data_source == "builtin" and builtin_case_cov:
                    col_available_range = available_case_range
                    cov_start, cov_end = builtin_case_cov
                    # If gaps are before or after the coverage interval
                    is_outside = any(
                        rng.end < cov_start or rng.start > cov_end
                        for rng in missing_ranges
                    )
                    if is_outside:
                        reason = "outside_source_coverage"
                    else:
                        reason = "gaps_inside_source"
                else:
                    reason = "unknown"
            else:
                reason = "unknown"

        coverage_list.append(
            DataCoverage(
                column=col_name,
                total_periods=total_periods,
                periods_with_value=periods_with_val,
                missing_count=missing_count,
                missing_percent=missing_pct,
                missing_ranges=missing_ranges,
                first_available=first_avail,
                last_available=last_avail,
                reason=reason,
                available_range=col_available_range,
            )
        )

        # Build provenance step text for genuine gaps (not_provided_by_source is noted in TMD step)
        if missing_count > 0 and reason != "not_provided_by_source":
            if missing_ranges:
                rng_strs = [
                    f"{r.start} – {r.end}" if r.start != r.end else r.start
                    for r in missing_ranges
                ]
                gaps_for_step.append(
                    f"{col_name} missing for {missing_count} of {total_periods} periods ({', '.join(rng_strs)})"
                )
            else:
                gaps_for_step.append(
                    f"{col_name} missing for {missing_count} of {total_periods} periods"
                )

    if gaps_for_step:
        step_text = f"Checked data completeness: {'; '.join(gaps_for_step)}."
    elif any(c.reason == "not_provided_by_source" for c in coverage_list):
        step_text = "Checked data completeness: all provided variables have complete data for requested periods."
    else:
        step_text = "Checked data completeness: all requested periods have data."

    return coverage_list, step_text

