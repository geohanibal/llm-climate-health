"""Unit tests for the epidemiological statistics and lagged correlation module.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

import pandas as pd
import pytest

from app.models import PeriodRecord
from app.services.statistics import (
    MIN_PAIRS_FOR_SIGNIFICANCE,
    compute_bivariate_stats,
    compute_lagged_correlations,
    compute_statistics,
    is_significant,
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
    # Construct a dataset where climate at t leads disease at t+1 (cases are
    # rain shifted by one period). 14 points -> 13 pairs at lag 1, enough
    # for the significance rule (MIN_PAIRS_FOR_SIGNIFICANCE).
    rain = [100, 200, 300, 400, 500, 100, 200, 300, 450, 150, 350, 250, 50, 400]
    cases = [10] + rain[:-1]
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


def test_tiny_samples_are_never_labelled_significant():
    """Regression (found 2026-11-01, Thailand 2010-01..06): with 3 pairs
    Spearman rho = 1 gives p = 0.0, which used to mark lag 3 as
    "significant" although Pearson p was 0.25."""
    df = pd.DataFrame(
        {"temperature_mean_c": [26.3, 29.4, 30.6, 32.3, 32.3, 30.8], "case_count": [1496, 1528, 2020, 1868, 3666, 6631]}
    )
    metrics = compute_lagged_correlations(df, "temperature_mean_c", "case_count", "temperature", max_lag=3)
    lag3 = next(m for m in metrics if m.lag_periods == 3)
    assert lag3.sample_size == 3
    assert lag3.spearman_p == 0.0
    assert lag3.significant is False
    assert not any(m.significant for m in metrics)


def test_significance_requires_both_tests_and_enough_pairs():
    assert is_significant(0.01, 0.02, MIN_PAIRS_FOR_SIGNIFICANCE) is True
    assert is_significant(0.01, 0.02, MIN_PAIRS_FOR_SIGNIFICANCE - 1) is False
    assert is_significant(0.20, 0.01, 50) is False  # only Spearman supports it
    assert is_significant(0.01, 0.20, 50) is False  # only Pearson supports it
    assert is_significant(None, 0.01, 50) is False


def test_format_p_value_never_prints_zero():
    """A rounded "p=0.0" would suggest p is exactly zero; use the same
    "p<0.001" convention as the frontend card and the PDF."""
    from app.services.statistics import format_p_value

    assert format_p_value(0.0) == "p<0.001"
    assert format_p_value(0.00004) == "p<0.001"
    assert format_p_value(0.0238) == "p=0.024"
    assert format_p_value(None) == "p=n/a"
