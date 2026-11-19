"""Offline build script for Thailand regional (Admin1) monthly dengue case counts.

Downloads (or reads from local paths) the pinned OpenDengue V1.3 Spatial
extract ZIP and the HDX COD-AB Thailand administrative boundaries XLSX, maps
OpenDengue province names (`adm_1_name`) to official HDX Admin1 English names
and P-codes (`TH10`..`TH96`) via `backend/app/data/admin1_name_map_THA.csv`,
verifies that no duplicate `(admin1_pcode, month)` rows exist, and writes the
bundled dataset `backend/app/data/dengue_monthly_admin1_THA.csv`.

Sources & licences (verified 2026-11-19):
- Cases: OpenDengue V1.3 Spatial extract (Clarke et al. 2024, Sci. Data 11, 296),
  https://raw.githubusercontent.com/OpenDengue/master-repo/main/data/releases/V1.3/Spatial_extract_V1_3.zip
  Licence: CC BY 4.0 (figshare 10.6084/m9.figshare.24259573).
- Administrative boundaries & P-codes: HDX COD-AB Thailand,
  https://data.humdata.org/api/3/action/package_show?id=cod-ab-tha
  (`tha_admin_boundaries.xlsx`, sheet `tha_admin1`, 77 provinces).
  Source: Royal Thai Survey Department (RTSD) / UN OCHA ROAP.
  Licence: CC BY-IGO.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis — Task H / FR-28)
"""

from __future__ import annotations

import argparse
import io
import re
import sys
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

import pandas as pd
import requests

OPENDENGUE_SPATIAL_ZIP_URL = (
    "https://raw.githubusercontent.com/OpenDengue/master-repo/main/"
    "data/releases/V1.3/Spatial_extract_V1_3.zip"
)
HDX_COD_AB_THA_API_URL = "https://data.humdata.org/api/3/action/package_show?id=cod-ab-tha"

BACKEND_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BACKEND_DIR / "app" / "data"
NAME_MAP_PATH = DATA_DIR / "admin1_name_map_THA.csv"
OUTPUT_CSV_PATH = DATA_DIR / "dengue_monthly_admin1_THA.csv"

# Hand-verified mapping notes for names that are not identical case-insensitive
# matches or have special coverage characteristics in OpenDengue V1.3.
# Never guesses silently: any name not matched by normalised string and not
# present in the mapping CSV with a valid P-code is flagged as UNMATCHED.
HAND_VERIFIED_OVERRIDES: dict[str, tuple[str, str, str]] = {
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
}

SPECIAL_COVERAGE_NOTES: dict[str, str] = {
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
}


def normalize_key(name: str) -> str:
    """Case-insensitive normalisation ignoring spaces and hyphens."""
    return re.sub(r"[\s\-]+", "", str(name).strip().lower())


