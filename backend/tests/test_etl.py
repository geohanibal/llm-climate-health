"""Unit tests for the pure helper functions in app.services.etl.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

from datetime import date
from unittest.mock import patch

import pandas as pd

from app.config import DISEASES
from app.services.etl import _period_label, _target_resolution, resolve_case_data, run_integration


def test_target_resolution_honors_requested_aggregation():
    assert _target_resolution("month", "yearly") == "year"
    assert _target_resolution("month", "decadal") == "decade"


def test_target_resolution_falls_back_to_native_resolution():
    assert _target_resolution("month", "native") == "month"
    assert _target_resolution("year", "native") == "year"


def test_period_label_month():
    series = pd.to_datetime(pd.Series(["2020-01-15", "2020-02-01"]))
    assert list(_period_label(series, "month")) == ["2020-01", "2020-02"]


def test_period_label_year():
    series = pd.to_datetime(pd.Series(["2020-01-15", "2021-06-01"]))
    assert list(_period_label(series, "year")) == ["2020", "2021"]


def test_period_label_decade():
    series = pd.to_datetime(pd.Series(["2013-01-15", "2024-06-01"]))
    assert list(_period_label(series, "decade")) == ["2010s", "2020s"]


def test_resolve_case_data_custom_upload_branch():
    steps: list[str] = []
    df = resolve_case_data(
        DISEASES["dengue"],
        "Thailand",
        date(2020, 1, 1),
        date(2020, 12, 31),
        "custom_upload",
        None,
        b"month,cases\n2020-01,5\n2020-02,7\n",
        steps,
    )
    assert df["value"].tolist() == [5, 7]
    assert "uploaded" in steps[-1]


@patch("app.services.etl.get_case_data_from_url")
def test_resolve_case_data_custom_url_branch(mock_fetch):
    steps: list[str] = []
    mock_fetch.return_value = pd.DataFrame(
        {"period_start": pd.to_datetime(["2020-01-01"]), "value": [3]}
    )
    df = resolve_case_data(
        DISEASES["dengue"],
        "Thailand",
        date(2020, 1, 1),
        date(2020, 12, 31),
        "custom_url",
        "https://example.org/data.csv",
        None,
        steps,
    )
    assert df["value"].tolist() == [3]
    assert "example.org/data.csv" in steps[-1]


@patch("app.services.etl.fetch_who_gho_case_data")
def test_resolve_case_data_who_gho_branch(mock_fetch):
    steps: list[str] = []
    mock_fetch.return_value = pd.DataFrame(
        {"period_start": pd.to_datetime(["2020-01-01"]), "value": [9]}
    )
    df = resolve_case_data(
        DISEASES["malaria"],
        "Thailand",
        date(2020, 1, 1),
        date(2020, 12, 31),
        "who_gho",
        None,
        None,
        steps,
        who_indicator_code="MALARIA_EST_CASES",
        who_indicator_name="Estimated malaria cases",
    )
    assert df["value"].tolist() == [9]
    mock_fetch.assert_called_once_with(
        "MALARIA_EST_CASES", "THA", date(2020, 1, 1), date(2020, 12, 31)
    )


def test_resolve_case_data_builtin_branch_is_the_default():
    steps: list[str] = []
    df = resolve_case_data(
        DISEASES["dengue"], "Thailand", date(2020, 1, 1), date(2020, 3, 31), "builtin", None, None, steps
    )
    assert not df.empty
    assert "built-in source" in steps[-1]


@patch("app.services.etl.fetch_climate")
def test_run_integration_decadal_aggregation_averages_yearly_climate(mock_climate):
    mock_climate.return_value = pd.DataFrame(
        {
            "period": ["2020", "2021"],
            "temperature_2m_mean": [25.0, 27.0],
            "precipitation_sum": [100.0, 200.0],
        }
    )
    steps, records, resolution, audit, stat_summary = run_integration(
        "dengue",
        "Thailand",
        ["temperature", "precipitation"],
        date(2020, 1, 1),
        date(2021, 12, 31),
        aggregation="decadal",
    )
    assert resolution == "decade"
    assert len(records) == 1
    assert records[0].period == "2020s"
    assert records[0].temperature_mean_c == 26.0
    assert records[0].precipitation_sum_mm == 150.0
    assert any("decade" in s for s in steps)
    assert stat_summary is not None


@patch("app.services.etl.fetch_climate")
def test_run_integration_with_lag_periods_and_buffer(mock_climate):
    # Climate covers buffer (2019-10..2019-12) plus requested (2020-01..2020-03)
    mock_climate.return_value = pd.DataFrame(
        {
            "period": ["2019-10", "2019-11", "2019-12", "2020-01", "2020-02", "2020-03"],
            "temperature_2m_mean": [21.0, 22.0, 23.0, 24.0, 25.0, 26.0],
            "precipitation_sum": [10.0, 11.0, 12.0, 13.0, 14.0, 15.0],
        }
    )
    steps, records, resolution, audit, stat_summary = run_integration(
        "dengue",
        "Thailand",
        ["temperature", "precipitation"],
        date(2020, 1, 1),
        date(2020, 3, 31),
        aggregation="native",
        lag_periods=[1, 3],
    )
    assert resolution == "month"
    # First record is 2020-01 (buffer months 2019-10..2019-12 are NOT in records)
    assert records[0].period == "2020-01"
    assert records[0].temperature_lag1 == 23.0
    assert records[0].temperature_lag3 == 21.0
    assert records[0].precipitation_lag1 == 12.0
    assert records[0].precipitation_lag3 == 10.0
    # Provenance steps mention buffer and lags
    assert any("lag buffer" in s for s in steps)
    assert any("lags 1, 3" in s for s in steps)


