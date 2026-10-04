"""Climate (reanalysis) data access: Open-Meteo (ERA5) and NASA POWER.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

from datetime import date

import pandas as pd
import requests

from app.config import REGIONS

OPEN_METEO_URL = "https://archive-api.open-meteo.com/v1/archive"
NASA_POWER_URL = "https://power.larc.nasa.gov/api/temporal/daily/point"

OPEN_METEO_FIELDS = {
    "temperature": "temperature_2m_mean",
    "precipitation": "precipitation_sum",
}
NASA_POWER_FIELDS = {
    "temperature": "T2M",
    "precipitation": "PRECTOTCORR",
}


def _period_key(dt: pd.Series, resolution: str) -> pd.Series:
    if resolution == "decade":
        return (dt.dt.year // 10 * 10).astype(str) + "s"
    if resolution == "year":
        return dt.dt.strftime("%Y")
    if resolution == "day":
        return dt.dt.strftime("%Y-%m-%d")
    return dt.dt.strftime("%Y-%m")


TEMP_ALIASES = [
    "temperature_2m_mean",
    "temperature_mean_c",
    "temperature",
    "temp",
    "t2m",
    "tmean",
    "temp_mean",
    "air_temp",
    "air_temperature",
]
PRECIP_ALIASES = [
    "precipitation_sum",
    "precipitation_sum_mm",
    "precipitation",
    "precip",
    "rain",
    "rainfall",
    "prcp",
    "prectotcorr",
]
DATE_ALIASES = [
    "date",
    "time",
    "period",
    "datetime",
    "timestamp",
    "day",
    "month",
    "year",
]


def _find_matching_column(columns: list[str], aliases: list[str]) -> str | None:
    col_map = {str(c).lower().strip(): str(c) for c in columns}
    # Exact match first
    for alias in aliases:
        if alias in col_map:
            return col_map[alias]
    # Substring match second
    for col_clean, orig_col in col_map.items():
        for alias in aliases:
            if alias in col_clean:
                return orig_col
    return None


def fetch_custom_upload_climate(
    content: bytes,
    variables: list[str],
    start: date,
    end: date,
    resolution: str = "month",
) -> pd.DataFrame:
    """Parses a user-supplied meteorological station CSV dataset (with date,
    temperature, and/or precipitation columns) and aligns it to the target
    temporal resolution."""
    import io

    try:
        raw = pd.read_csv(io.BytesIO(content), on_bad_lines="skip")
    except Exception:
        raw = pd.read_csv(io.BytesIO(content), sep=None, engine="python", on_bad_lines="skip")

    cols = list(raw.columns)
    date_col = _find_matching_column(cols, DATE_ALIASES)
    if not date_col:
        raise ValueError(
            f"Could not find a date/time column in the uploaded weather CSV (columns: {cols}). "
            "Please include a column named 'date', 'time', or 'period'."
        )

    temp_col = _find_matching_column(cols, TEMP_ALIASES) if "temperature" in variables else None
    precip_col = _find_matching_column(cols, PRECIP_ALIASES) if "precipitation" in variables else None

    if not temp_col and not precip_col:
        raise ValueError(
            f"Could not find recognizable weather columns (temperature or precipitation) in uploaded CSV (columns: {cols}). "
            "Expected columns such as 'temperature', 'temp', 'precipitation', 'rain'."
        )

    raw["time"] = pd.to_datetime(raw[date_col], errors="coerce")
    valid = raw.dropna(subset=["time"]).copy()

    # Filter date range
    mask = (valid["time"].dt.date >= start) & (valid["time"].dt.date <= end)
    filtered = valid.loc[mask].copy()
    if filtered.empty:
        res_cols = ["period"]
        if temp_col:
            res_cols.append("temperature_2m_mean")
        if precip_col:
            res_cols.append("precipitation_sum")
        return pd.DataFrame(columns=res_cols)

    filtered["period"] = _period_key(filtered["time"], resolution)

    agg = {}
    if temp_col:
        filtered["temperature_2m_mean"] = pd.to_numeric(filtered[temp_col], errors="coerce")
        agg["temperature_2m_mean"] = "mean"
    if precip_col:
        filtered["precipitation_sum"] = pd.to_numeric(filtered[precip_col], errors="coerce")
        agg["precipitation_sum"] = lambda s: s.sum(min_count=1)

    grouped = filtered.groupby("period", as_index=False).agg(agg)
    return grouped.round(2)


def _fetch_open_meteo_daily(lat: float, lon: float, variables: list[str], start: date, end: date):
    daily_fields = [OPEN_METEO_FIELDS[v] for v in variables]
    resp = requests.get(
        OPEN_METEO_URL,
        params={
            "latitude": lat,
            "longitude": lon,
            "start_date": start.isoformat(),
            "end_date": end.isoformat(),
            "daily": ",".join(daily_fields),
            # Fixed, not "auto": "auto" resolves a per-point local timezone,
            # which shifts which calendar day/month a reading near a day
            # boundary falls into depending on the region — UTC keeps every
            # region's periods aligned to the same, deterministic boundary.
            "timezone": "UTC",
        },
        timeout=30,
    )
    resp.raise_for_status()
    payload = resp.json()["daily"]
    df = pd.DataFrame(payload)
    df["time"] = pd.to_datetime(df["time"])
    return df


def _fetch_nasa_power_daily(lat: float, lon: float, variables: list[str], start: date, end: date):
    params_list = [NASA_POWER_FIELDS[v] for v in variables]
    resp = requests.get(
        NASA_POWER_URL,
        params={
            "parameters": ",".join(params_list),
            "community": "AG",
            "longitude": lon,
            "latitude": lat,
            "start": start.strftime("%Y%m%d"),
            "end": end.strftime("%Y%m%d"),
            "format": "JSON",
        },
        timeout=30,
    )
    resp.raise_for_status()
    series = resp.json()["properties"]["parameter"]

    df = pd.DataFrame({param: pd.Series(values) for param, values in series.items()})
    df.index = pd.to_datetime(df.index, format="%Y%m%d")
    df = df.replace(-999.0, pd.NA)
    df = df.rename(columns={"T2M": "temperature_2m_mean", "PRECTOTCORR": "precipitation_sum"})
    df["time"] = df.index
    return df.reset_index(drop=True)


def fetch_climate(
    region: str,
    variables: list[str],
    start: date,
    end: date,
    source: str = "open-meteo-era5",
    resolution: str = "month",
    upload_content: bytes | None = None,
) -> pd.DataFrame:
    """Fetch daily reanalysis-based or user-uploaded climate data for a region's reference
    point and aggregate to the requested resolution ("day", "month", or "year"):
    temperature as the period mean, precipitation as the period sum."""
    if source == "custom_upload":
        if not upload_content:
            raise ValueError("No uploaded file provided for climate data source 'custom_upload'.")
        return fetch_custom_upload_climate(upload_content, variables, start, end, resolution)

    coords = REGIONS[region]
    if source == "nasa-power":
        daily = _fetch_nasa_power_daily(coords["lat"], coords["lon"], variables, start, end)
    else:
        daily = _fetch_open_meteo_daily(coords["lat"], coords["lon"], variables, start, end)

    daily["period"] = _period_key(daily["time"], resolution)

    agg = {}
    if "temperature_2m_mean" in daily.columns:
        agg["temperature_2m_mean"] = "mean"
    if "precipitation_sum" in daily.columns:
        # min_count=1 makes an all-missing period sum to NaN instead of 0 —
        # a real zero-rainfall reading must stay distinguishable from "no
        # data for this period" (e.g. NASA POWER's -999.0 sentinel, already
        # replaced with NA above).
        agg["precipitation_sum"] = lambda s: s.sum(min_count=1)

    grouped = daily.groupby("period", as_index=False).agg(agg)
    return grouped.round(2)
