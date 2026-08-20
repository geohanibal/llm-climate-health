"""Unit tests for app.services.case_data.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

from datetime import date

import pandas as pd
import pytest

from app.config import DISEASES
from app.services.case_data import _filter_range, _normalize_custom_frame, get_builtin_case_data


def test_get_builtin_case_data_returns_rows_in_range():
    df = get_builtin_case_data(
        DISEASES["dengue"], "Thailand", date(2020, 1, 1), date(2020, 3, 31)
    )
    assert not df.empty
    assert list(df.columns) == ["period_start", "value"]
    assert df["period_start"].min() >= pd.Timestamp(2020, 1, 1)
    assert df["period_start"].max() <= pd.Timestamp(2020, 3, 31)


def test_get_builtin_case_data_unknown_region_is_empty():
    df = get_builtin_case_data(
        DISEASES["dengue"], "Nowhereland", date(2020, 1, 1), date(2020, 12, 31)
    )
    assert df.empty


def test_normalize_custom_frame_detects_known_columns():
    raw = pd.DataFrame({"Date": ["2020-01-01", "2020-02-01"], "Cases": [10, 20]})
    out = _normalize_custom_frame(raw)
    assert list(out.columns) == ["period_start", "value"]
    assert out["value"].tolist() == [10, 20]


def test_normalize_custom_frame_raises_on_unrecognized_columns():
    raw = pd.DataFrame({"foo": [1], "bar": [2]})
    with pytest.raises(ValueError):
        _normalize_custom_frame(raw)


def test_filter_range_keeps_only_rows_inside_bounds():
    df = pd.DataFrame(
        {
            "period_start": pd.to_datetime(["2019-12-01", "2020-06-01", "2021-01-01"]),
            "value": [1, 2, 3],
        }
    )
    out = _filter_range(df, date(2020, 1, 1), date(2020, 12, 31))
    assert out["value"].tolist() == [2]
