"""Unit tests for the pure helper functions in app.services.etl.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

import pandas as pd

from app.services.etl import _period_label, _target_resolution


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
