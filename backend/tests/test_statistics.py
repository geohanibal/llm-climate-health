"""Unit tests for the epidemiological statistics and lagged correlation module.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

import pandas as pd
import pytest

from app.models import PeriodRecord
from app.services.statistics import (
    compute_bivariate_stats,
    compute_lagged_correlations,
    compute_statistics,
)


def test_bivariate_stats_returns_none_on_small_sample():
    x = pd.Series([1.0, 2.0])
    y = pd.Series([10.0, 20.0])
    pr, pp, sr, sp, n = compute_bivariate_stats(x, y)
    assert pr is None
    assert n == 2


def test_bivariate_stats_computes_perfect_correlation():
    x = pd.Series([1.0, 2.0, 3.0, 4.0, 5.0])
    y = pd.Series([2.0, 4.0, 6.0, 8.0, 10.0])
    pr, pp, sr, sp, n = compute_bivariate_stats(x, y)
    assert pr == 1.0
    assert pp is not None and pp < 0.01
    assert sr == 1.0
    assert sp is not None and sp < 0.01
    assert n == 5


def test_bivariate_stats_handles_zero_variance():
    x = pd.Series([5.0, 5.0, 5.0, 5.0])
    y = pd.Series([1.0, 2.0, 3.0, 4.0])
    pr, pp, sr, sp, n = compute_bivariate_stats(x, y)
    assert pr is None
    assert n == 4


def test_lagged_correlations_identifies_lagged_signal():
    # Construct a dataset where climate at t leads disease at t+1:
    # rain: [100, 200, 300, 400, 500, 100, 200, 300]
    # cases: [ 10, 100, 200, 300, 400, 500, 100, 200]
    rain = [100, 200, 300, 400, 500, 100, 200, 300]
    cases = [10, 100, 200, 300, 400, 500, 100, 200]
    df = pd.DataFrame({"precipitation_sum_mm": rain, "case_count": cases})

    metrics = compute_lagged_correlations(
        df,
        climate_col="precipitation_sum_mm",
        target_col="case_count",
        variable_name="precipitation",
        max_lag=2,
    )
    assert len(metrics) == 3  # lag 0, lag 1, lag 2
    # At lag 1, rain(t-1) aligns with cases(t), so correlation should be near 1.0
    lag1 = next(m for m in metrics if m.lag_periods == 1)
    assert lag1.pearson_r is not None
    assert lag1.pearson_r > 0.9
    assert lag1.significant is True


def test_compute_statistics_empty():
    stat = compute_statistics([], "month")
    assert stat.sample_size == 0
    assert len(stat.correlations) == 0


def test_compute_statistics_detects_peak_and_means():
    records = [
        PeriodRecord(period="2020-01", case_count=100, population=100000, incidence_rate_per_100k=100.0, temperature_mean_c=25.0, precipitation_sum_mm=50.0),
        PeriodRecord(period="2020-02", case_count=500, population=100000, incidence_rate_per_100k=500.0, temperature_mean_c=28.0, precipitation_sum_mm=200.0),
        PeriodRecord(period="2020-03", case_count=200, population=100000, incidence_rate_per_100k=200.0, temperature_mean_c=27.0, precipitation_sum_mm=100.0),
        PeriodRecord(period="2020-04", case_count=50, population=100000, incidence_rate_per_100k=50.0, temperature_mean_c=24.0, precipitation_sum_mm=20.0),
    ]
    stat = compute_statistics(records, "month")
    assert stat.sample_size == 4
    assert stat.peak_period == "2020-02"
    assert stat.peak_cases == 500.0
    assert stat.peak_incidence_per_100k == 500.0
    assert stat.total_cases == 850.0
    assert stat.mean_temperature_c == 26.0
    assert stat.mean_precipitation_mm == 92.5
    assert len(stat.correlations) > 0
    assert "Methodological Note" in stat.scientific_disclaimer
