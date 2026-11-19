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
    ai_note = None

    if date_key is None or value_key is None:
        try:
            from app.services.llm import harmonize_schema_with_llm
            sample = raw.head(5).to_dict(orient="records")
            ai_date, ai_val, ai_note = harmonize_schema_with_llm(list(raw.columns), sample)
            if ai_date and date_key is None:
                date_key = ai_date.lower().strip()
                cols[date_key] = ai_date
            if ai_val and value_key is None:
                value_key = ai_val.lower().strip()
                cols[value_key] = ai_val
        except Exception:
            pass

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
    if ai_note:
        transformations.append(f"AI Schema Harmonization: {ai_note}")

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


# Administrative unit harmonisation table (FR-28, Task H).
# In Thailand (THA), Bueng Kan province (TH38) was administratively separated
# from Nong Khai province (TH43) in 2011. Following Suttirat et al. (2026,
# PLOS Negl Trop Dis 20(7): e0014590, p. 5: "cases from Buengkarn province
# incorporated into Nong Khai province after it was administratively separated
# from Nong Khai in 2011 for consistency"), Bueng Kan case counts are merged
# into Nong Khai when merge_changed_units=True so the spatial unit set remains
# constant over time.
CHANGED_UNITS: dict[str, dict[str, str]] = {
    "THA": {"TH38": "TH43"},
}

_CHANGED_UNIT_TARGET_NAMES: dict[str, dict[str, str]] = {
    "THA": {"TH43": "Nong Khai"},
}


@lru_cache(maxsize=16)
def _read_admin1_csv(path_str: str, mtime_ns: int) -> pd.DataFrame:
    df = pd.read_csv(path_str)
    df["month"] = pd.to_datetime(df["month"], format="%Y-%m")
    df["cases"] = pd.to_numeric(df["dengue_total"], errors="raise").astype(int)
    return df


def load_dengue_admin1(
    iso3: str,
    start: date,
    end: date,
    merge_changed_units: bool = True,
) -> pd.DataFrame:
    """Loads monthly subnational (Admin1) dengue case counts for `iso3` within `[start, end]`.

    Returns a DataFrame with columns:
        `admin1_pcode`, `admin1_name`, `month` (period start timestamp), `cases`.

    When `merge_changed_units=True` (default), provinces listed in
    `CHANGED_UNITS[iso3]` (for Thailand: Bueng Kan `TH38` -> Nong Khai `TH43`,
    following Suttirat et al. 2026, p. 5) are merged into their parent unit by
    summing `cases` for each month where data exist. Months with no rows in the
    source remain absent (gaps are never filled, rule A20).
    """
    iso3_code = str(iso3 or "").strip().upper()
    # Only plain ISO 3166-1 alpha-3 codes may reach the file system path below.
    if len(iso3_code) != 3 or not iso3_code.isalpha():
        raise ValueError(f"no regional dengue data for {iso3!r}")

    path = DATA_DIR / f"dengue_monthly_admin1_{iso3_code}.csv"
    if not path.exists():
        raise ValueError(f"no regional dengue data for {iso3}")

    raw = _read_admin1_csv(str(path), path.stat().st_mtime_ns)
    mask = (raw["month"] >= pd.Timestamp(start)) & (raw["month"] <= pd.Timestamp(end))
    df = raw.loc[mask, ["admin1_pcode", "admin1_name", "month", "cases"]].copy()

    if df.empty:
        return pd.DataFrame(columns=["admin1_pcode", "admin1_name", "month", "cases"])

    if merge_changed_units and iso3_code in CHANGED_UNITS:
        unit_map = CHANGED_UNITS[iso3_code]
        target_names = dict(_CHANGED_UNIT_TARGET_NAMES.get(iso3_code, {}))
        for pcode, name in (
            raw[["admin1_pcode", "admin1_name"]].drop_duplicates().itertuples(index=False)
        ):
            if pcode in unit_map.values():
                target_names[pcode] = name

        needs_remap = df["admin1_pcode"].isin(unit_map)
        if needs_remap.any():
            df.loc[needs_remap, "admin1_pcode"] = df.loc[needs_remap, "admin1_pcode"].map(unit_map)
            df.loc[needs_remap, "admin1_name"] = df.loc[needs_remap, "admin1_pcode"].map(target_names)

        df = (
            df.groupby(["admin1_pcode", "admin1_name", "month"], as_index=False, sort=False)["cases"]
            .sum()
        )

    return (
        df[["admin1_pcode", "admin1_name", "month", "cases"]]
        .sort_values(["admin1_pcode", "month"])
        .reset_index(drop=True)
    )

