"""Unit tests for app.services.tmd.

The XML fixtures below mirror a real live response (verified 2026-08-23
against data.tmd.go.th with the published uid=demo/ukey=demokey
credentials) — including TMD's own swapped <Latitude>/<Longitude> tags
(see tmd.py's module docstring): <Latitude> actually holds the station's
longitude, <Longitude> its latitude.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

from datetime import date
from unittest.mock import MagicMock, patch

import pytest

from app.services import tmd as tmd_module
from app.services.tmd import _parse_tmd_response, fetch_tmd_climate, is_available


def _station_xml(
    *, lon: float, lat: float, year: int, rainfall: dict[str, float] | None = None
) -> str:
    rainfall = rainfall or {}
    months = "".join(
        f"<Rainfall{abbr}>{rainfall.get(abbr, 0)}</Rainfall{abbr}>"
        for abbr in ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
    )
    # Note the swap: the <Latitude> tag carries `lon`, <Longitude> carries `lat`.
    return (
        "<StationMonthlyRainfall>"
        f"<Latitude Unit=\"decimal degree\">{lon}</Latitude>"
        f"<Longitude Unit=\"decimal degree\">{lat}</Longitude>"
        f"<Year>{year}</Year>"
        f"<MonthlyRainfall unit=\"mm\">{months}</MonthlyRainfall>"
        "</StationMonthlyRainfall>"
    )


def _document(*stations: str) -> str:
    return f'<?xml version="1.0"?><ThailandMonthlyRainfall version="1.0">{"".join(stations)}</ThailandMonthlyRainfall>'


def test_is_available_false_without_credentials(monkeypatch):
    monkeypatch.setattr("app.services.tmd.TMD_API_UID", "")
    monkeypatch.setattr("app.services.tmd.TMD_API_UKEY", "")
    assert is_available() is False


def test_is_available_true_with_credentials(monkeypatch):
    monkeypatch.setattr("app.services.tmd.TMD_API_UID", "demo")
    monkeypatch.setattr("app.services.tmd.TMD_API_UKEY", "demokey")
    assert is_available() is True


def test_parse_tmd_response_extracts_monthly_rainfall_correcting_swapped_coordinates():
    xml = _document(
        _station_xml(lon=100.5, lat=13.7, year=2020, rainfall={"JAN": 12.5, "FEB": 45.0})
    )
    df = _parse_tmd_response(xml, region_lat=13.7, region_lon=100.5)
    assert list(df["period"])[:2] == ["2020-01", "2020-02"]
    assert list(df["precipitation_sum"])[:2] == [12.5, 45.0]
    assert df["temperature_2m_mean"].isna().all()


def test_parse_tmd_response_picks_the_nearest_station():
    bangkok = _station_xml(lon=100.5, lat=13.7, year=2020, rainfall={"JAN": 1.0})
    chiang_mai = _station_xml(lon=98.97, lat=18.77, year=2020, rainfall={"JAN": 99.0})
    xml = _document(bangkok, chiang_mai)

    df = _parse_tmd_response(xml, region_lat=13.7, region_lon=100.5)
    assert df.iloc[0]["precipitation_sum"] == 1.0  # Bangkok, the nearer station


def test_parse_tmd_response_drops_not_yet_reported_months_in_the_current_year(monkeypatch):
    class _FixedDate(date):
        @classmethod
        def today(cls):
            return date(2020, 6, 15)

    monkeypatch.setattr(tmd_module, "date", _FixedDate)
    xml = _document(
        _station_xml(
            lon=100.5, lat=13.7, year=2020,
            rainfall={"JAN": 1.0, "JUN": 2.0, "JUL": 3.0, "DEC": 4.0},
        )
    )
    df = _parse_tmd_response(xml, region_lat=13.7, region_lon=100.5)
    assert list(df["period"]) == ["2020-01", "2020-02", "2020-03", "2020-04", "2020-05", "2020-06"]


def test_parse_tmd_response_recovers_from_a_duplicated_document():
    """Observed live: TMD's server occasionally concatenates the whole
    document onto itself, which trips the XML parser with "junk after
    document element" — the first copy alone should still parse fine."""
    single = _document(_station_xml(lon=100.5, lat=13.7, year=2020, rainfall={"JAN": 12.5}))
    duplicated = single + single

    df = _parse_tmd_response(duplicated, region_lat=13.7, region_lon=100.5)
    assert df.iloc[0]["precipitation_sum"] == 12.5


def test_parse_tmd_response_raises_on_invalid_xml():
    with pytest.raises(RuntimeError):
        _parse_tmd_response("not xml at all", region_lat=13.7, region_lon=100.5)


def test_parse_tmd_response_raises_when_no_stations_found():
    with pytest.raises(RuntimeError):
        _parse_tmd_response(
            '<?xml version="1.0"?><ThailandMonthlyRainfall></ThailandMonthlyRainfall>',
            region_lat=13.7,
            region_lon=100.5,
        )


@patch("app.services.tmd.requests.get")
def test_fetch_tmd_climate_filters_to_the_requested_range(mock_get, monkeypatch):
    monkeypatch.setattr("app.services.tmd.TMD_API_UID", "demo")
    monkeypatch.setattr("app.services.tmd.TMD_API_UKEY", "demokey")

    class _FixedDate(date):
        @classmethod
        def today(cls):
            return date(2020, 12, 31)

    monkeypatch.setattr(tmd_module, "date", _FixedDate)

    resp = MagicMock()
    resp.raise_for_status = MagicMock()
    resp.text = _document(
        _station_xml(
            lon=100.0, lat=15.0, year=2020,
            rainfall={"JAN": 10.0, "FEB": 20.0, "MAR": 30.0},
        )
    )
    mock_get.return_value = resp

    df = fetch_tmd_climate("Thailand", ["precipitation"], date(2020, 2, 1), date(2020, 3, 31))
    assert list(df["period"]) == ["2020-02", "2020-03"]


def test_fetch_tmd_climate_raises_a_clear_error_without_credentials(monkeypatch):
    monkeypatch.setattr("app.services.tmd.TMD_API_UID", "")
    monkeypatch.setattr("app.services.tmd.TMD_API_UKEY", "")
    with pytest.raises(RuntimeError):
        fetch_tmd_climate("Thailand", ["precipitation"], date(2020, 1, 1), date(2020, 12, 31))
