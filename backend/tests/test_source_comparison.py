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


from unittest.mock import patch
import pandas as pd
from app.services.source_comparison import compare_sources


@patch("app.services.etl.fetch_climate")
@patch("app.services.etl.fetch_who_gho_case_data")
def test_compare_sources_who_gho_complete_years_only(mock_who, mock_climate):
    """WHO GHO comparison only includes complete years (all 12 months present in source A).
    A partial year (e.g. 2010 starting in March) is excluded and reported in excluded_years."""
    def fake_climate(*args, **kwargs):
        # Return yearly climate
        return pd.DataFrame({
            "period": ["2010", "2011", "2012"],
            "temperature_2m_mean": [28.0, 28.5, 29.0],
            "precipitation_sum": [1500.0, 1600.0, 1550.0],
        })
    mock_climate.side_effect = fake_climate

    # WHO returns annual counts for 2010, 2011, 2012
    mock_who.return_value = pd.DataFrame({
        "period_start": pd.to_datetime(["2010-01-01", "2011-01-01", "2012-01-01"]),
        "value": [50000.0, 60000.0, 70000.0],
    })

    req = SourceComparisonRequest(
        disease="dengue",
        region="Thailand",
        start_date="2010-03-01",
        end_date="2012-12-31",
        aggregation="native",
        compare_kind="cases",
        case_data_source="builtin",
        alternative_case_data_source="who_gho",
        alternative_who_indicator_code="DENGUE_ANNUAL",
    )

    res = compare_sources(req)
    assert res.compared_at_yearly_resolution is True
    assert res.resolution == "year"
    # 2010 only has 10 months (March to Dec) -> excluded!
    assert "2010" in res.excluded_years
    assert len(res.variables) == 1
    comp = res.variables[0]
    # Only 2011 and 2012 are compared
    assert comp.overlap_periods == 2
    assert comp.too_few_points is True


@patch("app.services.etl.fetch_climate")
def test_compare_sources_case_upload_source_b(mock_climate):
    """Comparison against an uploaded case CSV works and passes file bytes to Source B."""
    def fake_climate(*args, **kwargs):
        return pd.DataFrame({
            "period": ["2020-01", "2020-02", "2020-03", "2020-04", "2020-05", "2020-06"],
            "temperature_2m_mean": [25.0, 26.0, 27.0, 28.0, 29.0, 30.0],
            "precipitation_sum": [10.0, 15.0, 20.0, 25.0, 30.0, 35.0],
        })
    mock_climate.side_effect = fake_climate

    csv_bytes = b"date,cases\n2020-01-01,100\n2020-02-01,120\n2020-03-01,150\n2020-04-01,180\n2020-05-01,210\n2020-06-01,250\n"

    req = SourceComparisonRequest(
        disease="dengue",
        region="Thailand",
        start_date="2020-01-01",
        end_date="2020-06-30",
        aggregation="native",
        compare_kind="cases",
        case_data_source="builtin",
        alternative_case_data_source="custom_upload",
    )

    res = compare_sources(req, upload_file_b_bytes=csv_bytes)
    assert res.compare_kind == "cases"
    assert "Uploaded CSV" in res.source_b_label
    assert len(res.variables) == 1
    assert res.variables[0].overlap_periods == 6


@patch("app.services.etl.fetch_climate")
def test_compare_sources_climate_upload_source_b(mock_climate):
    """Comparison against an uploaded climate CSV works and passes bytes to Source B."""
    def fake_climate(*args, **kwargs):
        return pd.DataFrame({
            "period": ["2020-01", "2020-02", "2020-03", "2020-04", "2020-05", "2020-06"],
            "temperature_2m_mean": [25.0, 26.0, 27.0, 28.0, 29.0, 30.0],
            "precipitation_sum": [10.0, 15.0, 20.0, 25.0, 30.0, 35.0],
        })
    mock_climate.side_effect = fake_climate

    csv_bytes = b"date,temperature,precipitation\n2020-01-01,25.5,12.0\n2020-02-01,26.5,16.0\n2020-03-01,27.5,21.0\n2020-04-01,28.5,26.0\n2020-05-01,29.5,31.0\n2020-06-01,30.5,36.0\n"

    req = SourceComparisonRequest(
        disease="dengue",
        region="Thailand",
        start_date="2020-01-01",
        end_date="2020-06-30",
        aggregation="native",
        compare_kind="climate",
        climate_source="open-meteo-era5",
        alternative_climate_source="custom_upload",
    )

    res = compare_sources(req, upload_file_b_bytes=csv_bytes)
    assert res.compare_kind == "climate"
    assert "Uploaded CSV" in res.source_b_label
    assert len(res.variables) >= 1


def test_to_complete_years_keeps_only_full_years():
    """Monthly and daily inputs: only years with every period present are summed."""
    from app.services.source_comparison import to_complete_years

    monthly = [PeriodRecord(period=f"2011-{m:02d}", case_count=10.0) for m in range(1, 13)]
    monthly += [PeriodRecord(period=f"2012-{m:02d}", case_count=10.0) for m in range(1, 12)]
    yearly, excluded = to_complete_years(monthly, "month", 2011, 2012)
    assert [(r.period, r.case_count) for r in yearly] == [("2011", 120.0)]
    assert excluded == ["2012"]

    daily = [PeriodRecord(period=f"2012-01-{d:02d}", case_count=1.0) for d in range(1, 32)]
    yearly, excluded = to_complete_years(daily, "day", 2012, 2012)
    assert yearly == [] and excluded == ["2012"]


@patch("app.services.etl.fetch_climate")
@patch("app.services.etl.fetch_who_gho_case_data")
def test_compare_sources_who_as_source_a_applies_complete_years_to_b(mock_who, mock_climate):
    """If the main request used WHO GHO (A) and B is a monthly upload, B's
    partial years must also be excluded, not summed."""
    mock_climate.side_effect = lambda *a, **k: pd.DataFrame({
        "period": ["2011", "2012"],
        "temperature_2m_mean": [28.0, 28.5],
        "precipitation_sum": [1500.0, 1600.0],
    })
    mock_who.return_value = pd.DataFrame({
        "period_start": pd.to_datetime(["2011-01-01", "2012-01-01"]),
        "value": [1200.0, 1300.0],
    })
    rows = ["date,cases"] + [f"2011-{m:02d}-01,100" for m in range(1, 13)]
    rows += [f"2012-{m:02d}-01,100" for m in range(1, 7)]  # 2012: only Jan–Jun
    csv_bytes = ("\n".join(rows) + "\n").encode()

    req = SourceComparisonRequest(
        disease="dengue",
        region="Thailand",
        start_date="2011-01-01",
        end_date="2012-12-31",
        compare_kind="cases",
        case_data_source="who_gho",
        who_indicator_code="DENGUE_ANNUAL",
        alternative_case_data_source="custom_upload",
    )
    res = compare_sources(req, upload_file_b_bytes=csv_bytes)
    assert res.compared_at_yearly_resolution is True
    assert res.excluded_years == ["2012"]
    assert res.variables[0].overlap_periods == 1
