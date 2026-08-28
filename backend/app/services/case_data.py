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

CANDIDATE_DATE_COLUMNS = [
    "month",
    "date",
    "year",
    "calendar_start_date",
    "period",
    "time",
    "datetime",
    "timestamp",
    "period_start",
    "year_month",
    "survey_year",
    "observation_date",
    "reporting_date",
    "start_date",
    "end_date",
    "period_name",
    "epi_week",
    "datum",
]
CANDIDATE_VALUE_COLUMNS = [
    "cases",
    "case_count",
    "dengue_total",
    "value",
    "count",
    "malaria_cases",
    "cholera_cases",
    "confirmed_cases",
    "estimated_cases",
    "reported_cases",
    "incidence",
    "prevalence",
    "total_cases",
    "num_cases",
    "cases_total",
    "number_of_cases",
    "rate",
    "had_fever_or_malaria_in_percent",
    "total",
    "cases_reported",
    "suspected_cases",
    "data_value",
    "indicator_value",
    "metric_value",
    "amount",
    "statistic",
]

DATE_KEYWORDS = ["date", "year", "month", "time", "period", "week", "datum", "timestamp"]
VALUE_KEYWORDS = ["case", "count", "value", "total", "rate", "incidence", "prevalence", "fever", "malaria", "dengue", "cholera", "num"]


def _find_column(cols: dict[str, str], candidates: list[str], keywords: list[str]) -> str | None:
    # 1. Exact match from candidates list
    for cand in candidates:
        if cand in cols:
            return cand
    # 2. Substring keyword match
    for col_lower in cols:
        if any(kw in col_lower for kw in keywords):
            return col_lower
    return None


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
    cols = {str(c).lower().strip(): str(c) for c in raw.columns}

    date_key = _find_column(cols, CANDIDATE_DATE_COLUMNS, DATE_KEYWORDS)
    value_key = _find_column(cols, CANDIDATE_VALUE_COLUMNS, VALUE_KEYWORDS)

    if date_key is None or value_key is None:
        found_cols = [str(c) for c in raw.columns]
        missing = []
        if date_key is None:
            missing.append(
                f"time-series date column (expected one of {CANDIDATE_DATE_COLUMNS[:6]}... or columns containing {DATE_KEYWORDS})"
            )
        if value_key is None:
            missing.append(
                f"case count column (expected one of {CANDIDATE_VALUE_COLUMNS[:6]}... or columns containing {VALUE_KEYWORDS[:6]})"
            )
        raise ValueError(
            f"Could not find recognizable columns in dataset (found columns: {found_cols}). "
            f"Missing: {' and '.join(missing)}. "
            "Climate-health integration requires a temporal dimension to align disease cases with historical weather."
        )

    date_col = cols[date_key]
    value_col = cols[value_key]

    transformations = [
        f"Selected '{date_col}' as temporal index",
        f"Selected '{value_col}' as disease case metric",
    ]

    out = raw[[date_col, value_col]].copy()
    out.columns = ["raw_date", "value"]

    out["value"] = pd.to_numeric(out["value"], errors="coerce")

    # A bare "year" (e.g. 2020) or "month" (e.g. "2020-01") column needs an
    # explicit format: pandas otherwise reads a plain int as nanoseconds
    # since the epoch, collapsing every row to 1970 and silently dropping
    # all of them once filtered against a real date range.
    if date_key in ("year", "survey_year") or "year" in date_key:
        out["period_start"] = pd.to_datetime(out["raw_date"].astype(str), format="%Y", errors="coerce")
        transformations.append("Parsed integer/string years as YYYY dates")
    elif date_key in ("month", "year_month") or "month" in date_key:
        out["period_start"] = pd.to_datetime(out["raw_date"].astype(str), format="%Y-%m", errors="coerce")
        transformations.append("Parsed year-month periods as YYYY-MM dates")
    else:
        out["period_start"] = pd.to_datetime(out["raw_date"], errors="coerce")
        transformations.append("Inferred standard ISO timestamps")

    n_total = len(out)
    out = out.dropna(subset=["period_start"])
    n_dropped = n_total - len(out)
    if n_total > 0 and out.empty:
        raise ValueError(
            f"None of the {n_total} row(s) had a valid date this parser could "
            f"recognize in the '{date_col}' column."
        )

    if n_dropped > 0:
        transformations.append(f"Filtered out {n_dropped} row(s) with invalid or null dates")

    result = out[["period_start", "value"]]
    result.attrs["dropped_rows"] = n_dropped
    result.attrs["transformation_audit"] = {
        "original_columns": [str(c) for c in raw.columns],
        "selected_date_column": date_col,
        "selected_value_column": value_col,
        "total_rows_received": n_total,
        "valid_rows_retained": len(out),
        "dropped_rows_count": n_dropped,
        "transformations_applied": transformations,
    }
    return result


def _filter_range(df: pd.DataFrame, start: date, end: date) -> pd.DataFrame:
    mask = (df["period_start"] >= pd.Timestamp(start)) & (df["period_start"] <= pd.Timestamp(end))
    out = df.loc[mask].sort_values("period_start").reset_index(drop=True)
    out.attrs = dict(df.attrs)
    return out


def _safe_read_csv(source: io.StringIO | io.BytesIO) -> pd.DataFrame:
    try:
        return pd.read_csv(source, on_bad_lines="skip")
    except Exception:
        source.seek(0)
        return pd.read_csv(source, sep=None, engine="python", on_bad_lines="skip")


def get_case_data_from_url(url: str, start: date, end: date) -> pd.DataFrame:
    resp = requests.get(url, timeout=30)
    resp.raise_for_status()
    df = _normalize_custom_frame(_safe_read_csv(io.StringIO(resp.text)))
    return _filter_range(df, start, end)


def get_case_data_from_upload(content: bytes, start: date, end: date) -> pd.DataFrame:
    df = _normalize_custom_frame(_safe_read_csv(io.BytesIO(content)))
    return _filter_range(df, start, end)
