"""Climate feature lag generation for time series modeling.

Enables creating lagged predictors (e.g. temperature_lag1, precipitation_lag3)
from climate series, as required by epidemiological models (Suttirat et al. 2026,
Lowe et al. 2021) to capture biological incubation and vector development delays.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

from datetime import date, timedelta
import pandas as pd


# Column name aliases to canonical base variable names
_CLIMATE_VAR_MAPPING = {
    "temperature_2m_mean": "temperature",
    "temperature_mean_c": "temperature",
    "temperature": "temperature",
    "temp": "temperature",
    "t2m": "temperature",
    "temperature_2m_min": "temperature_min",
    "temperature_min_c": "temperature_min",
    "temperature_min": "temperature_min",
    "temp_min": "temperature_min",
    "tmin": "temperature_min",
    "t_min": "temperature_min",
    "min_temp": "temperature_min",
    "min_temperature": "temperature_min",
    "temperature_2m_max": "temperature_max",
    "temperature_max_c": "temperature_max",
    "temperature_max": "temperature_max",
    "temp_max": "temperature_max",
    "tmax": "temperature_max",
    "t_max": "temperature_max",
    "max_temp": "temperature_max",
    "max_temperature": "temperature_max",
    "precipitation_sum": "precipitation",
    "precipitation_sum_mm": "precipitation",
    "precipitation": "precipitation",
    "precip": "precipitation",
    "rain": "precipitation",
    "rainfall": "precipitation",
    "prectotcorr": "precipitation",
}


def calculate_buffer_start_date(start_date: date, lag_periods: list[int], resolution: str) -> date:
    """Calculates the earlier start date required to fetch climate data
    so that lagged variables can be computed without dropping initial
    observations (Lowe et al. 2021).
    
    The buffer duration equals max(lag_periods) in units of the target resolution.
    """
    if not lag_periods:
        return start_date

    max_lag = max(lag_periods)
    if resolution == "month":
        year = start_date.year
        month = start_date.month - max_lag
        while month <= 0:
            month += 12
            year -= 1
        return date(year, month, 1)

    if resolution == "day":
        return start_date - timedelta(days=max_lag)

    if resolution == "year":
        return date(max(1, start_date.year - max_lag), 1, 1)

    if resolution == "decade":
        return date(max(1, start_date.year - max_lag * 10), 1, 1)

    return start_date


def _infer_resolution(period_series: pd.Series) -> str:
    """Infers temporal resolution from the string formatting of the period column."""
    clean = period_series.dropna().astype(str).str.strip()
    if clean.empty:
        return "month"
    sample = clean.iloc[0]
    if sample.endswith("s"):
        return "decade"
    if len(sample) == 4 and sample.isdigit():
        return "year"
    if len(sample) == 10 and sample[4] == "-" and sample[7] == "-":
        return "day"
    if len(sample) == 7 and sample[4] == "-":
        return "month"
    return "month"


def _build_complete_period_range(min_period: str, max_period: str, resolution: str) -> list[str]:
    """Generates an unbroken sequence of period labels between min_period and max_period
    for the specified resolution to detect missing observation intervals."""
    if resolution == "month":
        start_dt = pd.to_datetime(min_period + "-01")
        end_dt = pd.to_datetime(max_period + "-01")
        return pd.date_range(start_dt, end_dt, freq="MS").strftime("%Y-%m").tolist()

    if resolution == "day":
        start_dt = pd.to_datetime(min_period)
        end_dt = pd.to_datetime(max_period)
        return pd.date_range(start_dt, end_dt, freq="D").strftime("%Y-%m-%d").tolist()

    if resolution == "year":
        start_yr = int(min_period)
        end_yr = int(max_period)
        return [str(y) for y in range(start_yr, end_yr + 1)]

    if resolution == "decade":
        start_dec = int(min_period.rstrip("s"))
        end_dec = int(max_period.rstrip("s"))
        return [f"{d}s" for d in range(start_dec, end_dec + 1, 10)]

    return [min_period]


def add_lagged_climate_features(
    df: pd.DataFrame,
    lag_periods: list[int],
    resolution: str | None = None,
) -> pd.DataFrame:
    """Adds lagged climate features to a DataFrame.
    
    To avoid silently propagating older values across missing time intervals
    (e.g. if 2019-12 is absent, 2020-01 lag1 must be NaN, not 2019-11):
    1. Reindexes the series to the complete unbroken sequence of periods.
    2. Computes the lag shifts on that regular timeline (so missing periods yield NaN).
    3. Drops the placeholder rows that were added solely for reindexing.
    """
    if df.empty or not lag_periods or "period" not in df.columns:
        return df

    out = df.copy()
    out = out.sort_values("period").reset_index(drop=True)

    # Detect which columns are climate variables
    detected_vars: dict[str, str] = {}  # source_col -> base_name
    for col in out.columns:
        col_lower = str(col).lower()
        if col_lower in _CLIMATE_VAR_MAPPING:
            detected_vars[col] = _CLIMATE_VAR_MAPPING[col_lower]

    if not detected_vars:
        return out

    res = resolution or _infer_resolution(out["period"])
    original_periods = out["period"].tolist()
    min_p = original_periods[0]
    max_p = original_periods[-1]

    try:
        full_periods = _build_complete_period_range(min_p, max_p, res)
    except Exception:
        # Fallback to direct series if parsing unexpected custom period format
        full_periods = original_periods

    # Set period as index and reindex to the complete unbroken timeline
    reindexed = out.set_index("period").reindex(full_periods)

    # Generate lag columns by shifting on the regular unbroken timeline
    for lag in sorted(lag_periods):
        for src_col, base_var in detected_vars.items():
            lag_col = f"{base_var}_lag{lag}"
            reindexed[lag_col] = reindexed[src_col].shift(lag)

    # Retain only the rows that were present in the original dataset
    result = reindexed.loc[reindexed.index.isin(original_periods)].reset_index()
    return result
