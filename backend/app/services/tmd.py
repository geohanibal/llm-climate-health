"""Thai Meteorological Department (TMD) climate data access — Thailand only.

NOTE: TMD's public API (data.tmd.go.th) requires a free registered uid/ukey
credential pair, and its documentation does not publish the exact JSON
response field names (only the endpoint names and that a `uid`/`ukey`
query-param pair is required). `_parse_tmd_response` below is written from
the documented endpoint descriptions and needs a live smoke test against a
real response once TMD_API_UID/TMD_API_UKEY are set — everything response-
shape-dependent is isolated in that one function so it's a single-place fix.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

from datetime import date

import pandas as pd
import requests

from app.config import TMD_API_UID, TMD_API_UKEY

TMD_MONTHLY_RAINFALL_URL = "http://data.tmd.go.th/api/ThailandMonthlyRainfall/v1/index.php"


def is_available() -> bool:
    return bool(TMD_API_UID and TMD_API_UKEY)


def _parse_tmd_response(payload: dict) -> pd.DataFrame:
    """Extracts (period, temperature_2m_mean, precipitation_sum) rows from a
    TMD API response. TMD's own docs describe the payload as station/year
    records with monthly rainfall totals; the exact key names below are a
    best guess from the documented field descriptions and must be verified
    against a real response (see module docstring)."""
    records = payload.get("Stations") or payload.get("data") or payload.get("Data")
    if not isinstance(records, list):
        raise RuntimeError(
            "Unexpected TMD API response shape (no 'Stations'/'data'/'Data' "
            "list found) — _parse_tmd_response needs updating against a real "
            "payload now that TMD_API_UID/TMD_API_UKEY are configured."
        )

    rows = []
    for record in records:
        year = record.get("year") or record.get("Year")
        month = record.get("month") or record.get("Month")
        rainfall = record.get("rainfall") or record.get("Rainfall")
        if year is None or month is None:
            continue
        rows.append(
            {
                "period": f"{int(year):04d}-{int(month):02d}",
                "precipitation_sum": float(rainfall) if rainfall is not None else None,
                "temperature_2m_mean": None,
            }
        )

    if not rows:
        raise RuntimeError(
            "TMD API response parsed but yielded no usable rows — "
            "_parse_tmd_response needs updating against a real payload."
        )
    return pd.DataFrame(rows)


def fetch_tmd_climate(
    region: str,
    variables: list[str],
    start: date,
    end: date,
    resolution: str = "month",
) -> pd.DataFrame:
    """Thailand-only historical climate data from TMD. `region` must be
    "Thailand" (enforced by the caller via CLIMATE_SOURCE_REGIONS)."""
    if not is_available():
        raise RuntimeError(
            "TMD_API_UID/TMD_API_UKEY are not configured — register for free "
            "at data.tmd.go.th and set them in the backend's .env."
        )

    resp = requests.get(
        TMD_MONTHLY_RAINFALL_URL,
        params={"uid": TMD_API_UID, "ukey": TMD_API_UKEY},
        timeout=30,
    )
    resp.raise_for_status()
    df = _parse_tmd_response(resp.json())

    mask = (df["period"] >= start.strftime("%Y-%m")) & (df["period"] <= end.strftime("%Y-%m"))
    df = df.loc[mask].reset_index(drop=True)

    if resolution == "year":
        df["period"] = df["period"].str.slice(0, 4)
        df = df.groupby("period", as_index=False).agg(
            temperature_2m_mean=("temperature_2m_mean", "mean"),
            precipitation_sum=("precipitation_sum", "sum"),
        )

    return df
