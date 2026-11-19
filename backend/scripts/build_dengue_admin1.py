"""Offline build script for regional (Admin1) monthly dengue case-count datasets.

Downloads (or reads from local paths) the pinned OpenDengue V1.3 Spatial
extract ZIP and each configured country's HDX COD-AB administrative boundaries
XLSX, maps OpenDengue province/department names (`adm_1_name`) to official HDX
Admin1 English names and P-codes via `backend/app/data/admin1_name_map_<ISO3>.csv`,
verifies that no duplicate `(admin1_pcode, month)` rows exist, and writes the
bundled datasets `backend/app/data/dengue_monthly_admin1_<ISO3>.csv`.

Configured countries (all monthly in OpenDengue V1.3 Spatial extract, FR-28):
- THA (Thailand): 77 HDX provinces (`TH10`..`TH96`), 1993-2022, 27,024 rows.
  HDX cod-ab-tha: CC BY-IGO, source Royal Thai Survey Department.
- LAO (Lao PDR): 18 HDX provinces (`LA01`..`LA18`), 1998-2010, 2,419 mapped rows
  (16 mapped provinces; `VIENTIANE CAPITAL` and `VIENTIANE CAPITAL [PREFECTURE]`
  both left unresolved: same `FAO_GAUL_code=1768` / `RNE_iso_code=LA-VI` and
  same 156 months, different counts, unclear which is LA01 and which LA10).
  HDX cod-ab-lao: CC BY-IGO, source National Geographic Department (NGD).
- LKA (Sri Lanka): 9 HDX provinces (`LK1`..`LK9`), 1996-2004, 960 rows.
  HDX cod-ab-lka: CC BY-IGO, source Survey Department of Sri Lanka (http://www.survey.gov.lk).
- SLV (El Salvador): 14 HDX departments (`SV01`..`SV14`), 2000-2009, 1,587 rows.
  HDX cod-ab-slv: CC BY-IGO, source www.gadm.org.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis — Tasks H & I / FR-28)
"""

from __future__ import annotations

import argparse
import io
import re
import sys
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path
from typing import Any

import pandas as pd
import requests

OPENDENGUE_SPATIAL_ZIP_URL = (
    "https://raw.githubusercontent.com/OpenDengue/master-repo/main/"
    "data/releases/V1.3/Spatial_extract_V1_3.zip"
)
HDX_PACKAGE_SHOW_URL = "https://data.humdata.org/api/3/action/package_show?id={package_id}"

BACKEND_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BACKEND_DIR / "app" / "data"

