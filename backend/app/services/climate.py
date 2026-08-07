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
    if resolution == "year":
        return dt.dt.strftime("%Y")
    return dt.dt.strftime("%Y-%m")


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
            "timezone": "auto",
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
) -> pd.DataFrame:
    """Fetch daily reanalysis-based climate data for a region's reference
    point and aggregate to the requested resolution ("month" or "year"):
    temperature as the period mean, precipitation as the period sum."""
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
        agg["precipitation_sum"] = "sum"

    grouped = daily.groupby("period", as_index=False).agg(agg)
    return grouped.round(2)
