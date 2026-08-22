"""Thai Meteorological Department (TMD) climate data access — Thailand only.

Verified 2026-08-23 against a live response, using TMD's own published demo
credentials (uid=demo, ukey=demokey — no registration needed for this tier).
Three things the docs don't mention, discovered from the real payload:
  - The response is XML, not JSON.
  - TMD's own <Latitude>/<Longitude> tags are swapped: <Latitude> holds the
    station's longitude and <Longitude> holds its latitude (confirmed
    across every station in a live response — e.g. Chiang Mai's real
    ~18.8°N latitude comes back under <Longitude>). Corrected explicitly in
    _parse_tmd_response rather than "fixed" by renaming, so it stays
    obvious this is TMD's data quirk, not a bug in this parser.
  - The demo tier only ever returns the current (in-progress) year,
    regardless of any year/date query parameter tried — a registered
    (non-demo) account may unlock historical years; unverified without one.
    Months later than today, within that current year, come back as a
    placeholder 0 rather than being omitted — treated as "not reported
    yet" (dropped) rather than "zero rainfall" below.
  - The server occasionally emits the entire document twice, concatenated
    ("junk after document element" from the XML parser) — seen live,
    intermittently, on an otherwise-identical repeated request. Handled by
    retrying the parse against just the first copy before giving up.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

import xml.etree.ElementTree as ET
from datetime import date

import pandas as pd
import requests

from app.config import REGIONS, TMD_API_UID, TMD_API_UKEY

TMD_MONTHLY_RAINFALL_URL = "https://data.tmd.go.th/api/ThailandMonthlyRainfall/v1/index.php"

_ROOT_CLOSE_TAG = "</ThailandMonthlyRainfall>"

_MONTH_TAGS = [
    ("JAN", 1), ("FEB", 2), ("MAR", 3), ("APR", 4), ("MAY", 5), ("JUN", 6),
    ("JUL", 7), ("AUG", 8), ("SEP", 9), ("OCT", 10), ("NOV", 11), ("DEC", 12),
]


def is_available() -> bool:
    return bool(TMD_API_UID and TMD_API_UKEY)


def _station_distance_key(station: ET.Element, region_lat: float, region_lon: float):
    # <Latitude>/<Longitude> are swapped in TMD's own response — see
    # module docstring.
    station_lon = float(station.findtext("Latitude", "nan"))
    station_lat = float(station.findtext("Longitude", "nan"))
    return (station_lat - region_lat) ** 2 + (station_lon - region_lon) ** 2


def _parse_tmd_response(xml_text: str, region_lat: float, region_lon: float) -> pd.DataFrame:
    """Extracts (period, temperature_2m_mean, precipitation_sum) monthly
    rows for the station nearest (region_lat, region_lon) — the same
    "one representative point per region" simplification used for the
    Open-Meteo/NASA POWER sources — from a ThailandMonthlyRainfall XML
    response. This endpoint only reports rainfall, never temperature, so
    temperature_2m_mean is always null for the tmd source."""
    try:
        root = ET.fromstring(xml_text)
    except ET.ParseError:
        # Observed live: TMD's server occasionally emits the whole document
        # twice, concatenated ("junk after document element") — the first
        # copy alone is still well-formed, so retry against just that
        # before giving up.
        end = xml_text.find(_ROOT_CLOSE_TAG)
        if end == -1:
            raise RuntimeError("Unexpected TMD API response (not valid XML).") from None
        try:
            root = ET.fromstring(xml_text[: end + len(_ROOT_CLOSE_TAG)])
        except ET.ParseError as exc:
            raise RuntimeError(f"Unexpected TMD API response (not valid XML): {exc}") from exc

    stations = root.findall("StationMonthlyRainfall")
    if not stations:
        raise RuntimeError(
            "Unexpected TMD API response shape (no StationMonthlyRainfall "
            "elements found) — _parse_tmd_response needs updating against a "
            "new real payload."
        )

    nearest = min(stations, key=lambda s: _station_distance_key(s, region_lat, region_lon))
    year_text = nearest.findtext("Year")
    rainfall = nearest.find("MonthlyRainfall")
    if year_text is None or rainfall is None:
        raise RuntimeError(
            "TMD API response parsed but the nearest station had no "
            "Year/MonthlyRainfall data — _parse_tmd_response needs "
            "updating against a new real payload."
        )
    year = int(year_text)
    today = date.today()

    rows = []
    for abbr, month in _MONTH_TAGS:
        if year == today.year and month > today.month:
            continue  # not reported yet this year — not a real zero.
        value = rainfall.findtext(f"Rainfall{abbr}")
        if value is None:
            continue
        rows.append(
            {
                "period": f"{year:04d}-{month:02d}",
                "precipitation_sum": float(value),
                "temperature_2m_mean": None,
            }
        )
    if not rows:
        raise RuntimeError(
            "TMD API response parsed but yielded no usable monthly rows — "
            "_parse_tmd_response needs updating against a new real payload."
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
    "Thailand" (enforced by the caller via CLIMATE_SOURCE_REGIONS). Note
    the demo credential tier only ever returns the current year (see
    module docstring) — a query for a past date range will come back
    empty, not an error, once the mask below filters out the returned
    current-year rows."""
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
    coords = REGIONS[region]
    df = _parse_tmd_response(resp.text, coords["lat"], coords["lon"])

    mask = (df["period"] >= start.strftime("%Y-%m")) & (df["period"] <= end.strftime("%Y-%m"))
    df = df.loc[mask].reset_index(drop=True)

    if resolution == "year":
        df["period"] = df["period"].str.slice(0, 4)
        df = df.groupby("period", as_index=False).agg(
            temperature_2m_mean=("temperature_2m_mean", "mean"),
            precipitation_sum=("precipitation_sum", "sum"),
        )

    return df
