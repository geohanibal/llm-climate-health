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


def test_load_dengue_admin1_thailand_output_unchanged():
    """Task I Rule 4 & E: verify Thailand bundled output stays unchanged."""
    raw_csv = pd.read_csv(DATA_DIR / "dengue_monthly_admin1_THA.csv")
    assert len(raw_csv) == 27_024
    assert int(raw_csv["dengue_total"].sum()) == 1_410_795
    assert raw_csv["admin1_pcode"].nunique() == 77
    assert raw_csv["month"].min() == "1993-01"
    assert raw_csv["month"].max() == "2022-12"

    unmerged = load_dengue_admin1("THA", date(1993, 1, 1), date(2022, 12, 31), merge_changed_units=False)
    assert len(unmerged) == 27_024
    assert int(unmerged["cases"].sum()) == 1_410_795

    merged = load_dengue_admin1("THA", date(1993, 1, 1), date(2022, 12, 31), merge_changed_units=True)
    assert int(merged["cases"].sum()) == 1_410_795


def test_load_dengue_admin1_bundled_lao_file():
    """Task I: verify bundled Lao PDR (LAO) Admin1 monthly dengue dataset."""
    df = load_dengue_admin1("LAO", date(1998, 1, 1), date(2010, 12, 31))
    assert list(df.columns) == ["admin1_pcode", "admin1_name", "month", "cases"]
    # 2,731 raw OpenDengue rows minus 2 x 156 rows of the two ambiguous Vientiane series = 2,419
    assert len(df) == 2_419
    assert int(df["cases"].sum()) == 63_534
    assert df["admin1_pcode"].nunique() == 16
    assert "LA01" not in set(df["admin1_pcode"])
    assert df["month"].min() == pd.Timestamp(1998, 1, 1)
    assert df["month"].max() == pd.Timestamp(2010, 12, 1)

    # Xaisomboon (LA18) exists only in 1998-2005 in OpenDengue (reason not verified)
    xai = df[df["admin1_pcode"] == "LA18"]
    assert len(xai) == 96
    assert xai["month"].dt.year.min() == 1998
    assert xai["month"].dt.year.max() == 2005

    name_map = pd.read_csv(DATA_DIR / "admin1_name_map_LAO.csv", dtype=str).fillna("")
    assert len(name_map) == 18
    unresolved = name_map[name_map["admin1_pcode"] == ""]
    assert unresolved["opendengue_name"].tolist() == ["VIENTIANE CAPITAL", "VIENTIANE CAPITAL [PREFECTURE]"]


def test_load_dengue_admin1_bundled_lka_file():
    """Task I: verify bundled Sri Lanka (LKA) Admin1 monthly dengue dataset."""
    df = load_dengue_admin1("LKA", date(1996, 1, 1), date(2004, 12, 31))
    assert list(df.columns) == ["admin1_pcode", "admin1_name", "month", "cases"]
    assert len(df) == 960
    assert int(df["cases"].sum()) == 20_868
    assert df["admin1_pcode"].nunique() == 9
    assert df["month"].min() == pd.Timestamp(1996, 1, 1)
    assert df["month"].max() == pd.Timestamp(2004, 12, 1)

    # Year 2000 has 8 provinces (Eastern LK5 is absent in 2000; gaps stay gaps per Rule C / A20)
    by_year = df.groupby(df["month"].dt.year)["admin1_pcode"].nunique()
    assert by_year[2000] == 8
    for yr in [1996, 1997, 1998, 1999, 2001, 2002, 2003, 2004]:
        assert by_year[yr] == 9


def test_load_dengue_admin1_bundled_slv_file():
    """Task I: verify bundled El Salvador (SLV) Admin1 monthly dengue dataset."""
    df = load_dengue_admin1("SLV", date(2000, 1, 1), date(2009, 12, 31))
    assert list(df.columns) == ["admin1_pcode", "admin1_name", "month", "cases"]
    assert len(df) == 1_587
    assert int(df["cases"].sum()) == 41_958
    assert df["admin1_pcode"].nunique() == 14
    assert df["month"].min() == pd.Timestamp(2000, 1, 1)
    assert df["month"].max() == pd.Timestamp(2009, 8, 1)

    # San Salvador (SV10) is absent in 2000-2002 (13 departments) and present 2003-2009 (14 departments)
    by_year = df.groupby(df["month"].dt.year)["admin1_pcode"].nunique()
    for yr in [2000, 2001, 2002]:
        assert by_year[yr] == 13
    for yr in range(2003, 2010):
        assert by_year[yr] == 14


