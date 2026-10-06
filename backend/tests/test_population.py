"""Tests for population data service and temporal resolution alignment."""

from datetime import date
import pandas as pd
from app.services.population import get_population_data, _load_builtin_population


def test_builtin_population_loaded():
    df = _load_builtin_population()
    assert not df.empty
    assert "iso3" in df.columns
    assert "year" in df.columns
    assert "population" in df.columns
    assert "THA" in df["iso3"].values


def test_get_population_data_yearly():
    df = get_population_data("Thailand", date(2018, 1, 1), date(2022, 12, 31), resolution="year")
    assert not df.empty
    assert list(df.columns) == ["period", "population"]
    assert "2018" in df["period"].values
    assert "2022" in df["period"].values
    # Thailand population is ~70-72 million
    row_2020 = df[df["period"] == "2020"]
    assert len(row_2020) == 1
    assert 65_000_000 < row_2020.iloc[0]["population"] < 75_000_000


def test_get_population_data_monthly():
    df = get_population_data("Thailand", date(2020, 1, 1), date(2020, 12, 31), resolution="month")
    assert not df.empty
    assert len(df) == 12
    assert "2020-01" in df["period"].values
    assert "2020-12" in df["period"].values
    assert all(df["population"] > 60_000_000)


def test_get_population_data_decadal():
    df = get_population_data("Thailand", date(2000, 1, 1), date(2023, 12, 31), resolution="decade")
    assert not df.empty
    assert "2000s" in df["period"].values
    assert "2010s" in df["period"].values
    assert "2020s" in df["period"].values
    # Check that decadal averages are increasing
    pop_2000s = df[df["period"] == "2000s"].iloc[0]["population"]
    pop_2010s = df[df["period"] == "2010s"].iloc[0]["population"]
    assert pop_2010s > pop_2000s


def test_get_population_unknown_region():
    df = get_population_data("NonExistentCountry999", date(2020, 1, 1), date(2021, 12, 31), resolution="year")
    assert df.empty
    assert list(df.columns) == ["period", "population"]


def test_search_population_sources():
    from app.services.population import search_population_sources

    results = search_population_sources("Thailand", "urban")
    assert len(results) > 0
    assert any("Urban" in r.title for r in results)
    assert any(r.indicator_code == "SP.URB.TOTL" for r in results)

    # Empty query should return default indicators
    all_results = search_population_sources("Thailand", "")
    assert len(all_results) >= 8


def test_parse_custom_population_csv():
    from app.services.population import parse_custom_population_csv

    csv_data = b"year,population\n2018,70000000\n2019,70500000\n2020,71000000\n"
    df = parse_custom_population_csv(csv_data)
    assert not df.empty
    assert len(df) == 3
    assert "period_start" in df.columns
    assert "population" in df.columns
    assert df.iloc[0]["population"] == 70000000.0


def test_get_population_custom_upload():
    csv_data = b"date,persons\n2020-01-01,69500000\n2021-01-01,70000000\n"
    df = get_population_data(
        "Thailand",
        date(2020, 1, 1),
        date(2021, 12, 31),
        resolution="year",
        population_source="custom_upload",
        upload_content=csv_data,
    )
    assert not df.empty
    assert len(df) == 2
    assert "2020" in df["period"].values
    assert df.loc[df["period"] == "2020", "population"].iloc[0] == 69500000.0


def test_get_population_daily_resolution():
    df = get_population_data(
        "Thailand",
        date(2020, 1, 1),
        date(2020, 1, 10),
        resolution="day",
    )
    assert not df.empty
    assert len(df) == 10
    assert "2020-01-01" in df["period"].values
    assert "2020-01-10" in df["period"].values
    assert all(df["population"] > 60_000_000)

