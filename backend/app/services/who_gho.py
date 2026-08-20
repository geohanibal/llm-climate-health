"""World Health Organization Global Health Observatory (GHO) client.

Two responsibilities:
  1. `search_indicators` — full-text search over WHO's own indicator catalog,
     so the frontend can offer real, WHO-defined indicators (e.g. "confirmed
     malaria cases" vs. "estimated malaria cases" vs. "malaria deaths")
     instead of one hardcoded choice per disease.
  2. `fetch_who_gho_case_data` — pulls the actual yearly values for one
     chosen indicator + country, normalized to the same (period_start,
     value) shape every other case-data source in this codebase produces.

WHO GHO's OData API is public, free, and needs no API key:
https://www.who.int/data/gho/info/gho-odata-api

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

from datetime import date

import pandas as pd
import requests

_BASE_URL = "https://ghoapi.azureedge.net/api"


def search_indicators(keyword: str, limit: int = 15) -> list[dict]:
    """Full-text search over WHO's indicator catalog. Returns real indicator
    codes/names straight from WHO — never invented."""
    safe_keyword = keyword.replace("'", "")
    params = {
        "$filter": f"contains(IndicatorName,'{safe_keyword}')",
        "$top": str(limit),
    }
    resp = requests.get(f"{_BASE_URL}/Indicator", params=params, timeout=15)
    resp.raise_for_status()
    return [
        {"code": row["IndicatorCode"], "name": row["IndicatorName"]}
        for row in resp.json().get("value", [])
    ]


def fetch_who_gho_case_data(
    indicator_code: str, iso3: str, start: date, end: date
) -> pd.DataFrame:
    """Fetches yearly values for one WHO GHO indicator + country, filtered
    to [start, end]. Raises ValueError if WHO has no data for this
    indicator/country combination (a clear, honest failure — never silently
    substitutes another indicator)."""
    safe_code = indicator_code.replace("'", "").replace(" ", "")
    if not safe_code.replace("_", "").isalnum():
        raise ValueError(f"Invalid WHO GHO indicator code: {indicator_code!r}")

    params = {"$filter": f"SpatialDim eq '{iso3}'"}
    resp = requests.get(f"{_BASE_URL}/{safe_code}", params=params, timeout=15)
    resp.raise_for_status()
    rows = resp.json().get("value", [])
    if not rows:
        raise ValueError(
            f"WHO GHO indicator '{indicator_code}' has no data for country '{iso3}'."
        )

    df = pd.DataFrame(rows)
    df = df[df["TimeDimType"] == "YEAR"]
    df["period_start"] = pd.to_datetime(df["TimeDim"], format="%Y")
    df["value"] = pd.to_numeric(df["NumericValue"], errors="coerce")
    df = df.dropna(subset=["value"])

    mask = (df["period_start"] >= pd.Timestamp(start)) & (df["period_start"] <= pd.Timestamp(end))
    return (
        df.loc[mask, ["period_start", "value"]]
        .sort_values("period_start")
        .reset_index(drop=True)
    )
