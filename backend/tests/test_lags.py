"""Tests for lagged climate feature generation and lag buffer calculation.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

from datetime import date
import numpy as np
import pandas as pd
import pytest
from pydantic import ValidationError

from app.models import IntegrationRequest, PeriodRecord
from app.services.lags import add_lagged_climate_features, calculate_buffer_start_date


def test_integration_request_lag_periods_default_is_empty():
    req = IntegrationRequest(
        disease="dengue",
        region="Thailand",
        start_date=date(2020, 1, 1),
        end_date=date(2020, 6, 1),
    )
    assert req.lag_periods == []


def test_integration_request_lag_periods_valid_range():
    req = IntegrationRequest(
        disease="dengue",
        region="Thailand",
        start_date=date(2020, 1, 1),
        end_date=date(2020, 6, 1),
        lag_periods=[3, 1, 2],
    )
    # Automatically sorted and deduplicated
    assert req.lag_periods == [1, 2, 3]


@pytest.mark.parametrize("invalid_lag", [0, 7, -1, 10])
def test_integration_request_lag_periods_rejects_out_of_range(invalid_lag):
    with pytest.raises(ValidationError):
        IntegrationRequest(
            disease="dengue",
            region="Thailand",
            start_date=date(2020, 1, 1),
            end_date=date(2020, 6, 1),
            lag_periods=[1, invalid_lag],
        )


def test_calculate_buffer_start_date_monthly():
    start = date(2010, 1, 1)
    # max lag 3 months -> 2009-10-01
    buf = calculate_buffer_start_date(start, [1, 3], resolution="month")
    assert buf == date(2009, 10, 1)

    # max lag 1 month -> 2009-12-01
    buf1 = calculate_buffer_start_date(start, [1], resolution="month")
    assert buf1 == date(2009, 12, 1)


def test_calculate_buffer_start_date_daily():
    start = date(2020, 3, 15)
    buf = calculate_buffer_start_date(start, [1, 5], resolution="day")
    assert buf == date(2020, 3, 10)


def test_calculate_buffer_start_date_yearly():
    start = date(2015, 1, 1)
    buf = calculate_buffer_start_date(start, [2], resolution="year")
    assert buf == date(2013, 1, 1)


def test_calculate_buffer_start_date_decadal():
    start = date(2010, 1, 1)
    buf = calculate_buffer_start_date(start, [2], resolution="decade")
    assert buf == date(1990, 1, 1)


def test_calculate_buffer_empty_lags_returns_same_date():
    start = date(2020, 1, 1)
    assert calculate_buffer_start_date(start, [], resolution="month") == start


def test_add_lagged_climate_features_default_empty():
    df = pd.DataFrame({
        "period": ["2020-01", "2020-02"],
        "temperature_2m_mean": [25.0, 26.0],
    })
    res = add_lagged_climate_features(df, [])
    assert list(res.columns) == ["period", "temperature_2m_mean"]


def test_add_lagged_climate_features_handmade_dataframe_values():
    df = pd.DataFrame({
        "period": ["2020-01", "2020-02", "2020-03", "2020-04", "2020-05"],
        "temperature_2m_mean": [20.0, 22.0, 24.0, 26.0, 28.0],
        "precipitation_sum": [10.0, 15.0, 20.0, 25.0, 30.0],
    })
    res = add_lagged_climate_features(df, [1, 3])

    assert "temperature_lag1" in res.columns
    assert "temperature_lag3" in res.columns
    assert "precipitation_lag1" in res.columns
    assert "precipitation_lag3" in res.columns

    # Period 2020-04 (index 3):
    # lag 1 should be 2020-03 value (24.0 temp, 20.0 precip)
    # lag 3 should be 2020-01 value (20.0 temp, 10.0 precip)
    row_apr = res.loc[res["period"] == "2020-04"].iloc[0]
    assert row_apr["temperature_lag1"] == 24.0
    assert row_apr["temperature_lag3"] == 20.0
    assert row_apr["precipitation_lag1"] == 20.0
    assert row_apr["precipitation_lag3"] == 10.0


def test_add_lagged_climate_features_without_earlier_data_first_k_rows_are_nan():
    """Without an earlier buffer, row 0 has no lag1 and rows 0..2 have no lag3."""
    df = pd.DataFrame({
        "period": ["2020-01", "2020-02", "2020-03"],
        "temperature_2m_mean": [20.0, 22.0, 24.0],
    })
    res = add_lagged_climate_features(df, [1, 3])
    assert pd.isna(res.loc[0, "temperature_lag1"])
    assert pd.isna(res.loc[0, "temperature_lag3"])
    assert pd.isna(res.loc[1, "temperature_lag3"])
    assert pd.isna(res.loc[2, "temperature_lag3"])
    # But lag 1 at index 1 is valid
    assert res.loc[1, "temperature_lag1"] == 20.0


def test_lag_buffer_retains_values_on_initial_output_rows():
    """Simulates fetching buffer months 2009-10..2009-12 prior to 2010-01..2010-03.
    After computing lags and cutting back to 2010-01, row 2010-01 is NOT NaN.
    """
    buffer_periods = ["2009-10", "2009-11", "2009-12", "2010-01", "2010-02", "2010-03"]
    df = pd.DataFrame({
        "period": buffer_periods,
        "temperature_2m_mean": [15.0, 16.0, 17.0, 18.0, 19.0, 20.0],
    })
    lagged = add_lagged_climate_features(df, [1, 3])

    # Cut back to requested period start (2010-01)
    output = lagged[lagged["period"] >= "2010-01"].reset_index(drop=True)
    assert len(output) == 3
    assert output.loc[0, "period"] == "2010-01"

    # In 2010-01, lag1 is 2009-12 (17.0) and lag3 is 2009-10 (15.0) -> neither is NaN!
    assert output.loc[0, "temperature_lag1"] == 17.0
    assert output.loc[0, "temperature_lag3"] == 15.0
    assert not pd.isna(output.loc[0, "temperature_lag1"])
    assert not pd.isna(output.loc[0, "temperature_lag3"])


def test_period_record_serializes_dynamic_lag_columns():
    rec = PeriodRecord(
        period="2020-01",
        case_count=100.0,
        temperature_mean_c=25.0,
        temperature_lag1=24.0,
        temperature_lag3=22.5,
    )
    dumped = rec.model_dump()
    assert dumped["period"] == "2020-01"
    assert dumped["temperature_lag1"] == 24.0
    assert dumped["temperature_lag3"] == 22.5


def test_add_lagged_climate_features_missing_monthly_period_yields_nan():
    """If 2019-12 is missing, 2020-01's lag1 must be NaN, not silently getting 2019-11."""
    df = pd.DataFrame({
        "period": ["2019-10", "2019-11", "2020-01"],
        "temperature_2m_mean": [20.0, 22.0, 24.0],
    })
    res = add_lagged_climate_features(df, [1])
    assert len(res) == 3
    # 2019-10 has no earlier period
    assert pd.isna(res.loc[res["period"] == "2019-10", "temperature_lag1"].iloc[0])
    # 2019-11 lag1 is 2019-10 value (20.0)
    assert res.loc[res["period"] == "2019-11", "temperature_lag1"].iloc[0] == 20.0
    # 2020-01 lag1 must be NaN because 2019-12 is absent
    assert pd.isna(res.loc[res["period"] == "2020-01", "temperature_lag1"].iloc[0])


def test_add_lagged_climate_features_missing_daily_period_yields_nan():
    """If 2020-05-03 is missing, 2020-05-04's lag1 must be NaN, not silently getting 2020-05-02."""
    df = pd.DataFrame({
        "period": ["2020-05-01", "2020-05-02", "2020-05-04"],
        "temperature_2m_mean": [25.0, 26.0, 28.0],
    })
    res = add_lagged_climate_features(df, [1], resolution="day")
    assert len(res) == 3
    # 2020-05-01 has no earlier day
    assert pd.isna(res.loc[res["period"] == "2020-05-01", "temperature_lag1"].iloc[0])
    # 2020-05-02 lag1 is 2020-05-01 value (25.0)
    assert res.loc[res["period"] == "2020-05-02", "temperature_lag1"].iloc[0] == 25.0
    # 2020-05-04 lag1 must be NaN because 2020-05-03 was missing
    assert pd.isna(res.loc[res["period"] == "2020-05-04", "temperature_lag1"].iloc[0])


