"""Core ETL orchestration: fetch, aggregate, and join case and climate data
across diseases with different native temporal resolutions, and across
optional coarser aggregation levels (yearly, decadal) for long-run analysis.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

from datetime import date

import pandas as pd

from app.config import CLIMATE_SOURCES, DISEASES, POPULATION_SOURCES, REGIONS, DiseaseMeta
from app.models import PeriodRecord
from app.services.case_data import (
    get_builtin_case_data,
    get_case_data_from_upload,
    get_case_data_from_url,
)
from app.services.climate import fetch_climate
from app.services.population import get_population_data
from app.services.statistics import compute_statistics
from app.services.tmd import fetch_tmd_climate
from app.services.who_gho import fetch_who_gho_case_data

# Internal, resolution-agnostic vocabulary used throughout this module.
_RESOLUTION_LABEL = {"day": "daily", "month": "monthly", "year": "yearly", "decade": "decadal"}


def _target_resolution(native_resolution: str, aggregation: str) -> str:
    """Resolve the user's requested aggregation against what the chosen
    case-data source actually supports."""
    if aggregation == "decadal":
        return "decade"
    if aggregation == "yearly":
        return "year"
    if aggregation == "daily":
        return "day"
    return "month" if native_resolution == "month" else "year"


def _dropped_rows_note(df: pd.DataFrame) -> str:
    """Surfaces `_normalize_custom_frame`'s row-drop count (carried on the
    DataFrame via `.attrs` rather than a second return value, since the
    frame is also used directly by tests as-is) in the user-facing steps —
    a few unparseable rows shouldn't fail the whole import, but dropping
    them must never happen silently."""
    dropped = df.attrs.get("dropped_rows", 0)
    if not dropped:
        return ""
    return f" ({dropped} row(s) skipped: unparseable date.)"


def _period_label(series: pd.Series, resolution: str) -> pd.Series:
    if resolution == "decade":
        return (series.dt.year // 10 * 10).astype(str) + "s"
    if resolution == "year":
        return series.dt.strftime("%Y")
    if resolution == "day":
        return series.dt.strftime("%Y-%m-%d")
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
    who_indicator_code: str | None = None,
    who_indicator_name: str | None = None,
) -> pd.DataFrame:
    if case_data_source == "custom_upload":
        df = get_case_data_from_upload(upload_content, start, end)
        steps.append(
            f"Parsed {len(df)} case-count records from the file you uploaded "
            f"(date/case columns auto-detected)."
            + _dropped_rows_note(df)
        )
        return df

    if case_data_source == "custom_url":
        df = get_case_data_from_url(custom_source_url, start, end)
        steps.append(
            f"Fetched and parsed {len(df)} case-count records from the URL "
            f"you provided: {custom_source_url}"
            + _dropped_rows_note(df)
        )
        return df

    if case_data_source == "who_gho":
        iso3 = REGIONS[region]["iso3"]
        df = fetch_who_gho_case_data(who_indicator_code, iso3, start, end)
        steps.append(
            f"Fetched {len(df)} yearly records for {region} from WHO Global "
            f"Health Observatory indicator '{who_indicator_name or who_indicator_code}' "
            f"({who_indicator_code}), the source you selected from the search results."
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
    population_source: str = "worldbank",
    custom_source_url: str | None = None,
    upload_content: bytes | None = None,
    who_indicator_code: str | None = None,
    who_indicator_name: str | None = None,
    climate_upload_content: bytes | None = None,
    custom_population_url: str | None = None,
    population_upload_content: bytes | None = None,
    population_indicator_code: str | None = None,
    population_indicator_name: str | None = None,
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
        disease,
        region,
        start,
        end,
        case_data_source,
        custom_source_url,
        upload_content,
        steps,
        who_indicator_code,
        who_indicator_name,
    )

    # WHO GHO indicators are always yearly, regardless of the disease's
    # normal native resolution (e.g. dengue is monthly via OpenDengue but
    # yearly via WHO GHO) — using the source actually queried, not the
    # disease's default, keeps the case/climate join periods aligned.
    native_resolution = "year" if case_data_source == "who_gho" else disease.native_resolution
    resolution = _target_resolution(native_resolution, aggregation)

    case_df = case_df.copy()
    has_daily_input = (
        case_data_source in ("custom_upload", "custom_url")
        and len(case_df) > 0
        and (case_df["period_start"].dt.day > 1).any()
    )
    if case_df.empty:
        case_agg = case_df.assign(period=pd.Series(dtype="object"))[["period", "value"]]
    elif resolution == "day" and not has_daily_input and len(case_df) > 0:
        all_days = pd.date_range(start=start, end=end, freq="D")
        daily_df = pd.DataFrame({"day": all_days})

        if len(case_df) == 1:
            row = case_df.iloc[0]
            days_in_p = max(len(daily_df), 1)
            daily_val = round(float(row["value"]) / days_in_p, 3) if pd.notna(row["value"]) else None
            daily_df["value"] = daily_val
        else:
            midpoints = []
            rates = []
            for _, row in case_df.iterrows():
                p_start = pd.Timestamp(row["period_start"])
                if native_resolution == "month":
                    days_in_p = int(p_start.days_in_month)
                else:
                    days_in_p = 366 if p_start.is_leap_year else 365
                p_end = p_start + pd.DateOffset(days=days_in_p - 1)
                midpoint = p_start + (p_end - p_start) / 2
                rate = (float(row["value"]) / days_in_p) if (pd.notna(row["value"]) and days_in_p > 0) else 0.0
                midpoints.append(midpoint)
                rates.append(rate)

            rate_series = pd.Series(rates, index=pd.DatetimeIndex(midpoints))
            combined_index = rate_series.index.union(daily_df["day"]).sort_values()
            interpolated = rate_series.reindex(combined_index).interpolate(method="time").bfill().ffill()
            daily_df["rate"] = interpolated.reindex(daily_df["day"]).values
            daily_df["value"] = 0.0

            for _, row in case_df.iterrows():
                p_start = pd.Timestamp(row["period_start"])
                if native_resolution == "month":
                    days_in_p = int(p_start.days_in_month)
                else:
                    days_in_p = 366 if p_start.is_leap_year else 365
                p_end = p_start + pd.DateOffset(days=days_in_p - 1)
                mask = (daily_df["day"] >= p_start) & (daily_df["day"] <= p_end)
                period_slice = daily_df.loc[mask]
                if not period_slice.empty and pd.notna(row["value"]):
                    rate_sum = period_slice["rate"].sum()
                    if rate_sum > 0:
                        scale = float(row["value"]) / rate_sum
                        daily_df.loc[mask, "value"] = (daily_df.loc[mask, "rate"] * scale).round(3)
                    else:
                        daily_df.loc[mask, "value"] = round(float(row["value"]) / len(period_slice), 3)

        daily_df["period"] = daily_df["day"].dt.strftime("%Y-%m-%d")
        case_agg = daily_df[["period", "value"]].copy()
        steps.append(
            f"Applied mass-preserving smooth temporal downscaling to {disease.label} {native_resolution}ly "
            f"surveillance counts to generate continuous daily trajectories while preserving reported {native_resolution}ly totals."
        )
    else:
        case_df["period"] = _period_label(case_df["period_start"], resolution)
        case_agg = case_df.groupby("period", as_index=False)["value"].sum()

    climate_fetch_resolution = "day" if resolution == "day" else ("month" if resolution == "month" else "year")
    if climate_source == "tmd":
        climate_df = fetch_tmd_climate(
            region, variables, start, end, resolution=climate_fetch_resolution
        )
    elif climate_source == "custom_upload":
        content_to_use = climate_upload_content or upload_content
        if not content_to_use:
            raise ValueError("No CSV file uploaded for climate data source 'custom_upload'.")
        climate_df = fetch_climate(
            region,
            variables,
            start,
            end,
            source="custom_upload",
            resolution=climate_fetch_resolution,
            upload_content=content_to_use,
        )
        steps.append(
            f"Parsed user-uploaded meteorological CSV dataset for {', '.join(variables)} "
            f"and aligned to {_RESOLUTION_LABEL[climate_fetch_resolution]} resolution."
        )
    else:
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

    pop_df = get_population_data(
        region,
        start,
        end,
        resolution=resolution,
        source=population_source,
        custom_source_url=custom_population_url,
        upload_content=population_upload_content,
        indicator_code=population_indicator_code,
    )

    merged = pd.merge(case_agg, climate_df, on="period", how="outer")
    if not pop_df.empty:
        merged = pd.merge(merged, pop_df, on="period", how="left")
    merged = merged.sort_values("period")

    steps.append(
        f"Temporally joined the {disease.label} and climate series on a "
        f"shared {_RESOLUTION_LABEL[resolution]} period key, producing "
        f"{len(merged)} aligned rows."
    )
    if not pop_df.empty:
        if population_source == "custom_upload":
            pop_source_label = "User-uploaded demographic dataset"
        elif population_source == "custom_url":
            pop_source_label = f"User-provided demographic URL: {custom_population_url}"
        elif population_source == "worldbank_indicator":
            pop_source_label = f"World Bank Indicator '{population_indicator_name or population_indicator_code}' ({population_indicator_code})"
        else:
            pop_source_label = POPULATION_SOURCES.get(population_source, {}).get("label", population_source)
        steps.append(
            f"Linked demographic population series for {region} ({pop_source_label}) "
            f"and calculated disease incidence rate per 100,000 population."
        )

    def clean(value):
        return None if value is None or pd.isna(value) else float(value)

    records = []
    for _, row in merged.iterrows():
        case_val = clean(row.get("value"))
        pop_val = clean(row.get("population"))
        incidence_val = None
        if case_val is not None and pop_val is not None and pop_val > 0:
            incidence_val = round((case_val / pop_val) * 100000.0, 3)

        records.append(
            PeriodRecord(
                period=row["period"],
                case_count=case_val,
                population=pop_val,
                incidence_rate_per_100k=incidence_val,
                temperature_mean_c=clean(row.get("temperature_2m_mean")),
                precipitation_sum_mm=clean(row.get("precipitation_sum")),
            )
        )

    transformation_audit_data = case_df.attrs.get("transformation_audit")
    stat_summary = compute_statistics(records, resolution)
    if stat_summary.correlations:
        sig_corrs = [c for c in stat_summary.correlations if c.significant]
        if sig_corrs:
            sig_desc = ", ".join(
                f"{c.variable} at Lag {c.lag_periods} (r={c.pearson_r}, p={c.pearson_p})"
                for c in sig_corrs[:3]
            )
            steps.append(
                f"Conducted cross-correlation analysis across time lags (Lags 0-3). "
                f"Identified statistically significant associations (p < 0.05): {sig_desc}."
            )
        else:
            steps.append(
                "Conducted cross-correlation analysis across time lags (Lags 0-3). "
                "No statistically significant bivariate association was detected at alpha=0.05."
            )

    return steps, records, resolution, transformation_audit_data, stat_summary

