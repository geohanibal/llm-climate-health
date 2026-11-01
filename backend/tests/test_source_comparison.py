"""Tests for source comparison service (FR-27 / Task F)."""

import pytest

from app.models import PeriodRecord, SourceComparisonRequest
from app.services.source_comparison import (
    compute_variable_comparison,
)


def _make_record(period: str, temp: float | None = None, prec: float | None = None, cases: int | None = None):
    return PeriodRecord(
        period=period,
        cases=cases if cases is not None else 10,
        temperature=temp,
        precipitation=prec,
        temperature_mean_c=temp,
        precipitation_sum_mm=prec,
        case_count=cases if cases is not None else 10,
    )


def test_compute_variable_comparison_identical():
    periods = ["2020-01", "2020-02", "2020-03", "2020-04", "2020-05", "2020-06"]
    temps = [25.0, 26.0, 27.5, 29.0, 30.0, 28.5]
    records_a = [_make_record(p, temp=t) for p, t in zip(periods, temps)]
    records_b = [_make_record(p, temp=t) for p, t in zip(periods, temps)]

    comp = compute_variable_comparison(
        records_a=records_a,
        records_b=records_b,
        attr_name="temperature_mean_c",
        variable_label="Mean temperature (°C)",
        compare_kind="climate",
        source_a_name="Open-Meteo ERA5",
        source_b_name="NASA POWER",
    )

    assert comp is not None
    assert comp.variable == "Mean temperature (°C)"
    assert comp.overlap_periods == 6
    assert comp.pearson_r == 1.0
    assert comp.mean_difference == 0.0
    assert comp.mean_absolute_difference == 0.0
    assert comp.relative_mean_absolute_difference_percent == 0.0
    assert comp.verdict == "very_similar"
    assert not comp.too_few_points
    # Check that seasonal cycle sentence is present for climate comparisons
    assert "shared seasonal cycle" in comp.verdict_explanation
    # No word "significant" in explanations
    assert "significant" not in comp.verdict_explanation.lower()


def test_compute_variable_comparison_systematic_offset():
    periods = ["2020-01", "2020-02", "2020-03", "2020-04", "2020-05", "2020-06"]
    temps_a = [20.0, 22.0, 24.0, 26.0, 28.0, 30.0]
    # B has constant +1.5 offset
    temps_b = [21.5, 23.5, 25.5, 27.5, 29.5, 31.5]
    records_a = [_make_record(p, temp=t) for p, t in zip(periods, temps_a)]
    records_b = [_make_record(p, temp=t) for p, t in zip(periods, temps_b)]

    comp = compute_variable_comparison(
        records_a=records_a,
        records_b=records_b,
        attr_name="temperature_mean_c",
        variable_label="Mean temperature (°C)",
        compare_kind="climate",
        source_a_name="Source A",
        source_b_name="Source B",
    )

    assert comp is not None
    assert comp.overlap_periods == 6
    assert pytest.approx(comp.pearson_r, rel=1e-4) == 1.0
    assert pytest.approx(comp.mean_difference, rel=1e-4) == 1.5
    assert pytest.approx(comp.mean_absolute_difference, rel=1e-4) == 1.5
    # mean of source A is 25.0 -> rel MAD = 1.5 / 25.0 = 6.0% <= 10% -> very_similar
    assert comp.verdict == "very_similar"


def test_compute_variable_comparison_divergent():
    periods = ["2020-01", "2020-02", "2020-03", "2020-04", "2020-05", "2020-06"]
    precs_a = [10.0, 20.0, 30.0, 40.0, 50.0, 60.0]
    precs_b = [100.0, 10.0, 90.0, 5.0, 80.0, 0.0]
    records_a = [_make_record(p, prec=v) for p, v in zip(periods, precs_a)]
    records_b = [_make_record(p, prec=v) for p, v in zip(periods, precs_b)]

    comp = compute_variable_comparison(
        records_a=records_a,
        records_b=records_b,
        attr_name="precipitation_sum_mm",
        variable_label="Precipitation sum (mm)",
        compare_kind="climate",
        source_a_name="Source A",
        source_b_name="Source B",
    )

    assert comp is not None
    assert comp.verdict == "clearly_different"


