"""Disease case-count data access.

Generalizes across diseases with different native temporal resolutions
(dengue: monthly OpenDengue archive; malaria/cholera: annual WHO GHO
indicators), plus two user-supplied scientific-data pathways (a CSV URL, or
an uploaded CSV file) that work for any disease.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

import io
from datetime import date
from functools import lru_cache

import pandas as pd
import requests

from app.config import DATA_DIR, REGIONS, DiseaseMeta

CANDIDATE_DATE_COLUMNS = ["month", "date", "year", "calendar_start_date"]
CANDIDATE_VALUE_COLUMNS = ["cases", "case_count", "dengue_total", "value", "count"]


@lru_cache
def _load_builtin(data_file: str) -> pd.DataFrame:
    path = DATA_DIR / data_file
    if not path.exists():
        return pd.DataFrame(columns=["iso3", "period_start", "value"])
    return pd.read_csv(path)


def get_builtin_case_data(disease: DiseaseMeta, region: str, start: date, end: date) -> pd.DataFrame:
    info = REGIONS.get(region)
    if info is None:
        return pd.DataFrame(columns=["period_start", "value"])

    df = _load_builtin(disease.data_file)
    if df.empty:
        return pd.DataFrame(columns=["period_start", "value"])
    df = df[df["iso3"] == info["iso3"]].copy()

    if disease.native_resolution == "month":
        df["period_start"] = pd.to_datetime(df["month"], format="%Y-%m")
    else:
        df["period_start"] = pd.to_datetime(df["year"], format="%Y")

    df["value"] = df[disease.value_col]
    mask = (df["period_start"] >= pd.Timestamp(start)) & (df["period_start"] <= pd.Timestamp(end))
    return df.loc[mask, ["period_start", "value"]].sort_values("period_start").reset_index(drop=True)


def _normalize_custom_frame(raw: pd.DataFrame) -> pd.DataFrame:
    cols = {c.lower().strip(): c for c in raw.columns}

    date_col = next((cols[c] for c in CANDIDATE_DATE_COLUMNS if c in cols), None)
    value_col = next((cols[c] for c in CANDIDATE_VALUE_COLUMNS if c in cols), None)
    if date_col is None or value_col is None:
        raise ValueError(
            "Could not find recognizable date/case columns. Expected one of "
            f"{CANDIDATE_DATE_COLUMNS} and one of {CANDIDATE_VALUE_COLUMNS}."
        )

    out = raw[[date_col, value_col]].copy()
    out.columns = ["raw_date", "value"]
    out["period_start"] = pd.to_datetime(out["raw_date"])
    return out[["period_start", "value"]]


def _filter_range(df: pd.DataFrame, start: date, end: date) -> pd.DataFrame:
    mask = (df["period_start"] >= pd.Timestamp(start)) & (df["period_start"] <= pd.Timestamp(end))
    return df.loc[mask].sort_values("period_start").reset_index(drop=True)


def get_case_data_from_url(url: str, start: date, end: date) -> pd.DataFrame:
    resp = requests.get(url, timeout=30)
    resp.raise_for_status()
    df = _normalize_custom_frame(pd.read_csv(io.StringIO(resp.text)))
    return _filter_range(df, start, end)


def get_case_data_from_upload(content: bytes, start: date, end: date) -> pd.DataFrame:
    df = _normalize_custom_frame(pd.read_csv(io.BytesIO(content)))
    return _filter_range(df, start, end)
