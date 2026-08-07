"""Application configuration: environment, regions, and data-source registry.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

import json
import os
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv

load_dotenv()

GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")
GEMINI_MODEL = os.environ.get("GEMINI_MODEL", "gemini-flash-lite-latest")

BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"

with open(DATA_DIR / "region_registry.json", encoding="utf-8") as f:
    _RAW_REGIONS = json.load(f)  # ISO3 -> {name, lat, lon}

# Every country the platform can fetch climate data for (climate reanalysis
# coverage is effectively global). Keyed by display name, since that is what
# the frontend shows/sends; each entry keeps its ISO3 code to join against
# disease-specific case-count files and the world-map GeoJSON.
REGIONS = {
    info["name"]: {
        "iso3": iso3,
        "lat": info["lat"],
        "lon": info["lon"],
        "label": info["name"],
    }
    for iso3, info in _RAW_REGIONS.items()
}
_ISO3_TO_NAME = {v["iso3"]: name for name, v in REGIONS.items()}


class DiseaseMeta:
    def __init__(self, key: str, label: str, native_resolution: str, data_file: str, value_col: str, citation: str):
        self.key = key
        self.label = label
        self.native_resolution = native_resolution  # "month" or "year"
        self.data_file = data_file
        self.value_col = value_col
        self.citation = citation


DISEASES: dict[str, DiseaseMeta] = {
    "dengue": DiseaseMeta(
        "dengue", "Dengue", "month", "dengue_monthly_by_iso3.csv", "dengue_total",
        "Clarke et al. (2024), Scientific Data — A global dataset of publicly "
        "available dengue case count data (OpenDengue, opendengue.org)",
    ),
    "malaria": DiseaseMeta(
        "malaria", "Malaria", "year", "malaria_annual_by_iso3.csv", "cases",
        "WHO Global Health Observatory, indicator MALARIA_EST_CASES — "
        "estimated number of malaria cases (modelled) (who.int/data/gho)",
    ),
    "cholera": DiseaseMeta(
        "cholera", "Cholera", "year", "cholera_annual_by_iso3.csv", "cases",
        "WHO Global Health Observatory, indicator CHOLERA_0000000001 — "
        "number of reported cases of cholera (who.int/data/gho)",
    ),
}


def _regions_with_data(data_file: str) -> set[str]:
    path = DATA_DIR / data_file
    if not path.exists():
        return set()
    df = pd.read_csv(path)
    if "iso3" not in df.columns or df.empty:
        return set()
    return {_ISO3_TO_NAME[i] for i in df["iso3"].unique() if i in _ISO3_TO_NAME}


DISEASES_WITH_DATA: dict[str, set[str]] = {
    key: _regions_with_data(meta.data_file) for key, meta in DISEASES.items()
}

CLIMATE_SOURCES = {
    "open-meteo-era5": {
        "label": "Open-Meteo Historical Archive (ECMWF ERA5 reanalysis)",
        "citation": "Hersbach et al. (2020), ERA5 reanalysis, via Open-Meteo (open-meteo.com)",
    },
    "nasa-power": {
        "label": "NASA POWER (Prediction of Worldwide Energy Resources)",
        "citation": "NASA Langley Research Center POWER Project (power.larc.nasa.gov)",
    },
}

CASE_DATA_SOURCES = {
    "builtin": {
        "label": "Built-in scientific source for the selected disease",
        "citation": "See disease metadata",
    },
    "custom_url": {
        "label": "Custom URL (user-provided CSV of scientific/official case data)",
        "citation": "User-provided source",
    },
    "custom_upload": {
        "label": "Uploaded file (user-provided CSV of scientific/official case data)",
        "citation": "User-provided source",
    },
}

AGGREGATIONS = ["native", "yearly", "decadal"]
