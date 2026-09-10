"""Statistical and cross-correlation analysis for climate-health time series.

Provides:
  - Pearson r and Spearman rho correlations with two-tailed p-values.
  - Cross-correlation across temporal lags (Lag 0 to 3) to capture delayed
    epidemiological effects (e.g. mosquito breeding cycles following rainfall).
  - Summary metrics: peak outbreak periods, incidence rates, and series means.
  - Methodological disclaimers for academic researchers (single-point vs spatial).

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

from typing import Sequence
import numpy as np
import pandas as pd
from scipy import stats

from app.models import CorrelationMetric, PeriodRecord, StatisticalSummary

SCIENTIFIC_DISCLAIMER = (
    "Methodological Note for Researchers: Climate indicators are derived from "
    "a single representative point coordinate (reanalysis centroid). Intended for "
    "exploratory data analysis (EDA) and input data preparation; causal epidemiological "
    "inference requires subnational spatial disaggregation (Admin-1/Province) "
    "and adjustment for unmeasured confounders."
)


def _safe_float(val) -> float | None:
    if val is None or pd.isna(val) or np.isinf(val):
        return None
    return round(float(val), 4)


def compute_bivariate_stats(x: pd.Series, y: pd.Series) -> tuple[float | None, float | None, float | None, float | None, int]:
    """Computes (pearson_r, pearson_p, spearman_rho, spearman_p, valid_n)
    for two series, dropping missing values and checking for zero variance."""
    paired = pd.DataFrame({"x": pd.to_numeric(x, errors="coerce"), "y": pd.to_numeric(y, errors="coerce")}).dropna()
    n = len(paired)
    if n < 3:
        return None, None, None, None, n

    x_clean = paired["x"].to_numpy()
    y_clean = paired["y"].to_numpy()

    # Zero variance in either variable prevents correlation calculation
    if np.all(x_clean == x_clean[0]) or np.all(y_clean == y_clean[0]):
        return None, None, None, None, n

    try:
        p_res = stats.pearsonr(x_clean, y_clean)
        pr = _safe_float(p_res.statistic)
        pp = _safe_float(p_res.pvalue)
    except Exception:
        pr, pp = None, None

    try:
        s_res = stats.spearmanr(x_clean, y_clean)
        s_rho = _safe_float(s_res.statistic)
        s_p = _safe_float(s_res.pvalue)
    except Exception:
        s_rho, s_p = None, None

    return pr, pp, s_rho, s_p, n


def compute_lagged_correlations(
    df: pd.DataFrame,
    climate_col: str,
    target_col: str,
    variable_name: str,
    max_lag: int = 3,
) -> list[CorrelationMetric]:
    """Computes cross-correlations where climate leads disease by `lag` periods:
    disease(t) vs climate(t - lag)."""
    metrics: list[CorrelationMetric] = []
    if climate_col not in df.columns or target_col not in df.columns:
        return metrics

    for lag in range(max_lag + 1):
        if lag == 0:
            clim_lagged = df[climate_col]
        else:
            clim_lagged = df[climate_col].shift(lag)

        pr, pp, s_rho, s_p, n = compute_bivariate_stats(clim_lagged, df[target_col])
        sig = False
        if pp is not None and pp < 0.05:
            sig = True
        elif s_p is not None and s_p < 0.05:
            sig = True

        metrics.append(
            CorrelationMetric(
                variable=variable_name,
                lag_periods=lag,
                pearson_r=pr,
                pearson_p=pp,
                spearman_rho=s_rho,
                spearman_p=s_p,
                significant=sig,
                sample_size=n,
            )
        )

    return metrics


def compute_statistics(records: Sequence[PeriodRecord], resolution: str) -> StatisticalSummary:
    """Calculates comprehensive epidemiological and statistical metrics across
    the joined records."""
    if not records:
        return StatisticalSummary(
            sample_size=0,
            correlations=[],
            scientific_disclaimer=SCIENTIFIC_DISCLAIMER,
        )

    rows = []
    for r in records:
        rows.append(
            {
                "period": r.period,
                "case_count": r.case_count,
                "incidence_rate_per_100k": r.incidence_rate_per_100k,
                "temperature_mean_c": r.temperature_mean_c,
                "precipitation_sum_mm": r.precipitation_sum_mm,
            }
        )
    df = pd.DataFrame(rows)
    sample_size = len(df)

    # Determine metric target: prefer incidence_rate_per_100k if populated, else case_count
    has_incidence = df["incidence_rate_per_100k"].dropna().count() >= 3
    target_col = "incidence_rate_per_100k" if has_incidence else "case_count"

    # Lags: monthly resolution supports up to 3-period lag (1-3 months).
    # Yearly supports lag 0 and 1. Decadal supports only lag 0.
    if resolution == "month":
        max_lag = 3
    elif resolution == "year":
        max_lag = 1
    else:
        max_lag = 0

    correlations: list[CorrelationMetric] = []
    if "temperature_mean_c" in df.columns:
        correlations.extend(
            compute_lagged_correlations(df, "temperature_mean_c", target_col, "temperature", max_lag=max_lag)
        )
    if "precipitation_sum_mm" in df.columns:
        correlations.extend(
            compute_lagged_correlations(df, "precipitation_sum_mm", target_col, "precipitation", max_lag=max_lag)
        )

    # Aggregate summaries
    total_cases = _safe_float(df["case_count"].dropna().sum()) if df["case_count"].dropna().count() > 0 else None
    mean_temp = _safe_float(df["temperature_mean_c"].dropna().mean()) if df["temperature_mean_c"].dropna().count() > 0 else None
    mean_precip = _safe_float(df["precipitation_sum_mm"].dropna().mean()) if df["precipitation_sum_mm"].dropna().count() > 0 else None

    # Peak outbreak identification
    peak_period = None
    peak_cases = None
    peak_incidence = None
    valid_cases = df.dropna(subset=["case_count"])
    if not valid_cases.empty:
        peak_row = valid_cases.loc[valid_cases["case_count"].idxmax()]
        peak_period = str(peak_row["period"])
        peak_cases = _safe_float(peak_row["case_count"])
        peak_incidence = _safe_float(peak_row.get("incidence_rate_per_100k"))

    return StatisticalSummary(
        sample_size=sample_size,
        correlations=correlations,
        peak_period=peak_period,
        peak_cases=peak_cases,
        peak_incidence_per_100k=peak_incidence,
        mean_temperature_c=mean_temp,
        mean_precipitation_mm=mean_precip,
        total_cases=total_cases,
        scientific_disclaimer=SCIENTIFIC_DISCLAIMER,
    )
