"""Unit tests for app.config's builtin-data introspection helpers.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

from app.config import CLIMATE_SOURCE_REGIONS, CLIMATE_SOURCES, _region_coverage, _regions_with_data


def test_regions_with_data_missing_file_is_empty(tmp_path, monkeypatch):
    monkeypatch.setattr("app.config.DATA_DIR", tmp_path)
    assert _regions_with_data("does_not_exist.csv") == set()


def test_regions_with_data_empty_file_is_empty(tmp_path, monkeypatch):
    monkeypatch.setattr("app.config.DATA_DIR", tmp_path)
    (tmp_path / "empty.csv").write_text("iso3,year,cases\n")
    assert _regions_with_data("empty.csv") == set()


def test_regions_with_data_drops_unknown_iso3(tmp_path, monkeypatch):
    monkeypatch.setattr("app.config.DATA_DIR", tmp_path)
    (tmp_path / "data.csv").write_text("iso3,year,cases\nTHA,2020,5\nZZZ,2020,3\n")
    assert _regions_with_data("data.csv") == {"Thailand"}


def test_region_coverage_missing_file_is_empty(tmp_path, monkeypatch):
    monkeypatch.setattr("app.config.DATA_DIR", tmp_path)
    assert _region_coverage("does_not_exist.csv", "year") == {}


def test_region_coverage_reports_earliest_and_latest_period(tmp_path, monkeypatch):
    monkeypatch.setattr("app.config.DATA_DIR", tmp_path)
    (tmp_path / "data.csv").write_text("iso3,year,cases\nTHA,2020,5\nTHA,2022,7\nTHA,2021,1\n")
    coverage = _region_coverage("data.csv", "year")
    assert coverage["Thailand"] == ("2020", "2022")


def test_region_coverage_uses_month_column_for_monthly_diseases(tmp_path, monkeypatch):
    monkeypatch.setattr("app.config.DATA_DIR", tmp_path)
    (tmp_path / "data.csv").write_text("iso3,month,dengue_total\nTHA,2020-03,5\nTHA,2020-01,2\n")
    coverage = _region_coverage("data.csv", "month")
    assert coverage["Thailand"] == ("2020-01", "2020-03")


def test_at_least_one_climate_source_is_region_unrestricted():
    """Invariant the frontend relies on: RequestFormCardState seeds its
    initial climate-source dropdown value from the region-filtered options
    list, so that list must never be empty for *any* region — i.e. at least
    one configured climate source must have no region restriction at all."""
    unrestricted = [key for key in CLIMATE_SOURCES if key not in CLIMATE_SOURCE_REGIONS]
    assert unrestricted, "every climate source is region-restricted — the frontend's default-region case would break"
