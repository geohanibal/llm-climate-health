"""Tests for gap detection and data coverage analysis (FR-26, A18)."""

from datetime import date
import pandas as pd
import pytest

from app.models import PeriodRecord
from app.services.coverage import analyze_data_coverage


def test_coverage_full_data():
    records = [
        PeriodRecord(period="2020-01", case_count=10, population=1000, incidence_rate_per_100k=1000.0, temperature_mean_c=25.0),
        PeriodRecord(period="2020-02", case_count=12, population=1000, incidence_rate_per_100k=1200.0, temperature_mean_c=26.0),
        PeriodRecord(period="2020-03", case_count=15, population=1000, incidence_rate_per_100k=1500.0, temperature_mean_c=27.0),
    ]
    covs, step = analyze_data_coverage(
        records=records,
        disease_key="dengue",
        region="Thailand",
        variables=["temperature"],
        case_data_source="builtin",
        climate_source="open-meteo-era5",
        population_source="worldbank",
        start_date=date(2020, 1, 1),
        end_date=date(2020, 3, 31),
        resolution="month",
    )
    assert len(covs) == 4  # case_count, population, incidence_rate_per_100k, temperature_mean_c
    cases_cov = next(c for c in covs if c.column == "case_count")
    assert cases_cov.total_periods == 3
    assert cases_cov.periods_with_value == 3
    assert cases_cov.missing_count == 0
    assert cases_cov.missing_percent == 0.0
    assert cases_cov.reason is None
    assert cases_cov.missing_ranges == []
    assert "all requested periods have data" in step.lower()


def test_coverage_gaps_inside_source():
    records = [
        PeriodRecord(period="2020-01", case_count=10, population=1000, incidence_rate_per_100k=1000.0, temperature_mean_c=25.0),
        PeriodRecord(period="2020-02", case_count=None, population=1000, incidence_rate_per_100k=None, temperature_mean_c=26.0),
        PeriodRecord(period="2020-03", case_count=15, population=1000, incidence_rate_per_100k=1500.0, temperature_mean_c=27.0),
    ]
    covs, step = analyze_data_coverage(
        records=records,
        disease_key="dengue",
        region="Thailand",
        variables=["temperature"],
        case_data_source="builtin",
        climate_source="open-meteo-era5",
        population_source="worldbank",
        start_date=date(2020, 1, 1),
        end_date=date(2020, 3, 31),
        resolution="month",
    )
    cases_cov = next(c for c in covs if c.column == "case_count")
    assert cases_cov.total_periods == 3
    assert cases_cov.periods_with_value == 2
    assert cases_cov.missing_count == 1
    assert cases_cov.missing_percent == 33.3
    assert cases_cov.reason == "gaps_inside_source"
    assert len(cases_cov.missing_ranges) == 1
    assert cases_cov.missing_ranges[0].start == "2020-02"
    assert cases_cov.missing_ranges[0].end == "2020-02"
    assert "case_count missing for 1 of 3 periods" in step


def test_coverage_outside_source_coverage():
    # Built-in Thailand dengue covers 2009-01 .. 2023-12.
    # Request covers 2008-10 .. 2009-03 (6 months, first 3 missing).
    records = [
        PeriodRecord(period="2008-10", case_count=None, population=1000, incidence_rate_per_100k=None, temperature_mean_c=25.0),
        PeriodRecord(period="2008-11", case_count=None, population=1000, incidence_rate_per_100k=None, temperature_mean_c=25.5),
        PeriodRecord(period="2008-12", case_count=None, population=1000, incidence_rate_per_100k=None, temperature_mean_c=26.0),
        PeriodRecord(period="2009-01", case_count=20, population=1000, incidence_rate_per_100k=2000.0, temperature_mean_c=26.5),
        PeriodRecord(period="2009-02", case_count=25, population=1000, incidence_rate_per_100k=2500.0, temperature_mean_c=27.0),
        PeriodRecord(period="2009-03", case_count=30, population=1000, incidence_rate_per_100k=3000.0, temperature_mean_c=27.5),
    ]
    covs, step = analyze_data_coverage(
        records=records,
        disease_key="dengue",
        region="Thailand",
        variables=["temperature"],
        case_data_source="builtin",
        climate_source="open-meteo-era5",
        population_source="worldbank",
        start_date=date(2008, 10, 1),
        end_date=date(2009, 3, 31),
        resolution="month",
    )
    cases_cov = next(c for c in covs if c.column == "case_count")
    assert cases_cov.missing_count == 3
    assert cases_cov.missing_percent == 50.0
    assert cases_cov.reason == "outside_source_coverage"
    assert cases_cov.first_available == "2009-01"
    assert cases_cov.last_available == "2009-03"
    assert len(cases_cov.missing_ranges) == 1
    assert cases_cov.missing_ranges[0].start == "2008-10"
    assert cases_cov.missing_ranges[0].end == "2008-12"
    assert cases_cov.available_range == {"start": "2009-01", "end": "2025-03"}


def test_coverage_not_provided_by_source():
    # TMD source does not deliver temperature
    records = [
        PeriodRecord(period="2020-01", case_count=10, population=1000, incidence_rate_per_100k=1000.0, temperature_mean_c=None),
        PeriodRecord(period="2020-02", case_count=12, population=1000, incidence_rate_per_100k=1200.0, temperature_mean_c=None),
    ]
    covs, step = analyze_data_coverage(
        records=records,
        disease_key="dengue",
        region="Thailand",
        variables=["temperature"],
        case_data_source="builtin",
        climate_source="tmd",
        population_source="worldbank",
        start_date=date(2020, 1, 1),
        end_date=date(2020, 2, 28),
        resolution="month",
    )
    temp_cov = next(c for c in covs if c.column == "temperature_mean_c")
    assert temp_cov.missing_count == 2
    assert temp_cov.missing_percent == 100.0
    assert temp_cov.reason == "not_provided_by_source"
    assert temp_cov.first_available is None


def test_coverage_multiple_missing_ranges():
    records = [
        PeriodRecord(period="2020-01", case_count=10, population=1000, incidence_rate_per_100k=1000.0, temperature_mean_c=25.0),
        PeriodRecord(period="2020-02", case_count=None, population=1000, incidence_rate_per_100k=None, temperature_mean_c=26.0),
        PeriodRecord(period="2020-03", case_count=None, population=1000, incidence_rate_per_100k=None, temperature_mean_c=27.0),
        PeriodRecord(period="2020-04", case_count=15, population=1000, incidence_rate_per_100k=1500.0, temperature_mean_c=28.0),
        PeriodRecord(period="2020-05", case_count=None, population=1000, incidence_rate_per_100k=None, temperature_mean_c=29.0),
        PeriodRecord(period="2020-06", case_count=18, population=1000, incidence_rate_per_100k=1800.0, temperature_mean_c=30.0),
    ]
    covs, step = analyze_data_coverage(
        records=records,
        disease_key="dengue",
        region="Thailand",
        variables=["temperature"],
        case_data_source="builtin",
        climate_source="open-meteo-era5",
        population_source="worldbank",
        start_date=date(2020, 1, 1),
        end_date=date(2020, 6, 30),
        resolution="month",
    )
    cases_cov = next(c for c in covs if c.column == "case_count")
    assert cases_cov.missing_count == 3
    assert cases_cov.missing_percent == 50.0
    assert len(cases_cov.missing_ranges) == 2
    assert cases_cov.missing_ranges[0].start == "2020-02"
    assert cases_cov.missing_ranges[0].end == "2020-03"
    assert cases_cov.missing_ranges[1].start == "2020-05"
    assert cases_cov.missing_ranges[1].end == "2020-05"