def test_compute_variable_comparison_too_few_points():
    periods = ["2020-01", "2020-02", "2020-03"]
    temps = [25.0, 26.0, 27.0]
    records_a = [_make_record(p, temp=t) for p, t in zip(periods, temps)]
    records_b = [_make_record(p, temp=t) for p, t in zip(periods, temps)]

    comp = compute_variable_comparison(
        records_a=records_a,
        records_b=records_b,
        attr_name="temperature_mean_c",
        variable_label="Mean temperature (°C)",
        compare_kind="climate",
        source_a_name="Source A",
        source_b_name="Source B",
    )

    assert comp is not None
    assert comp.overlap_periods == 3
    assert comp.too_few_points is True
    assert comp.verdict == "too_few_points"
    assert "Too few overlapping points" in comp.verdict_explanation


def test_compute_variable_comparison_cases_note():
    periods = ["2020-01", "2020-02", "2020-03", "2020-04", "2020-05", "2020-06"]
    cases_a = [10, 20, 30, 40, 50, 60]
    cases_b = [12, 22, 32, 42, 52, 62]
    records_a = [_make_record(p, cases=c) for p, c in zip(periods, cases_a)]
    records_b = [_make_record(p, cases=c) for p, c in zip(periods, cases_b)]

    comp = compute_variable_comparison(
        records_a=records_a,
        records_b=records_b,
        attr_name="case_count",
        variable_label="Case count",
        compare_kind="cases",
        source_a_name="Primary Cases",
        source_b_name="Alternative Cases",
    )

    assert comp is not None
    # Seasonal cycle sentence must NOT be in case comparison
    assert "shared seasonal cycle" not in comp.verdict_explanation
    # Case definition note must be present
    assert "Case definitions" in comp.verdict_explanation


def test_source_comparison_request_model():
    req = SourceComparisonRequest(
        disease="dengue",
        region="Thailand",
        start_date="2020-01-01",
        end_date="2020-06-30",
        aggregation="native",
        compare_kind="climate",
        climate_source="open-meteo-era5",
        alternative_climate_source="nasa-power",
    )
    assert req.aggregation == "native"
    assert req.compare_kind == "climate"
    assert req.climate_source == "open-meteo-era5"
    assert req.alternative_climate_source == "nasa-power"


def test_compute_variable_comparison_constant_series_has_no_r():
    """A constant series has no defined Pearson r; no invented r = 0 / p = 1."""
    periods = [f"2020-{m:02d}" for m in range(1, 9)]
    a = [PeriodRecord(period=p, temperature_mean_c=25.0) for p in periods]
    b = [PeriodRecord(period=p, temperature_mean_c=25.0 + i) for i, p in enumerate(periods)]
    res = compute_variable_comparison(a, b, "temperature_mean_c", "Temperature (mean)",
                                      "climate", "A", "B")
    assert res.pearson_r is None
    assert res.p_value is None
    assert res.formatted_p_value == "p=n/a"
    assert res.verdict == "clearly_different"


def test_compute_variable_comparison_zero_baseline_has_no_relative_mad():
    """Relative MAD is undefined when the baseline averages ~0 (dry period)."""
    periods = [f"2020-{m:02d}" for m in range(1, 9)]
    a = [PeriodRecord(period=p, precipitation_sum_mm=0.0) for p in periods]
    b = [PeriodRecord(period=p, precipitation_sum_mm=0.0) for p in periods]
    res = compute_variable_comparison(a, b, "precipitation_sum_mm", "Precipitation (sum)",
                                      "climate", "A", "B")
    assert res.relative_mean_absolute_difference_percent is None
    assert res.verdict == "very_similar"
