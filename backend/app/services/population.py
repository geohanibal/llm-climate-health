"""Historical population data access and resolution alignment.

Sources population data from World Bank Open Data (SP.POP.TOTL) and UN WPP
(built-in offline archive with live World Bank API fallback) to enable
calculating incidence rates per 100,000 population across different temporal
resolutions.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

from datetime import date
from functools import lru_cache
import pandas as pd
import requests

from app.config import DATA_DIR, REGIONS

POPULATION_DATA_FILE = "population_annual_by_iso3.csv"
WORLD_BANK_POP_URL = "https://api.worldbank.org/v2/country/{iso3}/indicator/SP.POP.TOTL?format=json&date={start_year}:{end_year}&per_page=100"


@lru_cache
def _load_builtin_population() -> pd.DataFrame:
    path = DATA_DIR / POPULATION_DATA_FILE
    if not path.exists():
        return pd.DataFrame(columns=["iso3", "year", "population"])
    return pd.read_csv(path)


def fetch_world_bank_population(iso3: str, start_year: int, end_year: int) -> pd.DataFrame:
    """Fallback fetch directly from World Bank Open Data API."""
    url = WORLD_BANK_POP_URL.format(iso3=iso3, start_year=start_year, end_year=end_year)
    try:
        resp = requests.get(url, timeout=10)
        if resp.status_code != 200:
            return pd.DataFrame(columns=["iso3", "year", "population"])
        payload = resp.json()
        if not isinstance(payload, list) or len(payload) < 2 or not payload[1]:
            return pd.DataFrame(columns=["iso3", "year", "population"])

        rows = []
        for entry in payload[1]:
            val = entry.get("value")
            yr = entry.get("date")
            if val is not None and yr is not None:
                try:
                    rows.append({
                        "iso3": iso3,
                        "year": int(yr),
                        "population": float(val),
                    })
                except ValueError:
                    pass
        return pd.DataFrame(rows).sort_values("year").reset_index(drop=True)
    except Exception:
        return pd.DataFrame(columns=["iso3", "year", "population"])


def get_population_data(
    region: str,
    start: date,
    end: date,
    resolution: str = "year",
    source: str = "worldbank",
) -> pd.DataFrame:
    """Returns a DataFrame with columns ['period', 'population'] aligned to
    the requested temporal resolution ('month', 'year', 'decade') for the given region."""
    info = REGIONS.get(region)
    if not info:
        return pd.DataFrame(columns=["period", "population"])

    iso3 = info["iso3"]
    df = _load_builtin_population()
    subset = df[df["iso3"] == iso3].copy()

    start_year = start.year
    end_year = end.year

    if subset.empty:
        # Fallback to World Bank API
        subset = fetch_world_bank_population(iso3, start_year, end_year)

    if subset.empty:
        return pd.DataFrame(columns=["period", "population"])

    subset["year"] = subset["year"].astype(int)
    subset["population"] = subset["population"].astype(float)

    # Filter year range with a small buffer for interpolation
    filtered = subset[(subset["year"] >= start_year - 1) & (subset["year"] <= end_year + 1)].sort_values("year")
    if filtered.empty:
        filtered = subset.sort_values("year")

    # Map to requested resolution
    if resolution == "decade":
        # Decade period string like "2010s"
        filtered = filtered[(filtered["year"] >= start_year) & (filtered["year"] <= end_year)].copy()
        if filtered.empty:
            return pd.DataFrame(columns=["period", "population"])
        filtered["decade"] = (filtered["year"] // 10 * 10).astype(str) + "s"
        agg = filtered.groupby("decade", as_index=False)["population"].mean()
        return agg.rename(columns={"decade": "period"})[["period", "population"]]

    if resolution == "year":
        # Yearly period string like "2020"
        filtered = filtered[(filtered["year"] >= start_year) & (filtered["year"] <= end_year)].copy()
        filtered["period"] = filtered["year"].astype(str)
        return filtered[["period", "population"]].reset_index(drop=True)

    if resolution == "month":
        # Monthly resolution: each month YYYY-MM gets the mid-year population for that year
        year_to_pop = dict(zip(filtered["year"], filtered["population"]))
        current = pd.Timestamp(start).replace(day=1)
        end_ts = pd.Timestamp(end).replace(day=1)
        months = []
        while current <= end_ts:
            period_str = current.strftime("%Y-%m")
            pop = year_to_pop.get(current.year)
            if pop is None and year_to_pop:
                nearest_year = min(year_to_pop.keys(), key=lambda y: abs(y - current.year))
                pop = year_to_pop[nearest_year]
            months.append({"period": period_str, "population": pop})
            if current.month == 12:
                current = pd.Timestamp(year=current.year + 1, month=1, day=1)
            else:
                current = pd.Timestamp(year=current.year, month=current.month + 1, day=1)

        return pd.DataFrame(months)

    return pd.DataFrame(columns=["period", "population"])
