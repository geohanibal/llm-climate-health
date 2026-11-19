"""Unit tests for app.services.case_data.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

from datetime import date

import pandas as pd
import pytest

from app.config import DATA_DIR, DISEASES, REGIONAL_CASE_DATA_SOURCES
from app.services.case_data import (
    CHANGED_UNITS,
    _filter_range,
    _normalize_custom_frame,
    get_builtin_case_data,
    get_case_data_from_upload,
    load_dengue_admin1,
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
    df.attrs["dropped_rows"] = 0
    filtered = _filter_range(df, date(2020, 1, 1), date(2020, 12, 31))
    assert filtered["value"].tolist() == [2]


def test_normalize_custom_frame_detects_extended_aliases_and_audit():
    raw = pd.DataFrame({"period": ["2021-01", "2021-02"], "malaria_cases": [45, 60]})
    out = _normalize_custom_frame(raw)
    assert list(out.columns) == ["period_start", "value"]
    assert out["value"].tolist() == [45, 60]
    audit = out.attrs.get("transformation_audit")
    assert audit is not None
    assert audit["selected_date_column"] == "period"
    assert audit["selected_value_column"] == "malaria_cases"
    assert audit["total_rows_received"] == 2
    assert audit["valid_rows_retained"] == 2


def test_normalize_custom_frame_fuzzy_matching():
    raw = pd.DataFrame({"observation_date": ["2022-05-01"], "confirmed_cases_count": [120]})
    out = _normalize_custom_frame(raw)
    assert out["value"].tolist() == [120]


def test_normalize_custom_frame_informative_error_on_spatial_data():
    raw = pd.DataFrame(
        {
            "county": ["BARINGO", "BOMET"],
            "had_fever_or_malaria_in_percent": [14.9, 39.5],
            "spending_per_person_in_ksh": [714.0, 666.0],
        }
    )
    with pytest.raises(ValueError) as exc:
        _normalize_custom_frame(raw)
    assert "time-series date column" in str(exc.value)


# ---------------------------------------------------------------------------
# FR-28 / Task H: Regional (Admin1) monthly dengue loader tests
# ---------------------------------------------------------------------------


@pytest.fixture
def admin1_fixture_dir(tmp_path, monkeypatch):
    """Creates a small synthetic Thailand Admin1 dengue CSV fixture for unit tests.

    Notice month 2015-02 is intentionally omitted so tests can verify that
    gaps inside [start, end] remain absent (rule A20).
    """
    csv_content = (
        "iso3,admin1_pcode,admin1_name,month,dengue_total,case_definition\n"
        "THA,TH10,Bangkok,2010-12,50,Suspected and confirmed\n"
        "THA,TH43,Nong Khai,2010-12,12,Suspected and confirmed\n"
        "THA,TH10,Bangkok,2015-01,100,Suspected and confirmed\n"
        "THA,TH43,Nong Khai,2015-01,25,Suspected and confirmed\n"
        "THA,TH38,Bueng Kan,2015-01,15,Suspected and confirmed\n"
        "THA,TH10,Bangkok,2015-03,110,Suspected and confirmed\n"
        "THA,TH43,Nong Khai,2015-03,30,Suspected and confirmed\n"
        "THA,TH38,Bueng Kan,2015-03,8,Suspected and confirmed\n"
        "THA,TH10,Bangkok,2016-01,90,Suspected and confirmed\n"
    )
    (tmp_path / "dengue_monthly_admin1_THA.csv").write_text(csv_content, encoding="utf-8")
    monkeypatch.setattr("app.services.case_data.DATA_DIR", tmp_path)
    return tmp_path


def test_load_dengue_admin1_filters_range_and_keeps_missing_months_absent(admin1_fixture_dir):
    df = load_dengue_admin1("THA", date(2015, 1, 1), date(2015, 3, 31), merge_changed_units=True)
    assert list(df.columns) == ["admin1_pcode", "admin1_name", "month", "cases"]
    assert df["month"].min() >= pd.Timestamp(2015, 1, 1)
    assert df["month"].max() <= pd.Timestamp(2015, 3, 31)
    # 2015-02 is missing in the fixture and must stay absent (never filled, rule A20)
    months_present = set(df["month"].dt.strftime("%Y-%m"))
    assert months_present == {"2015-01", "2015-03"}


def test_load_dengue_admin1_fixture_merges_bueng_kan_into_nong_khai(admin1_fixture_dir):
    assert CHANGED_UNITS["THA"] == {"TH38": "TH43"}
    df = load_dengue_admin1("THA", date(2010, 1, 1), date(2015, 12, 31), merge_changed_units=True)
    assert "TH38" not in set(df["admin1_pcode"])
    assert "Bueng Kan" not in set(df["admin1_name"])

    nk_2015_01 = df[(df["admin1_pcode"] == "TH43") & (df["month"] == pd.Timestamp(2015, 1, 1))]
    assert len(nk_2015_01) == 1
    assert nk_2015_01.iloc[0]["admin1_name"] == "Nong Khai"
    assert nk_2015_01.iloc[0]["cases"] == 25 + 15

    nk_2010_12 = df[(df["admin1_pcode"] == "TH43") & (df["month"] == pd.Timestamp(2010, 12, 1))]
    assert len(nk_2010_12) == 1
    assert nk_2010_12.iloc[0]["cases"] == 12


def test_load_dengue_admin1_fixture_without_merge_preserves_bueng_kan(admin1_fixture_dir):
    df = load_dengue_admin1("THA", date(2010, 1, 1), date(2015, 12, 31), merge_changed_units=False)
    assert "TH38" in set(df["admin1_pcode"])
    bk_rows = df[df["admin1_pcode"] == "TH38"]
    assert bk_rows["cases"].tolist() == [15, 8]
    nk_2015_01 = df[(df["admin1_pcode"] == "TH43") & (df["month"] == pd.Timestamp(2015, 1, 1))]
    assert nk_2015_01.iloc[0]["cases"] == 25


def test_load_dengue_admin1_unknown_iso3_raises_value_error():
    with pytest.raises(ValueError, match="no regional dengue data for ZZZ"):
        load_dengue_admin1("ZZZ", date(2015, 1, 1), date(2015, 12, 31))


@pytest.mark.parametrize("bad_iso3", ["", "TH", "THAI", "../x", "T1A"])
def test_load_dengue_admin1_rejects_non_iso3_input(bad_iso3):
    # Anything that is not a plain alpha-3 code must never become part of a file path.
    with pytest.raises(ValueError, match="no regional dengue data"):
        load_dengue_admin1(bad_iso3, date(2015, 1, 1), date(2015, 12, 31))


def test_load_dengue_admin1_bundled_thailand_file():
    """End-to-end verification on the real bundled Thailand Admin1 CSV."""
    raw_csv = pd.read_csv(DATA_DIR / "dengue_monthly_admin1_THA.csv")
    assert len(raw_csv) == 27_024

    # 1. With merge_changed_units=True (Suttirat et al. 2026, p. 5)
    merged = load_dengue_admin1("THA", date(1993, 1, 1), date(2022, 12, 31), merge_changed_units=True)
    assert "TH38" not in set(merged["admin1_pcode"])

    # Verify a 2015 month: merged Nong Khai equals raw Nong Khai + raw Bueng Kan
    raw_nk_2015_06 = int(
        raw_csv[(raw_csv["admin1_pcode"] == "TH43") & (raw_csv["month"] == "2015-06")]["dengue_total"].iloc[0]
    )
    raw_bk_2015_06 = int(
        raw_csv[(raw_csv["admin1_pcode"] == "TH38") & (raw_csv["month"] == "2015-06")]["dengue_total"].iloc[0]
    )
    merged_nk_2015_06 = int(
        merged[(merged["admin1_pcode"] == "TH43") & (merged["month"] == pd.Timestamp(2015, 6, 1))]["cases"].iloc[0]
    )
    assert raw_bk_2015_06 > 0
    assert merged_nk_2015_06 == raw_nk_2015_06 + raw_bk_2015_06

    # Merged province count per year: 72 in 1993-2002, constant 76 across 2003-2022
    merged_by_year = merged.groupby(merged["month"].dt.year)["admin1_pcode"].nunique()
    for yr in range(1993, 2003):
        assert merged_by_year[yr] == 72
    for yr in range(2003, 2023):
        assert merged_by_year[yr] == 76

    # 2. With merge_changed_units=False (as published in OpenDengue V1.3)
    unmerged = load_dengue_admin1("THA", date(1993, 1, 1), date(2022, 12, 31), merge_changed_units=False)
    bk_unmerged = unmerged[unmerged["admin1_pcode"] == "TH38"]
    assert not bk_unmerged.empty
    assert bk_unmerged["month"].dt.year.min() == 2011
    assert bk_unmerged["month"].dt.year.max() == 2022
    assert len(bk_unmerged) == 144

    unmerged_by_year = unmerged.groupby(unmerged["month"].dt.year)["admin1_pcode"].nunique()
    for yr in range(1993, 2003):
        assert unmerged_by_year[yr] == 72
    for yr in range(2003, 2011):
        assert unmerged_by_year[yr] == 76
    for yr in range(2011, 2023):
        assert unmerged_by_year[yr] == 77


def test_admin1_name_map_and_config_licences_for_thailand():
    name_map = pd.read_csv(DATA_DIR / "admin1_name_map_THA.csv")
    assert list(name_map.columns) == ["opendengue_name", "hdx_admin1_name", "admin1_pcode", "note"]
    assert len(name_map) == 78
    assert name_map["admin1_pcode"].isna().sum() == 0
    assert name_map["admin1_pcode"].nunique() == 77

    meta = REGIONAL_CASE_DATA_SOURCES["THA"]
    assert "CC BY 4.0" in meta["case_license"]
    assert "CC BY-IGO" in meta["boundary_license"]
    assert "Royal Thai Survey Department" in meta["boundary_citation"]

