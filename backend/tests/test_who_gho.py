"""Unit tests for app.services.who_gho. requests.get is mocked throughout so
these never touch the network.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

from datetime import date
from unittest.mock import MagicMock, patch

import pytest

from app.services.who_gho import fetch_who_gho_case_data, search_indicators


def _mock_response(payload: dict) -> MagicMock:
    resp = MagicMock()
    resp.raise_for_status = MagicMock()
    resp.json.return_value = payload
    return resp


@patch("app.services.who_gho.requests.get")
def test_search_indicators_returns_code_and_name(mock_get):
    mock_get.return_value = _mock_response(
        {"value": [{"IndicatorCode": "MALARIA_EST_CASES", "IndicatorName": "Estimated malaria cases"}]}
    )
    assert search_indicators("malaria") == [
        {"code": "MALARIA_EST_CASES", "name": "Estimated malaria cases"}
    ]


@patch("app.services.who_gho.requests.get")
def test_fetch_who_gho_case_data_returns_rows_in_range(mock_get):
    mock_get.return_value = _mock_response(
        {
            "value": [
                {"TimeDimType": "YEAR", "TimeDim": 2019, "NumericValue": 100, "SpatialDim": "THA"},
                {"TimeDimType": "YEAR", "TimeDim": 2020, "NumericValue": 150, "SpatialDim": "THA"},
                {"TimeDimType": "YEAR", "TimeDim": 2021, "NumericValue": 200, "SpatialDim": "THA"},
            ]
        }
    )
    df = fetch_who_gho_case_data("MALARIA_EST_CASES", "THA", date(2020, 1, 1), date(2021, 12, 31))
    assert df["value"].tolist() == [150.0, 200.0]


@patch("app.services.who_gho.requests.get")
def test_fetch_who_gho_case_data_raises_when_no_rows(mock_get):
    mock_get.return_value = _mock_response({"value": []})
    with pytest.raises(ValueError):
        fetch_who_gho_case_data("MALARIA_EST_CASES", "THA", date(2020, 1, 1), date(2021, 12, 31))


def test_fetch_who_gho_case_data_rejects_unsafe_indicator_code():
    with pytest.raises(ValueError):
        fetch_who_gho_case_data(
            "bad code!; DROP TABLE", "THA", date(2020, 1, 1), date(2021, 12, 31)
        )