# Per-country configuration table (Task I, requirement A).
# Any name that cannot be matched automatically by case/space/hyphen-insensitive
# comparison is resolved ONLY when backed by verifiable evidence in OpenDengue's
# own columns (`RNE_iso_code`, `FAO_GAUL_code`) or HDX's `adm1_ref_name`.
# Ambiguous names lacking non-colliding evidence are listed in `unresolved_notes`,
# recorded with empty `hdx_admin1_name`/`admin1_pcode` in the name map CSV, and
# excluded from the output dataset CSV (Rule 3).
ADMIN1_COUNTRY_CONFIGS: dict[str, dict[str, Any]] = {
    "THA": {
        "adm_0_name": "THAILAND",
        "hdx_package_id": "cod-ab-tha",
        "hdx_sheet_name": "tha_admin1",
        "hand_verified_overrides": {
            "BUNGKAN": (
                "Bueng Kan",
                "TH38",
                "Romanisation variant for Bueng Kan (RNE_iso_code=TH-38, FAO_GAUL_code=26787); "
                "split from Nong Khai (TH43) in 2011 (present 2011-2022, 144 rows)",
            ),
            "KAMPAENG PHET": (
                "Kamphaeng Phet",
                "TH62",
                "Romanisation variant for Kamphaeng Phet (RNE_iso_code=TH-62, FAO_GAUL_code=2864)",
            ),
            "PHACHINBURI": (
                "Prachin Buri",
                "TH25",
                "Extra 78th name: spelling variant for Prachin Buri used in OpenDengue for 2003-2022 "
                "(240 rows, same FAO_GAUL_code=2888 and RNE_iso_code=TH-25 as PRACHIN BURI 1993-2002; non-overlapping)",
            ),
            "PHRA NAKHON SI AYUDHYA": (
                "Phra Nakhon Si Ayutthaya",
                "TH14",
                "Romanisation variant for Phra Nakhon Si Ayutthaya (RNE_iso_code=TH-14, FAO_GAUL_code=2896)",
            ),
            "PRACHUAP KHILIKHAN": (
                "Prachuap Khiri Khan",
                "TH77",
                "Romanisation variant for Prachuap Khiri Khan (RNE_iso_code=TH-77, FAO_GAUL_code=2899)",
            ),
            "SAMUT PRAKARN": (
                "Samut Prakan",
                "TH11",
                "Romanisation variant for Samut Prakan (RNE_iso_code=TH-11, FAO_GAUL_code=2906)",
            ),
            "SAMUT SONGKHAM": (
                "Samut Songkhram",
                "TH75",
                "Romanisation variant for Samut Songkhram (RNE_iso_code=TH-75, FAO_GAUL_code=2908)",
            ),
            "TRAD": (
                "Trat",
                "TH23",
                "Romanisation variant for Trat (RNE_iso_code=TH-23, FAO_GAUL_code=2919)",
            ),
        },
        "special_coverage_notes": {
            "PRACHIN BURI": (
                "Exact match (case-insensitive); used in OpenDengue for 1993-2002 "
                "(120 rows, FAO_GAUL_code=2888, RNE_iso_code=TH-25); 2003-2022 rows use PHACHINBURI"
            ),
            "AMNAT CHAROEN": "Exact match (case-insensitive); present in OpenDengue from 2003-2022 (240 rows)",
            "MUKDAHAN": "Exact match (case-insensitive); present in OpenDengue from 2003-2022 (240 rows)",
            "NONG BUA LAMPHU": (
                "Normalized match (space difference, RNE_iso_code=TH-39); "
                "present in OpenDengue from 2003-2022 (240 rows)"
            ),
            "SA KAEO": "Exact match (case-insensitive); present in OpenDengue from 2003-2022 (240 rows)",
        },
        "unresolved_notes": {},
    },
    "LAO": {
        "adm_0_name": "LAO PEOPLE'S DEMOCRATIC REPUBLIC",
        "hdx_package_id": "cod-ab-lao",
        "hdx_sheet_name": "lao_admin1",
        "hand_verified_overrides": {
            "ATTAPU": (
                "Attapeu",
                "LA17",
                "Romanisation variant for Attapeu (RNE_iso_code=LA-AT, FAO_GAUL_code=1753)",
            ),
            "CHAMPASAK": (
                "Champasack",
                "LA16",
                "Romanisation variant for Champasack (RNE_iso_code=LA-CH, FAO_GAUL_code=1756)",
            ),
            "PHONGSALI": (
                "Phongsaly",
                "LA02",
                "Romanisation variant for Phongsaly (RNE_iso_code=LA-PH, FAO_GAUL_code=1762); "
                "missing 2008 and 2009-08 in OpenDengue (143 rows)",
            ),
            "XAIGNABOULI": (
                "Xaignabouly",
                "LA08",
                "Romanisation variant for Xaignabouly (RNE_iso_code=LA-XA, FAO_GAUL_code=1765)",
            ),
            "XAISOMBOUN": (
                "Xaisomboon",
                "LA18",
                "Romanisation variant for Xaisomboon (FAO_GAUL_code=74346, RNE_iso_code=LA-VI); "
                "present 1998-2005 only (96 rows); reason for the gap 2006-2010 not verified from a source",
            ),
            "XEKONG": (
                "Sekong",
                "LA15",
                "Romanisation variant for Sekong (RNE_iso_code=LA-XE, FAO_GAUL_code=1766); "
                "missing 4 months in 2007 in OpenDengue (152 rows)",
            ),
            "XIANGKHOUANG": (
                "Xiengkhouang",
                "LA09",
                "Romanisation variant for Xiengkhouang (RNE_iso_code=LA-XI, FAO_GAUL_code=74347)",
            ),
        },
        "special_coverage_notes": {},
        "unresolved_notes": {
            # Two OpenDengue series cover the same 156 months (1998-2010) with the same
            # FAO_GAUL_code=1768 / RNE_iso_code=LA-VI, but different counts (7,177 vs
            # 29,223 cases). Historically the capital was called "Vientiane Prefecture",
            # so the larger "[PREFECTURE]" series may be the capital and the plain one
            # Vientiane Province (LA10) - but no source says so. Both are excluded
            # until the assignment is confirmed (review by Claude, 2026-11-19).
            "VIENTIANE CAPITAL": (
                "UNRESOLVED: same FAO_GAUL_code=1768 / RNE_iso_code=LA-VI and same 156 months as "
                "VIENTIANE CAPITAL [PREFECTURE] but different counts; unclear whether this series is "
                "Vientiane Capital (LA01) or Vientiane Province (LA10); excluded"
            ),
            "VIENTIANE CAPITAL [PREFECTURE]": (
                "UNRESOLVED: shares identical FAO_GAUL_code=1768 and RNE_iso_code=LA-VI with VIENTIANE CAPITAL "
                "across all 156 months (1998-2010); HDX LA10 (Vientiane Province) has no distinct code in OpenDengue; "
                "excluded from CSV to avoid guessing or duplicate collision"
            ),
        },
    },
    "LKA": {
        "adm_0_name": "SRI LANKA",
        "hdx_package_id": "cod-ab-lka",
        "hdx_sheet_name": "lka_admin1",
        "hand_verified_overrides": {},
        "special_coverage_notes": {
            "EASTERN": (
                "Exact match (case-insensitive); year 2000 absent in OpenDengue "
                "(96 rows across 1996-1999 and 2001-2004)"
            ),
        },
        "unresolved_notes": {},
    },
    "SLV": {
        "adm_0_name": "EL SALVADOR",
        "hdx_package_id": "cod-ab-slv",
        "hdx_sheet_name": "slv_admin1",
        "hand_verified_overrides": {
            "AHUACHAPAN": (
                "Ahuachapán",
                "SV01",
                "Spanish diacritic difference (matches HDX adm1_ref_name=Ahuachapan; RNE_iso_code=SV-AH, FAO_GAUL_code=1184)",
            ),
            "CABANAS": (
                "Cabañas",
                "SV02",
                "Spanish diacritic difference (matches HDX adm1_ref_name=Cabanas; RNE_iso_code=SV-CA, FAO_GAUL_code=1185)",
            ),
            "CUSCATLAN": (
                "Cuscatlán",
                "SV04",
                "Spanish diacritic difference (matches HDX adm1_ref_name=Cuscatlan; RNE_iso_code=SV-CU, FAO_GAUL_code=1187)",
            ),
            "LA UNION": (
                "La Unión",
                "SV07",
                "Spanish diacritic difference (matches HDX adm1_ref_name=La Union; RNE_iso_code=SV-UN, FAO_GAUL_code=1190)",
            ),
            "MORAZAN": (
                "Morazán",
                "SV08",
                "Spanish diacritic difference (matches HDX adm1_ref_name=Morazan; RNE_iso_code=SV-MO, FAO_GAUL_code=1191)",
            ),
            "USULUTAN": (
                "Usulután",
                "SV14",
                "Spanish diacritic difference (matches HDX adm1_ref_name=Usulutan; RNE_iso_code=SV-US, FAO_GAUL_code=1197)",
            ),
        },
        "special_coverage_notes": {
            "SAN SALVADOR": (
                "Exact match (case-insensitive); present in OpenDengue Admin1 from 2003-01 to 2009-08 "
                "(80 rows; 2000-2002 absent)"
            ),
            "SANTA ANA": (
                "Exact match (case-insensitive); present 2000-01 to 2009-07 "
                "(115 rows; 2009-08 absent)"
            ),
        },
        "unresolved_notes": {},
    },
}

