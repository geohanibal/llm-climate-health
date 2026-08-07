"""Core ETL orchestration: fetch, aggregate, and join case and climate data
across diseases with different native temporal resolutions, and across
optional coarser aggregation levels (yearly, decadal) for long-run analysis.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

from datetime import date

import pandas as pd

from app.config import CLIMATE_SOURCES, DISEASES, REGIONS, DiseaseMeta
from app.models import PeriodRecord
from app.services.case_data import (
    get_builtin_case_data,
    get_case_data_from_upload,
    get_case_data_from_url,
)
from app.services.climate import fetch_climate

# Internal, resolution-agnostic vocabulary used throughout this module.
_RESOLUTION_LABEL = {"month": "monthly", "year": "yearly", "decade": "decadal"}


def _target_resolution(disease: DiseaseMeta, aggregation: str) -> str:
    """Resolve the user's requested aggregation against what the disease's
    data actually supports — you cannot go finer than the native
    resolution (e.g. malaria/cholera have no monthly case counts)."""
    if aggregation == "decadal":
        return "decade"
    if aggregation == "yearly":
        return "year"
    return "month" if disease.native_resolution == "month" else "year"


def _period_label(series: pd.Series, resolution: str) -> pd.Series:
    if resolution == "decade":
        return (series.dt.year // 10 * 10).astype(str) + "s"
    if resolution == "year":
        return series.dt.strftime("%Y")
    return series.dt.strftime("%Y-%m")


def resolve_case_data(
    disease: DiseaseMeta,
    region: str,
    start: date,
    end: date,
    case_data_source: str,
    custom_source_url: str | None,
    upload_content: bytes | None,
    steps: list[str],
) -> pd.DataFrame:
    if case_data_source == "custom_upload":
        df = get_case_data_from_upload(upload_content, start, end)
        steps.append(
            f"Parsed {len(df)} case-count records from the file you uploaded "
            f"(date/case columns auto-detected)."
        )
        return df

    if case_data_source == "custom_url":
        df = get_case_data_from_url(custom_source_url, start, end)
        steps.append(
            f"Fetched and parsed {len(df)} case-count records from the URL "
            f"you provided: {custom_source_url}"
        )
        return df

    df = get_builtin_case_data(disease, region, start, end)
    steps.append(
        f"Retrieved {len(df)} {disease.native_resolution}ly {disease.label} "
        f"case-count records for {region} from the built-in source "
        f"({disease.citation})."
    )
    return df


def run_integration(
    disease_key: str,
    region: str,
    variables: list[str],
    start: date,
    end: date,
    aggregation: str = "native",
    climate_source: str = "open-meteo-era5",
    case_data_source: str = "builtin",
    custom_source_url: str | None = None,
    upload_content: bytes | None = None,
):
    disease = DISEASES[disease_key]
    steps: list[str] = []

    coords = REGIONS[region]
    steps.append(
        f"Received request: disease='{disease.label}', region='{region}', "
        f"variables={variables}, period={start} to {end}, "
        f"aggregation='{aggregation}', scenario='historical'."
    )
    steps.append(
        f"Validated region '{region}' and mapped it to a reference "
        f"coordinate (lat={coords['lat']}, lon={coords['lon']}). This demo "
        f"uses one representative point per country as a simplification of "
        f"the gridded, admin-area-resolved approach the full platform targets."
    )

    case_df = resolve_case_data(
        disease, region, start, end, case_data_source, custom_source_url, upload_content, steps
    )

    resolution = _target_resolution(disease, aggregation)

    case_df = case_df.copy()
    if case_df.empty:
        case_agg = case_df.assign(period=pd.Series(dtype="object"))[["period", "value"]]
    else:
        case_df["period"] = _period_label(case_df["period_start"], resolution)
        case_agg = case_df.groupby("period", as_index=False)["value"].sum()

    climate_fetch_resolution = "month" if resolution == "month" else "year"
    climate_df = fetch_climate(
        region, variables, start, end, source=climate_source, resolution=climate_fetch_resolution
    )
    steps.append(
        f"Retrieved daily {', '.join(variables)} data for {region} from "
        f"{CLIMATE_SOURCES[climate_source]['label']} "
        f"({CLIMATE_SOURCES[climate_source]['citation']}) and aggregated it "
        f"to {_RESOLUTION_LABEL[climate_fetch_resolution]} resolution "
        f"(mean for temperature, sum for precipitation)."
    )

    if resolution == "decade":
        climate_df = climate_df.copy()
        climate_df["decade"] = (climate_df["period"].astype(int) // 10 * 10).astype(str) + "s"
        agg = {}
        if "temperature_2m_mean" in climate_df.columns:
            agg["temperature_2m_mean"] = "mean"
        if "precipitation_sum" in climate_df.columns:
            agg["precipitation_sum"] = "mean"
        climate_df = climate_df.groupby("decade", as_index=False).agg(agg).rename(
            columns={"decade": "period"}
        )
        steps.append(
            "Further aggregated the yearly climate and case series into "
            "decades: temperature as the mean of yearly means, precipitation "
            "as the mean annual total, and cases as the decade's total count."
        )

    merged = pd.merge(case_agg, climate_df, on="period", how="outer").sort_values("period")
    steps.append(
        f"Temporally joined the {disease.label} and climate series on a "
        f"shared {_RESOLUTION_LABEL[resolution]} period key, producing "
        f"{len(merged)} aligned rows."
    )

    def clean(value):
        return None if value is None or pd.isna(value) else float(value)

    records = []
    for _, row in merged.iterrows():
        records.append(
            PeriodRecord(
                period=row["period"],
                case_count=clean(row.get("value")),
                temperature_mean_c=clean(row.get("temperature_2m_mean")),
                precipitation_sum_mm=clean(row.get("precipitation_sum")),
            )
        )

    return steps, records, resolution
