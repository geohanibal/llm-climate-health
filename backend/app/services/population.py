"""Historical population data access and resolution alignment.

Sources population data from World Bank Open Data (SP.POP.TOTL), UN WPP,
custom user-provided CSV uploads, and live World Bank demographic indicator
search (such as urban, rural, 65+, 0-14 demographics) to enable calculating
incidence rates per 100,000 population across different temporal resolutions.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

import io
from datetime import date
from functools import lru_cache

import pandas as pd
import requests

from app.config import DATA_DIR, REGIONS
from app.models import DiscoveredSource

POPULATION_DATA_FILE = "population_annual_by_iso3.csv"
WORLD_BANK_POP_URL = "https://api.worldbank.org/v2/country/{iso3}/indicator/{indicator}?format=json&date={start_year}:{end_year}&per_page=100"

# Curated, scientific demographic indicators from World Bank Open Data
POPULATION_INDICATORS = [
    {
        "code": "SP.POP.TOTL",
        "name": "Population, total",
        "desc": "Total population count based on the de facto definition of population, counting all residents regardless of legal status or citizenship.",
    },
    {
        "code": "SP.URB.TOTL",
        "name": "Urban population",
        "desc": "Urban population headcount living in urban areas as defined by national statistical offices (critical for urban vector ecology like Aedes aegypti).",
    },
    {
        "code": "SP.RUR.TOTL",
        "name": "Rural population",
        "desc": "Rural population headcount living in rural areas (critical for rural malaria and agricultural vector exposure like Anopheles).",
    },
    {
        "code": "SP.POP.65UP.TO",
        "name": "Population ages 65 and above",
        "desc": "Senior citizens count (highest biological vulnerability to extreme thermal stress, heatwaves, and compounding cardiovascular climate impacts).",
    },
    {
        "code": "SP.POP.0014.TO",
        "name": "Population ages 0 to 14",
        "desc": "Children and youth count (high immunological vulnerability for pediatric severe malaria and dengue shock syndrome).",
    },
    {
        "code": "EN.POP.DNST",
        "name": "Population density (people per sq. km of land area)",
        "desc": "Midyear population divided by land area in square kilometers, assessing host proximity and epidemiological transmission potential.",
    },
    {
        "code": "SP.POP.GROW",
        "name": "Population growth (annual %)",
        "desc": "Annual exponential growth rate of midyear population from year t-1 to t.",
    },
    {
        "code": "SP.POP.TOTL.FE.IN",
        "name": "Population, female",
        "desc": "Female population count based on midyear de facto national estimates.",
    },
    {
        "code": "SP.POP.TOTL.MA.IN",
        "name": "Population, male",
        "desc": "Male population count based on midyear de facto national estimates.",
    },
]

POPULATION_DATE_COLS = ["year", "date", "period", "period_start", "time", "survey_year", "calendar_start_date"]
POPULATION_VALUE_COLS = ["population", "pop", "total_population", "count", "people", "persons", "residents", "value", "cases", "total"]


def search_population_sources(region_label: str, query: str = "") -> list[DiscoveredSource]:
    """Searches official World Bank demographic indicators and HDX demographic datasets."""
    sources: list[DiscoveredSource] = []
    q = query.lower().strip()

    # 1. Match curated World Bank indicators
    for item in POPULATION_INDICATORS:
        code = item["code"]
        name = item["name"]
        desc = item["desc"]
        if not q or (q in code.lower() or q in name.lower() or q in desc.lower()):
            sources.append(
                DiscoveredSource(
                    source_type="worldbank",
                    title=name,
                    organization="World Bank Group (WDI)",
                    description=desc,
                    citation=f"World Bank Group, Indicator {code} — {name} (api.worldbank.org)",
                    dataset_url=f"https://data.worldbank.org/indicator/{code}",
                    indicator_code=code,
                )
            )

    # 2. HDX demographic datasets
    try:
        from app.services import hdx

        hdx_results = hdx.search_case_datasets(f"{region_label} population") or hdx.search_case_datasets(
            f"{region_label} census"
        )
        for ds in hdx_results[:5]:
            sources.append(
                DiscoveredSource(
                    source_type="hdx",
                    title=ds["title"],
                    organization=ds["organization"],
                    description=ds["notes"][:280] if ds["notes"] else "Demographic dataset via HDX.",
                    citation=f"{ds['organization']}, \"{ds['title']}\" via HDX (data.humdata.org)",
                    dataset_url=ds["dataset_url"],
                    resource_url=ds.get("resource_url"),
                )
            )
    except Exception:
        pass

    return sources


@lru_cache
def _load_builtin_population() -> pd.DataFrame:
    path = DATA_DIR / POPULATION_DATA_FILE
    if not path.exists():
        return pd.DataFrame(columns=["iso3", "year", "population"])
    return pd.read_csv(path)


def fetch_world_bank_population_indicator(
    iso3: str, indicator_code: str, start_year: int, end_year: int
) -> pd.DataFrame:
    """Fetches a specific demographic indicator from World Bank Open Data API."""
    safe_indicator = indicator_code.strip()
    url = WORLD_BANK_POP_URL.format(iso3=iso3, indicator=safe_indicator, start_year=start_year, end_year=end_year)
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


def fetch_world_bank_population(iso3: str, start_year: int, end_year: int) -> pd.DataFrame:
    """Fallback fetch directly from World Bank Open Data API for total population."""
    return fetch_world_bank_population_indicator(iso3, "SP.POP.TOTL", start_year, end_year)


def parse_custom_population_csv(content: bytes) -> pd.DataFrame:
    """Parses user-uploaded population CSV, auto-detecting temporal and demographic columns."""
    df = pd.read_csv(io.BytesIO(content))
    cols_map = {str(c).lower().strip(): str(c) for c in df.columns}

    # 1. Detect date/year column
    date_col = None
    for cand in POPULATION_DATE_COLS:
        if cand in cols_map:
            date_col = cols_map[cand]
            break
    if not date_col:
        for c_lower, c_orig in cols_map.items():
            if any(k in c_lower for k in ["year", "date", "period", "time"]):
                date_col = c_orig
                break

    # 2. Detect population value column
    pop_col = None
    for cand in POPULATION_VALUE_COLS:
        if cand in cols_map:
            pop_col = cols_map[cand]
            break
    if not pop_col:
        for c_lower, c_orig in cols_map.items():
            if any(k in c_lower for k in ["pop", "total", "count", "people", "value"]):
                pop_col = c_orig
                break

    if not date_col or not pop_col:
        raise ValueError(
            f"Could not identify date and population columns in uploaded CSV (columns found: {list(df.columns)}). "
            f"Expected date column (e.g. year, date, period) and population column (e.g. population, total, count)."
        )

    out = pd.DataFrame()
    raw_date = df[date_col].astype(str).str.strip()

    # Try 4-digit year
    if raw_date.str.match(r"^\d{4}$").all():
        out["year"] = raw_date.astype(int)
        out["period_start"] = pd.to_datetime(out["year"], format="%Y")
    else:
        out["period_start"] = pd.to_datetime(raw_date, errors="coerce")
        out["year"] = out["period_start"].dt.year

    cleaned_pop = df[pop_col].astype(str).str.replace(",", "").str.replace(" ", "")
    out["population"] = pd.to_numeric(cleaned_pop, errors="coerce")
    out = out.dropna(subset=["population", "period_start"])
    if out.empty:
        raise ValueError("Uploaded population dataset contains no valid non-empty population rows.")
    return out.sort_values("period_start").reset_index(drop=True)


def get_population_from_upload(
    upload_content: bytes,
    start: date,
    end: date,
    resolution: str = "year",
) -> pd.DataFrame:
    df = parse_custom_population_csv(upload_content)
    return _align_population_resolution(df, start, end, resolution)


def get_population_from_url(
    url: str,
    start: date,
    end: date,
    resolution: str = "year",
) -> pd.DataFrame:
    try:
        resp = requests.get(url, timeout=15)
        resp.raise_for_status()
        return get_population_from_upload(resp.content, start, end, resolution)
    except Exception as exc:
        raise ValueError(f"Failed to fetch population data from URL '{url}': {exc}")


def _align_population_resolution(
    df: pd.DataFrame,
    start: date,
    end: date,
    resolution: str,
) -> pd.DataFrame:
    """Aligns a dataframe with ['year', 'population'] or ['period_start', 'population'] to resolution."""
    start_year = start.year
    end_year = end.year

    df = df.copy()
    if "year" not in df.columns:
        df["year"] = df["period_start"].dt.year

    df["year"] = df["year"].astype(int)
    df["population"] = df["population"].astype(float)

    filtered = df[(df["year"] >= start_year - 1) & (df["year"] <= end_year + 1)].sort_values("year")
    if filtered.empty:
        filtered = df.sort_values("year")

    if resolution == "decade":
        filtered = filtered[(filtered["year"] >= start_year) & (filtered["year"] <= end_year)].copy()
        if filtered.empty:
            return pd.DataFrame(columns=["period", "population"])
        filtered["decade"] = (filtered["year"] // 10 * 10).astype(str) + "s"
        agg = filtered.groupby("decade", as_index=False)["population"].mean()
        return agg.rename(columns={"decade": "period"})[["period", "population"]]

    if resolution == "year":
        filtered = filtered[(filtered["year"] >= start_year) & (filtered["year"] <= end_year)].copy()
        filtered["period"] = filtered["year"].astype(str)
        return filtered[["period", "population"]].reset_index(drop=True)

    if resolution == "month":
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

    if resolution == "day":
        year_to_pop = dict(zip(filtered["year"], filtered["population"]))
        current = pd.Timestamp(start)
        end_ts = pd.Timestamp(end)
        days = []
        while current <= end_ts:
            period_str = current.strftime("%Y-%m-%d")
            pop = year_to_pop.get(current.year)
            if pop is None and year_to_pop:
                nearest_year = min(year_to_pop.keys(), key=lambda y: abs(y - current.year))
                pop = year_to_pop[nearest_year]
            days.append({"period": period_str, "population": pop})
            current += pd.DateOffset(days=1)
        return pd.DataFrame(days)

    return pd.DataFrame(columns=["period", "population"])


def get_population_data(
    region: str,
    start: date,
    end: date,
    resolution: str = "year",
    source: str = "worldbank",
    custom_source_url: str | None = None,
    upload_content: bytes | None = None,
    indicator_code: str | None = None,
    population_source: str | None = None,
) -> pd.DataFrame:
    """Returns a DataFrame with columns ['period', 'population'] aligned to
    the requested temporal resolution ('day', 'month', 'year', 'decade') for the given region."""
    if population_source:
        source = population_source
    if source == "custom_upload":
        if not upload_content:
            raise ValueError("No file content uploaded for demographic source 'custom_upload'.")
        return get_population_from_upload(upload_content, start, end, resolution=resolution)

    if source == "custom_url":
        if not custom_source_url:
            raise ValueError("No URL provided for demographic source 'custom_url'.")
        return get_population_from_url(custom_source_url, start, end, resolution=resolution)

    info = REGIONS.get(region)
    if not info:
        return pd.DataFrame(columns=["period", "population"])

    iso3 = info["iso3"]
    start_year = start.year
    end_year = end.year

    if source == "worldbank_indicator" and indicator_code:
        subset = fetch_world_bank_population_indicator(iso3, indicator_code, start_year, end_year)
    else:
        df = _load_builtin_population()
        subset = df[df["iso3"] == iso3].copy()
        if subset.empty:
            subset = fetch_world_bank_population(iso3, start_year, end_year)

    if subset.empty:
        return pd.DataFrame(columns=["period", "population"])

    return _align_population_resolution(subset, start, end, resolution)