# Backward-compatible aliases for existing callers/tests
NAME_MAP_PATH = DATA_DIR / "admin1_name_map_THA.csv"
OUTPUT_CSV_PATH = DATA_DIR / "dengue_monthly_admin1_THA.csv"
HAND_VERIFIED_OVERRIDES = ADMIN1_COUNTRY_CONFIGS["THA"]["hand_verified_overrides"]
SPECIAL_COVERAGE_NOTES = ADMIN1_COUNTRY_CONFIGS["THA"]["special_coverage_notes"]


def normalize_key(name: str) -> str:
    """Case-insensitive normalisation ignoring spaces and hyphens."""
    return re.sub(r"[\s\-]+", "", str(name).strip().lower())


def read_hdx_admin1_xlsx(xlsx_source: Path | bytes, sheet_name: str = "tha_admin1") -> pd.DataFrame:
    """Reads the `<iso3>_admin1` worksheet from an HDX COD-AB `*_admin_boundaries.xlsx` file.

    Uses standard-library `zipfile` + `xml.etree.ElementTree` so the build
    script runs cleanly without requiring `openpyxl` in minimal environments.
    """
    ns = {"main": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
    zf_arg = io.BytesIO(xlsx_source) if isinstance(xlsx_source, bytes) else xlsx_source
    with zipfile.ZipFile(zf_arg, "r") as z:
        shared_strings: list[str] = []
        if "xl/sharedStrings.xml" in z.namelist():
            root = ET.fromstring(z.read("xl/sharedStrings.xml"))
            for si in root.findall("main:si", ns):
                texts = [t.text or "" for t in si.findall(".//main:t", ns)]
                shared_strings.append("".join(texts))

        wb_root = ET.fromstring(z.read("xl/workbook.xml"))
        rels_root = ET.fromstring(z.read("xl/_rels/workbook.xml.rels"))
        rid_to_target = {rel.attrib["Id"]: rel.attrib["Target"] for rel in rels_root}

        target_xml = None
        for sh in wb_root.findall(".//main:sheet", ns):
            name = sh.attrib.get("name", "")
            rid = sh.attrib.get(
                "{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id", ""
            )
            target = rid_to_target.get(rid, "")
            if not target.startswith("xl/"):
                target = "xl/" + target.lstrip("/")
            if name.lower() == sheet_name.lower():
                target_xml = target
                break

        if target_xml is None:
            raise ValueError(f"Worksheet '{sheet_name}' not found in HDX XLSX")

        sheet_root = ET.fromstring(z.read(target_xml))

        def _col_index(cell_ref: str) -> int:
            letters = "".join(c for c in cell_ref if c.isalpha())
            idx = 0
            for ch in letters:
                idx = idx * 26 + (ord(ch.upper()) - ord("A") + 1)
            return idx - 1

        rows_data: list[list[str | None]] = []
        for row in sheet_root.findall(".//main:sheetData/main:row", ns):
            row_dict: dict[int, str | None] = {}
            for c in row.findall("main:c", ns):
                ref = c.attrib.get("r", "A1")
                c_type = c.attrib.get("t", "")
                v_el = c.find("main:v", ns)
                is_el = c.find("main:is", ns)
                val: str | None = None
                if c_type == "s" and v_el is not None and v_el.text is not None:
                    val = shared_strings[int(v_el.text)]
                elif c_type == "inlineStr" and is_el is not None:
                    val = "".join(t.text or "" for t in is_el.findall(".//main:t", ns))
                elif v_el is not None and v_el.text is not None:
                    val = v_el.text
                row_dict[_col_index(ref)] = val
            if row_dict:
                max_c = max(row_dict.keys())
                rows_data.append([row_dict.get(i) for i in range(max_c + 1)])

        headers = [str(h).strip() if h is not None else f"col_{i}" for i, h in enumerate(rows_data[0])]
        padded = [r + [None] * (len(headers) - len(r)) for r in rows_data[1:]]
        df = pd.DataFrame(padded, columns=headers)
        return (
            df[["adm1_pcode", "adm1_name"]]
            .dropna()
            .drop_duplicates()
            .sort_values("adm1_pcode")
            .reset_index(drop=True)
        )


def fetch_hdx_xlsx_bytes(package_id: str = "cod-ab-tha") -> bytes:
    """Fetches HDX COD-AB package metadata and downloads its `.xlsx` resource."""
    api_url = HDX_PACKAGE_SHOW_URL.format(package_id=package_id)
    resp = requests.get(api_url, timeout=60)
    resp.raise_for_status()
    payload = resp.json()
    resources = payload.get("result", {}).get("resources", [])
    xlsx_url = None
    for res in resources:
        name = str(res.get("name", ""))
        url = str(res.get("url") or res.get("download_url") or "")
        if name.lower().endswith(".xlsx") or url.lower().endswith(".xlsx"):
            xlsx_url = url
            break
    if not xlsx_url:
        raise RuntimeError(f"No XLSX resource found in HDX package {package_id}")
    r_xlsx = requests.get(xlsx_url, timeout=120)
    r_xlsx.raise_for_status()
    return r_xlsx.content


def load_opendengue_admin1_monthly_all(
    zip_source: Path | bytes,
    adm_0_names: set[str],
) -> pd.DataFrame:
    """Extracts Admin1 monthly rows for the given `adm_0_name` set from OpenDengue V1.3 Spatial extract ZIP."""
    target_upper = {n.strip().upper() for n in adm_0_names}
    zf_arg = io.BytesIO(zip_source) if isinstance(zip_source, bytes) else zip_source
    with zipfile.ZipFile(zf_arg, "r") as z:
        csv_names = [n for n in z.namelist() if n.lower().endswith(".csv")]
        if not csv_names:
            raise ValueError("No CSV found inside OpenDengue Spatial extract ZIP")
        with z.open(csv_names[0]) as f:
            chunks = []
            for chunk in pd.read_csv(f, chunksize=100_000, low_memory=False):
                mask = (
                    chunk["adm_0_name"].astype(str).str.strip().str.upper().isin(target_upper)
                    & (chunk["S_res"].astype(str).str.strip() == "Admin1")
                    & (chunk["T_res"].astype(str).str.strip() == "Month")
                )
                sub = chunk.loc[mask]
                if not sub.empty:
                    chunks.append(sub)
            if not chunks:
                return pd.DataFrame()
            return pd.concat(chunks, ignore_index=True)


def build_or_update_name_map(
    od_df: pd.DataFrame,
    hdx_df: pd.DataFrame,
    map_path: Path,
    hand_verified_overrides: dict[str, tuple[str, str, str]] | None = None,
    special_coverage_notes: dict[str, str] | None = None,
    unresolved_notes: dict[str, str] | None = None,
) -> tuple[pd.DataFrame, list[str], list[str], list[str]]:
    """Maps distinct OpenDengue `adm_1_name` values to HDX `(adm1_name, adm1_pcode)`.

    Order of resolution:
    1. Automatic normalized matching (case-insensitive, ignoring spaces and hyphens)
       against the country's HDX `adm1_name` strings.
    2. Existing hand-checkable mapping CSV (`map_path`) if already present and populated.
    3. Explicit hand-verified overrides (`hand_verified_overrides`) backed by
       OpenDengue's `RNE_iso_code` / `FAO_GAUL_code` or HDX's `adm1_ref_name`.
    4. Anything still unmatched is written to `map_path` with empty HDX fields
       and an explicit unresolved explanation in `note` (never guessed silently).

    Returns `(map_df, auto_matched, hand_mapped, unmatched)`.
    """
    overrides = hand_verified_overrides if hand_verified_overrides is not None else HAND_VERIFIED_OVERRIDES
    coverage_notes = special_coverage_notes if special_coverage_notes is not None else SPECIAL_COVERAGE_NOTES
    unres_notes = unresolved_notes or {}

    hdx_by_norm: dict[str, tuple[str, str]] = {
        normalize_key(r["adm1_name"]): (str(r["adm1_name"]).strip(), str(r["adm1_pcode"]).strip())
        for _, r in hdx_df.iterrows()
    }

    existing_map: dict[str, tuple[str, str, str]] = {}
    if map_path.exists():
        existing_df = pd.read_csv(map_path, dtype=str).fillna("")
        for _, r in existing_df.iterrows():
            od_n = r.get("opendengue_name", "").strip()
            h_n = r.get("hdx_admin1_name", "").strip()
            h_p = r.get("admin1_pcode", "").strip()
            note = r.get("note", "").strip()
            if od_n and h_n and h_p:
                existing_map[od_n] = (h_n, h_p, note)

    od_names = sorted(od_df["adm_1_name"].dropna().astype(str).str.strip().unique())
    rows = []
    auto_matched: list[str] = []
    hand_mapped: list[str] = []
    unmatched: list[str] = []

    for od_name in od_names:
        norm_od = normalize_key(od_name)
        # Names declared unresolved win over any automatic name match: an exact
        # spelling match is not evidence when the source itself is ambiguous.
        if od_name in unres_notes:
            unmatched.append(od_name)
            rows.append(
                {
                    "opendengue_name": od_name,
                    "hdx_admin1_name": "",
                    "admin1_pcode": "",
                    "note": unres_notes[od_name],
                }
            )
            continue
        if norm_od in hdx_by_norm:
            h_name, h_pcode = hdx_by_norm[norm_od]
            if od_name in coverage_notes:
                note = coverage_notes[od_name]
            elif od_name.lower() == h_name.lower():
                note = "Exact match (case-insensitive)"
            else:
                note = "Normalized match (space/hyphen difference)"
            auto_matched.append(od_name)
            rows.append(
                {
                    "opendengue_name": od_name,
                    "hdx_admin1_name": h_name,
                    "admin1_pcode": h_pcode,
                    "note": note,
                }
            )
        elif od_name in existing_map:
            h_name, h_pcode, note = existing_map[od_name]
            hand_mapped.append(od_name)
            rows.append(
                {
                    "opendengue_name": od_name,
                    "hdx_admin1_name": h_name,
                    "admin1_pcode": h_pcode,
                    "note": note,
                }
            )
        elif od_name in overrides:
            h_name, h_pcode, note = overrides[od_name]
            hand_mapped.append(od_name)
            rows.append(
                {
                    "opendengue_name": od_name,
                    "hdx_admin1_name": h_name,
                    "admin1_pcode": h_pcode,
                    "note": note,
                }
            )
        else:
            unmatched.append(od_name)
            note = unres_notes.get(od_name, "UNMATCHED: requires human review")
            rows.append(
                {
                    "opendengue_name": od_name,
                    "hdx_admin1_name": "",
                    "admin1_pcode": "",
                    "note": note,
                }
            )

    map_df = pd.DataFrame(rows, columns=["opendengue_name", "hdx_admin1_name", "admin1_pcode", "note"])
    map_path.parent.mkdir(parents=True, exist_ok=True)
    map_df.to_csv(map_path, index=False)
    return map_df, auto_matched, hand_mapped, unmatched


def build_country_dataset(
    iso3: str,
    od_country_df: pd.DataFrame,
    hdx_df: pd.DataFrame,
    map_path: Path | None = None,
    output_csv_path: Path | None = None,
) -> dict[str, Any]:
    """Builds `admin1_name_map_<ISO3>.csv` and `dengue_monthly_admin1_<ISO3>.csv` for one country."""
    iso3_code = iso3.strip().upper()
    cfg = ADMIN1_COUNTRY_CONFIGS[iso3_code]
    resolved_map_path = map_path or (DATA_DIR / f"admin1_name_map_{iso3_code}.csv")
    resolved_out_path = output_csv_path or (DATA_DIR / f"dengue_monthly_admin1_{iso3_code}.csv")

    if od_country_df.empty:
        raise RuntimeError(f"No {iso3_code} Admin1 Monthly rows found in OpenDengue extract")

    map_df, auto_matched, hand_mapped, unmatched = build_or_update_name_map(
        od_country_df,
        hdx_df,
        resolved_map_path,
        hand_verified_overrides=cfg["hand_verified_overrides"],
        special_coverage_notes=cfg["special_coverage_notes"],
        unresolved_notes=cfg.get("unresolved_notes", {}),
    )

    print("\n" + "=" * 72)
    print(f"{iso3_code} ADMIN1 MONTHLY DENGUE BUILD SUMMARY")
    print("=" * 72)
    print(f"HDX COD-AB ({cfg['hdx_package_id']}) Admin1 units: {len(hdx_df)}")
    print(f"OpenDengue raw {iso3_code} Admin1 monthly rows: {len(od_country_df)}")
    print(f"Distinct OpenDengue adm_1_name values: {len(map_df)}")
    print(f"  - Automatically matched (case/space/hyphen-insensitive): {len(auto_matched)}")
    print(f"  - Resolved via hand-checked mapping table: {len(hand_mapped)} -> {hand_mapped}")
    print(f"  - Unresolved names excluded from CSV: {len(unmatched)} -> {unmatched}")

    resolved_rows = map_df[map_df["admin1_pcode"].astype(str).str.strip() != ""]
    name_to_pcode = dict(zip(resolved_rows["opendengue_name"], resolved_rows["admin1_pcode"]))
    name_to_hdx_name = dict(zip(resolved_rows["opendengue_name"], resolved_rows["hdx_admin1_name"]))

    od_clean_name = od_country_df["adm_1_name"].astype(str).str.strip()
    mapped_mask = od_clean_name.isin(name_to_pcode)
    excluded_rows_count = int((~mapped_mask).sum())
    if excluded_rows_count > 0:
        print(f"  - Rows excluded due to unresolved adm_1_name: {excluded_rows_count}")

    od_mapped = od_country_df.loc[mapped_mask].copy()
    od_mapped_names = od_clean_name.loc[mapped_mask]

    out = pd.DataFrame()
    out["iso3"] = iso3_code
    out["admin1_pcode"] = od_mapped_names.map(name_to_pcode).values
    out["admin1_name"] = od_mapped_names.map(name_to_hdx_name).values
    out["month"] = pd.to_datetime(od_mapped["calendar_start_date"], errors="raise").dt.strftime("%Y-%m").values
    out["dengue_total"] = pd.to_numeric(od_mapped["dengue_total"], errors="raise").astype(int).values
    out["case_definition"] = od_mapped["case_definition_standardised"].astype(str).str.strip().values
    out["iso3"] = iso3_code

    # Duplicate check on (admin1_pcode, month) — never sum duplicates silently (Rule 5)
    dup_mask = out.duplicated(subset=["admin1_pcode", "month"], keep=False)
    dup_count = int(dup_mask.sum())
    print(f"Duplicate (admin1_pcode, month) rows detected: {dup_count}")
    if dup_count > 0:
        dup_preview = out.loc[dup_mask, ["admin1_pcode", "admin1_name", "month", "dengue_total"]].head(10)
        print("Duplicate rows sample:\n", dup_preview.to_string(index=False))
        raise RuntimeError(
            f"Found {dup_count} duplicate (admin1_pcode, month) rows for {iso3_code}; refusing to sum silently."
        )

    out = out.sort_values(["admin1_pcode", "month"]).reset_index(drop=True)
    resolved_out_path.parent.mkdir(parents=True, exist_ok=True)
    out.to_csv(resolved_out_path, index=False)

    out["_year"] = out["month"].str.slice(0, 4).astype(int)
    prov_per_year = out.groupby("_year")["admin1_pcode"].nunique()

    print(f"\nOutput file: {resolved_out_path}")
    print(f"Total rows written: {len(out)} (sum of dengue_total = {int(out['dengue_total'].sum())})")
    print(f"Distinct mapped HDX Admin1 P-codes: {out['admin1_pcode'].nunique()}")
    print(f"Period covered: {out['month'].min()} to {out['month'].max()}")

    print("\nRegions per year:")
    for yr, cnt in prov_per_year.items():
        print(f"  {yr}: {cnt} regions")

    print("\ncase_definition counts per year:")
    cd_table = out.groupby(["_year", "case_definition"]).size().unstack(fill_value=0)
    print(cd_table.to_string())
    print("=" * 72)

    return {
        "iso3": iso3_code,
        "total_rows": len(out),
        "total_cases": int(out["dengue_total"].sum()),
        "excluded_rows": excluded_rows_count,
        "distinct_pcodes": int(out["admin1_pcode"].nunique()),
        "distinct_od_names": len(map_df),
        "auto_matched": auto_matched,
        "hand_mapped": hand_mapped,
        "unmatched": unmatched,
        "duplicates": dup_count,
    }


def build_dataset(
    spatial_zip_path: Path | None = None,
    hdx_xlsx_path: Path | None = None,
    map_path: Path = NAME_MAP_PATH,
    output_csv_path: Path = OUTPUT_CSV_PATH,
    iso3_list: list[str] | None = None,
    hdx_dir: Path | None = None,
) -> dict[str, Any]:
    """Builds regional Admin1 monthly dengue datasets for `iso3_list` (default: all configured).

    When called with single-country arguments (`map_path`/`output_csv_path` or a
    single ISO3), returns that country's summary dict for backward compatibility.
    """
    targets = [c.strip().upper() for c in (iso3_list or list(ADMIN1_COUNTRY_CONFIGS.keys()))]
    for code in targets:
        if code not in ADMIN1_COUNTRY_CONFIGS:
            raise ValueError(
                f"Unsupported ISO3 code {code!r}; configured: {list(ADMIN1_COUNTRY_CONFIGS.keys())}"
            )

    adm_0_names = {ADMIN1_COUNTRY_CONFIGS[c]["adm_0_name"] for c in targets}
    if spatial_zip_path is not None and spatial_zip_path.exists():
        print(f"Loading OpenDengue V1.3 Spatial extract from local file: {spatial_zip_path}")
        od_all = load_opendengue_admin1_monthly_all(spatial_zip_path, adm_0_names)
    else:
        print(f"Downloading OpenDengue V1.3 Spatial extract from: {OPENDENGUE_SPATIAL_ZIP_URL}")
        resp = requests.get(OPENDENGUE_SPATIAL_ZIP_URL, timeout=300)
        resp.raise_for_status()
        od_all = load_opendengue_admin1_monthly_all(resp.content, adm_0_names)

    results: dict[str, dict[str, Any]] = {}
    for code in targets:
        cfg = ADMIN1_COUNTRY_CONFIGS[code]
        sheet_name = cfg["hdx_sheet_name"]
        pkg_id = cfg["hdx_package_id"]

        local_xlsx: Path | None = None
        if hdx_xlsx_path is not None and len(targets) == 1 and hdx_xlsx_path.exists():
            local_xlsx = hdx_xlsx_path
        elif hdx_dir is not None:
            candidate = hdx_dir / f"{code.lower()}_admin_boundaries.xlsx"
            if candidate.exists():
                local_xlsx = candidate

        if local_xlsx is not None:
            print(f"Loading HDX Admin1 boundaries for {code} from local file: {local_xlsx}")
            hdx_df = read_hdx_admin1_xlsx(local_xlsx, sheet_name=sheet_name)
        else:
            print(f"Fetching HDX Admin1 boundaries for {code} ({pkg_id})...")
            hdx_df = read_hdx_admin1_xlsx(fetch_hdx_xlsx_bytes(pkg_id), sheet_name=sheet_name)

        od_country = od_all[
            od_all["adm_0_name"].astype(str).str.strip().str.upper() == cfg["adm_0_name"].upper()
        ].copy()

        c_map_path = map_path if (len(targets) == 1 and map_path != NAME_MAP_PATH) else (DATA_DIR / f"admin1_name_map_{code}.csv")
        c_out_path = output_csv_path if (len(targets) == 1 and output_csv_path != OUTPUT_CSV_PATH) else (DATA_DIR / f"dengue_monthly_admin1_{code}.csv")

        results[code] = build_country_dataset(
            iso3=code,
            od_country_df=od_country,
            hdx_df=hdx_df,
            map_path=c_map_path,
            output_csv_path=c_out_path,
        )

    return results[targets[0]] if len(targets) == 1 else results


def main(argv: list[str] | None = None) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(
        description="Build bundled regional (Admin1) monthly dengue case datasets (FR-28)."
    )
    parser.add_argument(
        "iso3",
        nargs="*",
        default=list(ADMIN1_COUNTRY_CONFIGS.keys()),
        help=f"ISO3 country codes to build (default: {' '.join(ADMIN1_COUNTRY_CONFIGS.keys())}).",
    )
    parser.add_argument(
        "--spatial-zip",
        type=Path,
        default=None,
        help="Optional local path to Spatial_extract_V1_3.zip (downloads from GitHub if omitted).",
    )
    parser.add_argument(
        "--hdx-xlsx",
        type=Path,
        default=None,
        help="Optional local path to a single country's *_admin_boundaries.xlsx.",
    )
    parser.add_argument(
        "--hdx-dir",
        type=Path,
        default=None,
        help="Optional directory containing cached <iso3>_admin_boundaries.xlsx files.",
    )
    args = parser.parse_args(argv)
    build_dataset(
        spatial_zip_path=args.spatial_zip,
        hdx_xlsx_path=args.hdx_xlsx,
        iso3_list=args.iso3,
        hdx_dir=args.hdx_dir,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