@pytest.mark.parametrize(
    "iso3,expected_source",
    [
        ("THA", "Royal Thai Survey Department"),
        ("LAO", "National Geographic Department (NGD)"),
        ("LKA", "Survey Department of Sri Lanka (http://www.survey.gov.lk)"),
        ("SLV", "www.gadm.org"),
    ],
)
def test_regional_case_data_sources_config_all_countries(iso3, expected_source):
    meta = REGIONAL_CASE_DATA_SOURCES[iso3]
    assert meta["hdx_dataset_source"] == expected_source
    assert (
        meta["hdx_license_title"]
        == "Creative Commons Attribution for Intergovernmental Organisations (CC BY-IGO)"
    )
    assert "CC BY 4.0" in meta["case_license"]
    assert (DATA_DIR / meta["data_file"]).exists()
    assert (DATA_DIR / meta["name_map_file"]).exists()


# ---------------------------------------------------------------------------
# Task J3 / A13: Reproducible national dengue build & comparison tests
# ---------------------------------------------------------------------------


def test_build_dengue_national_comparison_and_weekly_rules(tmp_path):
    """Verifies build_dengue_national helper functions on a synthetic OpenDengue V1.3 extract
    and ensures the script refuses to overwrite the bundled file."""
    from scripts.build_dengue_national import (
        BUNDLED_NATIONAL_CSV_PATH,
        _aggregate_weekly_to_monthly,
        build_national_monthly_df,
        compare_with_bundled,
        run_build_and_compare,
    )

    raw_nat = pd.DataFrame(
        [
            {
                "ISO_A0": "THA",
                "S_res": "Admin0",
                "T_res": "Month",
                "calendar_start_date": "2020-01-01",
                "calendar_end_date": "2020-01-31",
                "dengue_total": 100.0,
            },
            {
                "ISO_A0": "THA",
                "S_res": "Admin0",
                "T_res": "Month",
                "calendar_start_date": "2020-02-01",
                "calendar_end_date": "2020-02-29",
                "dengue_total": 120.0,
            },
            {
                "ISO_A0": "THA",
                "S_res": "Admin0",
                "T_res": "Week",
                "calendar_start_date": "2021-01-29",
                "calendar_end_date": "2021-02-04",
                "dengue_total": 70.0,
            },
        ]
    )

    # 1. Default rule='none' keeps only T_res == 'Month'
    monthly_only = build_national_monthly_df(raw_nat, include_weekly_rule="none")
    assert len(monthly_only) == 2
    assert monthly_only["month"].tolist() == ["2020-01", "2020-02"]
    assert monthly_only["dengue_total"].tolist() == [100.0, 120.0]

    # 2. Weekly rules: 2021-01-29..2021-02-04 has 3 days in Jan (29, 30, 31) and 4 days in Feb (1, 2, 3, 4)
    w_rows = raw_nat[raw_nat["T_res"] == "Week"]
    by_start = _aggregate_weekly_to_monthly(w_rows, "start_date")
    assert by_start.to_dict(orient="records") == [{"iso3": "THA", "month": "2021-01", "dengue_total": 70.0}]

    by_end = _aggregate_weekly_to_monthly(w_rows, "end_date")
    assert by_end.to_dict(orient="records") == [{"iso3": "THA", "month": "2021-02", "dengue_total": 70.0}]

    by_split = _aggregate_weekly_to_monthly(w_rows, "split_by_days").sort_values("month")
    assert by_split["month"].tolist() == ["2021-01", "2021-02"]
    assert by_split["dengue_total"].tolist() == pytest.approx([30.0, 40.0])

    # 3. compare_with_bundled reports exact equality
    cmp_df = compare_with_bundled(monthly_only, monthly_only)
    assert len(cmp_df) == 1
    assert cmp_df.iloc[0]["rows_equal"] == 2
    assert cmp_df.iloc[0]["rows_different"] == 0

    # 4. Refuses to overwrite the bundled file
    with pytest.raises(ValueError, match="Refusing to overwrite the bundled file"):
        run_build_and_compare(out_path=BUNDLED_NATIONAL_CSV_PATH)