def read_hdx_admin1_xlsx(xlsx_source: Path | bytes, sheet_name: str = "tha_admin1") -> pd.DataFrame:
    """Reads the `tha_admin1` worksheet from HDX's `tha_admin_boundaries.xlsx`.

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
        return df[["adm1_pcode", "adm1_name"]].dropna().drop_duplicates().sort_values("adm1_pcode").reset_index(drop=True)


def fetch_hdx_xlsx_bytes() -> bytes:
    """Fetches HDX COD-AB Thailand package metadata and downloads `tha_admin_boundaries.xlsx`."""
    resp = requests.get(HDX_COD_AB_THA_API_URL, timeout=60)
    resp.raise_for_status()
    payload = resp.json()
    resources = payload.get("result", {}).get("resources", [])
    xlsx_url = None
    for res in resources:
        name = str(res.get("name", ""))
        url = str(res.get("url") or res.get("download_url") or "")
        if "xlsx" in name.lower() or url.lower().endswith(".xlsx"):
            xlsx_url = url
            break
    if not xlsx_url:
        raise RuntimeError("No XLSX resource found in HDX package cod-ab-tha")
    r_xlsx = requests.get(xlsx_url, timeout=120)
    r_xlsx.raise_for_status()
    return r_xlsx.content


def load_opendengue_thailand_admin1(zip_source: Path | bytes) -> pd.DataFrame:
    """Extracts Thailand Admin1 monthly rows from OpenDengue V1.3 Spatial extract ZIP."""
    zf_arg = io.BytesIO(zip_source) if isinstance(zip_source, bytes) else zip_source
    with zipfile.ZipFile(zf_arg, "r") as z:
        csv_names = [n for n in z.namelist() if n.lower().endswith(".csv")]
        if not csv_names:
            raise ValueError("No CSV found inside OpenDengue Spatial extract ZIP")
        with z.open(csv_names[0]) as f:
            chunks = []
            for chunk in pd.read_csv(f, chunksize=100_000, low_memory=False):
                mask = (
                    (chunk["adm_0_name"].astype(str).str.strip().str.upper() == "THAILAND")
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
) -> tuple[pd.DataFrame, list[str], list[str], list[str]]:
    """Maps distinct OpenDengue `adm_1_name` values to HDX `(adm1_name, adm1_pcode)`.

    Order of resolution:
    1. Existing hand-checkable mapping CSV (`map_path`) if already present and populated.
    2. Automatic normalized matching (case-insensitive, ignoring spaces and hyphens)
       against the 77 HDX `adm1_name` strings.
    3. Explicit hand-verified overrides (`HAND_VERIFIED_OVERRIDES`) for known
       romanisation/spelling variants.
    4. Anything still unmatched is written to `map_path` with empty HDX fields
       and `note="UNMATCHED: requires human review"` (never guessed silently).

    Returns `(map_df, auto_matched, hand_mapped, unmatched)`.
    """
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
        if norm_od in hdx_by_norm:
            h_name, h_pcode = hdx_by_norm[norm_od]
            if od_name in SPECIAL_COVERAGE_NOTES:
                note = SPECIAL_COVERAGE_NOTES[od_name]
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
        elif od_name in HAND_VERIFIED_OVERRIDES:
            h_name, h_pcode, note = HAND_VERIFIED_OVERRIDES[od_name]
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
            rows.append(
                {
                    "opendengue_name": od_name,
                    "hdx_admin1_name": "",
                    "admin1_pcode": "",
                    "note": "UNMATCHED: requires human review",
                }
            )

    map_df = pd.DataFrame(rows, columns=["opendengue_name", "hdx_admin1_name", "admin1_pcode", "note"])
    map_path.parent.mkdir(parents=True, exist_ok=True)
    map_df.to_csv(map_path, index=False)
    return map_df, auto_matched, hand_mapped, unmatched


def build_dataset(
    spatial_zip_path: Path | None = None,
    hdx_xlsx_path: Path | None = None,
    map_path: Path = NAME_MAP_PATH,
    output_csv_path: Path = OUTPUT_CSV_PATH,
) -> dict:
    """Runs the end-to-end Thailand Admin1 monthly dengue build and prints a summary."""
    if hdx_xlsx_path is not None and hdx_xlsx_path.exists():
        print(f"Loading HDX Admin1 boundaries from local file: {hdx_xlsx_path}")
        hdx_df = read_hdx_admin1_xlsx(hdx_xlsx_path)
    else:
        print(f"Fetching HDX Admin1 boundaries from: {HDX_COD_AB_THA_API_URL}")
        hdx_df = read_hdx_admin1_xlsx(fetch_hdx_xlsx_bytes())

    if spatial_zip_path is not None and spatial_zip_path.exists():
        print(f"Loading OpenDengue V1.3 Spatial extract from local file: {spatial_zip_path}")
        od_df = load_opendengue_thailand_admin1(spatial_zip_path)
    else:
        print(f"Downloading OpenDengue V1.3 Spatial extract from: {OPENDENGUE_SPATIAL_ZIP_URL}")
        resp = requests.get(OPENDENGUE_SPATIAL_ZIP_URL, timeout=300)
        resp.raise_for_status()
        od_df = load_opendengue_thailand_admin1(resp.content)

    if od_df.empty:
        raise RuntimeError("No Thailand Admin1 Monthly rows found in OpenDengue extract")

    map_df, auto_matched, hand_mapped, unmatched = build_or_update_name_map(od_df, hdx_df, map_path)

    print("\n" + "=" * 72)
    print("THAILAND ADMIN1 MONTHLY DENGUE BUILD SUMMARY")
    print("=" * 72)
    print(f"HDX COD-AB Thailand Admin1 provinces: {len(hdx_df)}")
    print(f"OpenDengue raw Thailand Admin1 monthly rows: {len(od_df)}")
    print(f"Distinct OpenDengue adm_1_name values: {len(map_df)}")
    print(f"  - Automatically matched (case/space/hyphen-insensitive): {len(auto_matched)}")
    print(f"  - Resolved via hand-checked mapping table: {len(hand_mapped)} -> {hand_mapped}")
    print(f"  - Unmatched names requiring review: {len(unmatched)} -> {unmatched}")

    if unmatched:
        raise RuntimeError(
            f"Unmatched OpenDengue adm_1_name values found: {unmatched}. "
            f"Please review and complete {map_path} before building."
        )

    name_to_pcode = dict(zip(map_df["opendengue_name"], map_df["admin1_pcode"]))
    name_to_hdx_name = dict(zip(map_df["opendengue_name"], map_df["hdx_admin1_name"]))

    out = pd.DataFrame()
    out["iso3"] = "THA"
    od_clean_name = od_df["adm_1_name"].astype(str).str.strip()
    out["admin1_pcode"] = od_clean_name.map(name_to_pcode)
    out["admin1_name"] = od_clean_name.map(name_to_hdx_name)
    out["month"] = pd.to_datetime(od_df["calendar_start_date"], errors="raise").dt.strftime("%Y-%m")
    out["dengue_total"] = pd.to_numeric(od_df["dengue_total"], errors="raise").astype(int)
    out["case_definition"] = od_df["case_definition_standardised"].astype(str).str.strip()
    out["iso3"] = "THA"

    # Duplicate check on (admin1_pcode, month) — never sum duplicates silently
    dup_mask = out.duplicated(subset=["admin1_pcode", "month"], keep=False)
    dup_count = int(dup_mask.sum())
    print(f"Duplicate (admin1_pcode, month) rows detected: {dup_count}")
    if dup_count > 0:
        dup_preview = out.loc[dup_mask, ["admin1_pcode", "admin1_name", "month", "dengue_total"]].head(10)
        print("Duplicate rows sample:\n", dup_preview.to_string(index=False))
        raise RuntimeError(
            f"Found {dup_count} duplicate (admin1_pcode, month) rows; refusing to sum silently."
        )

    out = out.sort_values(["admin1_pcode", "month"]).reset_index(drop=True)
    output_csv_path.parent.mkdir(parents=True, exist_ok=True)
    out.to_csv(output_csv_path, index=False)

    out["_year"] = out["month"].str.slice(0, 4).astype(int)
    prov_per_year = out.groupby("_year")["admin1_pcode"].nunique()

    print(f"\nOutput file: {output_csv_path}")
    print(f"Total rows written: {len(out)}")
    print(f"Distinct mapped HDX Admin1 P-codes: {out['admin1_pcode'].nunique()}")
    print(f"Period covered: {out['month'].min()} to {out['month'].max()}")

    print("\nProvinces per year:")
    for yr, cnt in prov_per_year.items():
        print(f"  {yr}: {cnt} provinces")

    print("\ncase_definition counts per year:")
    cd_table = out.groupby(["_year", "case_definition"]).size().unstack(fill_value=0)
    print(cd_table.to_string())
    print("=" * 72)

    return {
        "total_rows": len(out),
        "distinct_pcodes": int(out["admin1_pcode"].nunique()),
        "distinct_od_names": len(map_df),
        "auto_matched": auto_matched,
        "hand_mapped": hand_mapped,
        "unmatched": unmatched,
        "duplicates": dup_count,
    }


def main(argv: list[str] | None = None) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(
        description="Build bundled Thailand Admin1 monthly dengue case dataset (FR-28)."
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
        help="Optional local path to tha_admin_boundaries.xlsx (downloads from HDX if omitted).",
    )
    args = parser.parse_args(argv)
    build_dataset(spatial_zip_path=args.spatial_zip, hdx_xlsx_path=args.hdx_xlsx)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
