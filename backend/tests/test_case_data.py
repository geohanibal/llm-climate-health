"""Unit tests for app.services.case_data.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

from datetime import date

import pandas as pd
import pytest

from app.config import DISEASES
from app.services.case_data import (
    _filter_range,
    _normalize_custom_frame,
    get_builtin_case_data,
    get_case_data_from_upload,
)


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


def test_normalize_custom_frame_parses_bare_year_column():
    """Regression test: a plain int `year` column used to be handed to
    pd.to_datetime unformatted, which pandas reads as nanoseconds since the
    epoch (collapsing every row to 1970) — silently filtering out all data
    downstream instead of raising. This is the same column shape as the
    project's own builtin malaria/cholera CSVs, so a very plausible
    real-world custom-upload shape."""
    raw = pd.DataFrame({"year": [2020, 2021, 2022], "cases": [10, 20, 30]})
    out = _normalize_custom_frame(raw)
    assert out["period_start"].dt.year.tolist() == [2020, 2021, 2022]
    filtered = _filter_range(out, date(2020, 1, 1), date(2022, 12, 31))
    assert filtered["value"].tolist() == [10, 20, 30]


def test_normalize_custom_frame_parses_year_month_column():
    raw = pd.DataFrame({"month": ["2020-03", "2020-01"], "cases": [7, 3]})
    out = _normalize_custom_frame(raw)
    assert out["period_start"].tolist() == list(
        pd.to_datetime(["2020-03-01", "2020-01-01"])
    )


def test_get_case_data_from_upload_survives_year_only_csv():
    content = b"year,cases\n2020,10\n2021,20\n"
    df = get_case_data_from_upload(content, date(2019, 1, 1), date(2022, 1, 1))
    assert df["value"].tolist() == [10, 20]


def test_normalize_custom_frame_skips_unparseable_rows_without_failing_the_batch():
    """One malformed date shouldn't sink an otherwise-good CSV — but the
    skip must be recorded (in `.attrs`), never silent."""
    raw = pd.DataFrame(
        {"date": ["2020-01-01", "not-a-date", "2020-03-01"], "cases": [10, 20, 30]}
    )
    out = _normalize_custom_frame(raw)
    assert out["value"].tolist() == [10, 30]
    assert out.attrs["dropped_rows"] == 1


def test_normalize_custom_frame_raises_when_every_date_is_unparseable():
    raw = pd.DataFrame({"date": ["not-a-date", "also-not-a-date"], "cases": [10, 20]})
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
