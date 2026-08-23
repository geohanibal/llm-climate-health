"""Unit tests for app.services.climate. requests.get is mocked throughout so
these never touch the network.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

from datetime import date
from unittest.mock import MagicMock, patch

import pandas as pd

from app.services.climate import _period_key, fetch_climate


def test_period_key_month():
    series = pd.to_datetime(pd.Series(["2020-01-15", "2020-02-01"]))
    assert list(_period_key(series, "month")) == ["2020-01", "2020-02"]


def test_period_key_year():
    series = pd.to_datetime(pd.Series(["2020-01-15", "2021-06-01"]))
    assert list(_period_key(series, "year")) == ["2020", "2021"]


def _mock_response(payload: dict) -> MagicMock:
    resp = MagicMock()
    resp.raise_for_status = MagicMock()
    resp.json.return_value = payload
    return resp


@patch("app.services.climate.requests.get")
def test_fetch_climate_open_meteo_aggregates_to_month(mock_get):
    mock_get.return_value = _mock_response(
        {
            "daily": {
                "time": ["2020-01-01", "2020-01-02", "2020-02-01"],
                "temperature_2m_mean": [20.0, 22.0, 25.0],
                "precipitation_sum": [1.0, 2.0, 3.0],
            }
        }
    )
    df = fetch_climate(
        "Thailand",
        ["temperature", "precipitation"],
        date(2020, 1, 1),
        date(2020, 2, 28),
        source="open-meteo-era5",
        resolution="month",
    )
    assert set(df["period"]) == {"2020-01", "2020-02"}
    jan = df[df["period"] == "2020-01"].iloc[0]
    assert jan["temperature_2m_mean"] == 21.0  # mean of 20 and 22
    assert jan["precipitation_sum"] == 3.0  # sum of 1 and 2
    # Fixed UTC, not "auto": a per-point local timezone would shift which
    # day/month a boundary reading falls into depending on the region.
    assert mock_get.call_args.kwargs["params"]["timezone"] == "UTC"


@patch("app.services.climate.requests.get")
def test_fetch_climate_all_missing_precipitation_stays_null_not_zero(mock_get):
    """Regression test: a period where every reading is missing (NASA
    POWER's -999.0 sentinel, already replaced with NA upstream) must sum to
    NaN, not 0.0 — a real zero-rainfall reading has to stay distinguishable
    from "no data for this period"."""
    mock_get.return_value = _mock_response(
        {
            "properties": {
                "parameter": {
                    "T2M": {"20200101": 20.0, "20200102": 22.0},
                    "PRECTOTCORR": {"20200101": -999.0, "20200102": -999.0},
                }
            }
        }
    )
    df = fetch_climate(
        "Thailand",
        ["temperature", "precipitation"],
        date(2020, 1, 1),
        date(2020, 1, 31),
        source="nasa-power",
        resolution="month",
    )
    jan = df[df["period"] == "2020-01"].iloc[0]
    assert pd.isna(jan["precipitation_sum"])


@patch("app.services.climate.requests.get")
def test_fetch_climate_nasa_power_aggregates_to_month(mock_get):
    mock_get.return_value = _mock_response(
        {
            "properties": {
                "parameter": {
                    "T2M": {"20200101": 20.0, "20200201": 24.0},
                    "PRECTOTCORR": {"20200101": 1.0, "20200201": 2.0},
                }
            }
        }
    )
    df = fetch_climate(
        "Thailand",
        ["temperature", "precipitation"],
        date(2020, 1, 1),
        date(2020, 2, 28),
        source="nasa-power",
        resolution="month",
    )
    assert set(df["period"]) == {"2020-01", "2020-02"}
