"""Offline reproducible builder and empirical verifier for `dengue_monthly_by_iso3.csv` (Task J3 / A13).

Reconstructs the national monthly dengue case-count dataset from the pinned
OpenDengue V1.3 National extract (`National_extract_V1_3.zip`, CC BY 4.0) and
(optionally) inspects the Temporal extract (`Temporal_extract_V1_3.zip`).

Never overwrites the bundled file (`backend/app/data/dengue_monthly_by_iso3.csv`)
by default: writes to `--out` and prints a full per-country empirical comparison
against the bundled file (rows equal / different, months only in one file,
totals, and how weekly rows were treated).

Empirical finding (verified across all 2,308 rows / 39 countries):
- The bundled `dengue_monthly_by_iso3.csv` was built exclusively from
  OpenDengue **V1.3 National extract** (`National_extract_V1_3.zip`) by filtering
  to `T_res == "Month"` (`S_res == "Admin0"`), taking `month = calendar_start_date[:7]`
  and `dengue_total = float(dengue_total)` for the 39 included ISO3 countries.
- **No weekly (`T_res == "Week"`) or yearly (`T_res == "Year"`) rows were converted
  or included** in the bundled file: even for countries in the bundled file that
  also have weekly rows in the National extract (`AFG`, `KHM`, `LKA`, `MYS`,
  `NCL`, `NIC`, `PHL`, `SAU`, `SDN`, `SGP`), 100 % of the bundled rows match
  `T_res == "Month"` rows with 0.0 difference, while converting weekly rows via
  `calendar_start_date`, `calendar_end_date`, or proportional day-splitting adds
  extra months and diverges from the bundled totals.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis — Task J3 / A13)
"""

from __future__ import annotations

import argparse
import io
import sys
import zipfile
from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd
import requests

OPENDENGUE_NATIONAL_ZIP_URL = (
    "https://raw.githubusercontent.com/OpenDengue/master-repo/main/"
    "data/releases/V1.3/National_extract_V1_3.zip"
)
OPENDENGUE_TEMPORAL_ZIP_URL = (
    "https://raw.githubusercontent.com/OpenDengue/master-repo/main/"
    "data/releases/V1.3/Temporal_extract_V1_3.zip"
)

BACKEND_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BACKEND_DIR / "app" / "data"
BUNDLED_NATIONAL_CSV_PATH = DATA_DIR / "dengue_monthly_by_iso3.csv"


def load_opendengue_extract_csv(
    zip_source: Path | bytes,
    s_res: str | None = "Admin0",
) -> pd.DataFrame:
    """Loads the CSV inside an OpenDengue V1.3 extract ZIP, optionally filtering by `S_res`."""
    zf_arg = io.BytesIO(zip_source) if isinstance(zip_source, bytes) else zip_source
    with zipfile.ZipFile(zf_arg, "r") as z:
        csv_names = [n for n in z.namelist() if n.lower().endswith(".csv")]
        if not csv_names:
            raise ValueError("No CSV found inside OpenDengue extract ZIP")
        with z.open(csv_names[0]) as f:
            chunks = []
            for chunk in pd.read_csv(f, chunksize=100_000, low_memory=False):
                if s_res is not None:
                    mask = chunk["S_res"].astype(str).str.strip() == s_res
                    sub = chunk.loc[mask]
                else:
                    sub = chunk
                if not sub.empty:
                    chunks.append(sub)
            if not chunks:
                return pd.DataFrame()
            return pd.concat(chunks, ignore_index=True)


def _aggregate_weekly_to_monthly(
    week_df: pd.DataFrame,
    rule: str,
) -> pd.DataFrame:
    """Converts weekly OpenDengue rows (`T_res == 'Week'`) to monthly totals (`iso3, month, dengue_total`)
    under one of three candidate rules:
      - 'start_date': assign the entire week's cases to `calendar_start_date` month (`YYYY-MM`)
      - 'end_date': assign the entire week's cases to `calendar_end_date` month (`YYYY-MM`)
      - 'split_by_days': split each week's cases proportionally across the calendar days
        spanning `[calendar_start_date, calendar_end_date]` in each month.
    """
    if week_df.empty:
        return pd.DataFrame(columns=["iso3", "month", "dengue_total"])

    w = week_df.copy()
    w["iso3"] = w["ISO_A0"].astype(str).str.strip()
    w["dengue_total"] = pd.to_numeric(w["dengue_total"], errors="coerce").fillna(0.0)
    w["start_dt"] = pd.to_datetime(w["calendar_start_date"], errors="coerce")
    w["end_dt"] = pd.to_datetime(w["calendar_end_date"], errors="coerce")
    w = w.dropna(subset=["start_dt", "end_dt"])

    if rule == "start_date":
        w["month"] = w["start_dt"].dt.strftime("%Y-%m")
        return w.groupby(["iso3", "month"], as_index=False)["dengue_total"].sum()

    if rule == "end_date":
        w["month"] = w["end_dt"].dt.strftime("%Y-%m")
        return w.groupby(["iso3", "month"], as_index=False)["dengue_total"].sum()

    if rule == "split_by_days":
        split_rows: list[dict[str, Any]] = []
        for row in w.itertuples(index=False):
            s_dt = row.start_dt
            e_dt = row.end_dt
            cases = float(row.dengue_total)
            if s_dt.year == e_dt.year and s_dt.month == e_dt.month:
                split_rows.append(
                    {"iso3": row.iso3, "month": s_dt.strftime("%Y-%m"), "dengue_total": cases}
                )
            else:
                days = pd.date_range(s_dt, e_dt, freq="D")
                n_days = len(days)
                if n_days <= 0:
                    continue
                months = days.strftime("%Y-%m")
                for m_str, count in pd.Series(months).value_counts().items():
                    split_rows.append(
                        {
                            "iso3": row.iso3,
                            "month": str(m_str),
                            "dengue_total": cases * (float(count) / float(n_days)),
                        }
                    )
        if not split_rows:
            return pd.DataFrame(columns=["iso3", "month", "dengue_total"])
        sdf = pd.DataFrame(split_rows)
        return sdf.groupby(["iso3", "month"], as_index=False)["dengue_total"].sum()

    raise ValueError(f"Unknown weekly assignment rule: {rule!r}")


def build_national_monthly_df(
    nat_df: pd.DataFrame,
    iso3_filter: set[str] | None = None,
    include_weekly_rule: str = "none",
) -> pd.DataFrame:
    """Builds a monthly `(iso3, month, dengue_total)` DataFrame from OpenDengue V1.3 National extract.

    When `include_weekly_rule == "none"` (the rule that reproduces the bundled file),
    only rows with `T_res == "Month"` are included.
    """
    df = nat_df[nat_df["S_res"].astype(str).str.strip() == "Admin0"].copy()
    df["iso3"] = df["ISO_A0"].astype(str).str.strip()
    if iso3_filter is not None:
        df = df[df["iso3"].isin(iso3_filter)].copy()

    m_df = df[df["T_res"].astype(str).str.strip() == "Month"].copy()
    m_df["month"] = pd.to_datetime(m_df["calendar_start_date"], errors="raise").dt.strftime("%Y-%m")
    m_df["dengue_total"] = pd.to_numeric(m_df["dengue_total"], errors="raise").astype(float)

    dup_mask = m_df.duplicated(subset=["iso3", "month"], keep=False)
    if dup_mask.any():
        raise RuntimeError(
            f"Duplicate (iso3, month) rows in OpenDengue T_res=='Month': {int(dup_mask.sum())}"
        )

    base = m_df[["iso3", "month", "dengue_total"]].copy()

    if include_weekly_rule != "none":
        w_df = df[df["T_res"].astype(str).str.strip() == "Week"].copy()
        w_monthly = _aggregate_weekly_to_monthly(w_df, rule=include_weekly_rule)
        # Keep native monthly rows where present; add weekly-derived months where monthly is absent
        existing_keys = set(zip(base["iso3"], base["month"]))
        w_only = w_monthly[
            ~w_monthly.apply(lambda r: (r["iso3"], r["month"]) in existing_keys, axis=1)
        ]
        base = pd.concat([base, w_only], ignore_index=True)

    return base.sort_values(["iso3", "month"]).reset_index(drop=True)


def compare_with_bundled(
    reproduced_df: pd.DataFrame,
    bundled_df: pd.DataFrame,
) -> pd.DataFrame:
    """Compares a candidate `(iso3, month, dengue_total)` DataFrame against the bundled CSV per country."""
    all_isos = sorted(set(bundled_df["iso3"].unique()) | set(reproduced_df["iso3"].unique()))
    rows: list[dict[str, Any]] = []

    for iso3 in all_isos:
        b_sub = bundled_df[bundled_df["iso3"] == iso3][["month", "dengue_total"]].copy()
        r_sub = reproduced_df[reproduced_df["iso3"] == iso3][["month", "dengue_total"]].copy()

        merged = pd.merge(
            b_sub,
            r_sub,
            on="month",
            how="outer",
            suffixes=("_bundled", "_repro"),
            indicator=True,
        )
        both = merged[merged["_merge"] == "both"]
        only_bundled = int((merged["_merge"] == "left_only").sum())
        only_repro = int((merged["_merge"] == "right_only").sum())

        if not both.empty:
            eq_mask = np.isclose(
                both["dengue_total_bundled"].astype(float),
                both["dengue_total_repro"].astype(float),
                rtol=0.0,
                atol=1e-6,
            )
            rows_equal = int(eq_mask.sum())
            rows_diff = int((~eq_mask).sum())
        else:
            rows_equal = 0
            rows_diff = 0

        rows.append(
            {
                "iso3": iso3,
                "bundled_rows": len(b_sub),
                "repro_rows": len(r_sub),
                "rows_equal": rows_equal,
                "rows_different": rows_diff,
                "months_only_in_bundled": only_bundled,
                "months_only_in_repro": only_repro,
                "bundled_total": float(b_sub["dengue_total"].sum()) if not b_sub.empty else 0.0,
                "repro_total": float(r_sub["dengue_total"].sum()) if not r_sub.empty else 0.0,
            }
        )

    return pd.DataFrame(rows)


def evaluate_weekly_rules(
    nat_df: pd.DataFrame,
    bundled_df: pd.DataFrame,
) -> pd.DataFrame:
    """Empirically tests how weekly rows in OpenDengue V1.3 National extract relate to the bundled file."""
    bundled_isos = set(bundled_df["iso3"].unique())
    sub = nat_df[
        (nat_df["S_res"].astype(str).str.strip() == "Admin0")
        & (nat_df["ISO_A0"].astype(str).str.strip().isin(bundled_isos))
    ].copy()

    weekly_isos = sorted(
        sub[sub["T_res"].astype(str).str.strip() == "Week"]["ISO_A0"].astype(str).str.strip().unique()
    )

    records: list[dict[str, Any]] = []
    for rule in ("none", "start_date", "end_date", "split_by_days"):
        cand = build_national_monthly_df(nat_df, iso3_filter=bundled_isos, include_weekly_rule=rule)
        cmp_df = compare_with_bundled(cand, bundled_df)
        cmp_weekly = cmp_df[cmp_df["iso3"].isin(weekly_isos)]
        records.append(
            {
                "rule": rule,
                "total_bundled_rows": int(cmp_df["bundled_rows"].sum()),
                "total_repro_rows": int(cmp_df["repro_rows"].sum()),
                "rows_equal_all_39": int(cmp_df["rows_equal"].sum()),
                "rows_different_all_39": int(cmp_df["rows_different"].sum()),
                "months_only_in_bundled_all_39": int(cmp_df["months_only_in_bundled"].sum()),
                "months_only_in_repro_all_39": int(cmp_df["months_only_in_repro"].sum()),
                "weekly_countries_exact_match": int(
                    (
                        (cmp_weekly["rows_equal"] == cmp_weekly["bundled_rows"])
                        & (cmp_weekly["rows_different"] == 0)
                        & (cmp_weekly["months_only_in_bundled"] == 0)
                        & (cmp_weekly["months_only_in_repro"] == 0)
                    ).sum()
                ),
                "weekly_countries_count": len(weekly_isos),
            }
        )
    return pd.DataFrame(records)


def run_build_and_compare(
    out_path: Path,
    national_zip_path: Path | None = None,
    temporal_zip_path: Path | None = None,
    bundled_path: Path = BUNDLED_NATIONAL_CSV_PATH,
    all_countries: bool = False,
) -> dict[str, Any]:
    """Builds the reproduced national monthly dengue CSV at `out_path` and compares with `bundled_path`."""
    if out_path.resolve() == bundled_path.resolve():
        raise ValueError(
            f"Refusing to overwrite the bundled file {bundled_path}; pass a separate --out path."
        )

    bundled_df = pd.read_csv(bundled_path)
    bundled_isos = set(bundled_df["iso3"].unique())

    if national_zip_path is not None and national_zip_path.exists():
        print(f"Loading OpenDengue V1.3 National extract from local file: {national_zip_path}")
        nat_df = load_opendengue_extract_csv(national_zip_path, s_res="Admin0")
    else:
        print(f"Downloading OpenDengue V1.3 National extract from: {OPENDENGUE_NATIONAL_ZIP_URL}")
        resp = requests.get(OPENDENGUE_NATIONAL_ZIP_URL, timeout=180)
        resp.raise_for_status()
        nat_df = load_opendengue_extract_csv(resp.content, s_res="Admin0")

    iso_filter = None if all_countries else bundled_isos
    repro_df = build_national_monthly_df(nat_df, iso3_filter=iso_filter, include_weekly_rule="none")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    repro_df.to_csv(out_path, index=False)

    cmp_39 = compare_with_bundled(
        build_national_monthly_df(nat_df, iso3_filter=bundled_isos, include_weekly_rule="none"),
        bundled_df,
    )
    cmp_all_65 = compare_with_bundled(
        build_national_monthly_df(nat_df, iso3_filter=None, include_weekly_rule="none"),
        bundled_df,
    )
    weekly_rules_df = evaluate_weekly_rules(nat_df, bundled_df)

    print("\n" + "=" * 78)
    print("OPEN DENGUE V1.3 NATIONAL EXTRACT vs BUNDLED dengue_monthly_by_iso3.csv")
    print("=" * 78)
    print(f"Bundled file: {bundled_path} ({len(bundled_df)} rows, {len(bundled_isos)} countries)")
    print(f"Reproduced output written to: {out_path} ({len(repro_df)} rows)")
    print("\n1. Per-country comparison for the 39 bundled countries (T_res == 'Month'):")
    print(cmp_39.to_string(index=False))

    exact_39 = (
        int(cmp_39["rows_equal"].sum()) == len(bundled_df)
        and int(cmp_39["rows_different"].sum()) == 0
        and int(cmp_39["months_only_in_bundled"].sum()) == 0
        and int(cmp_39["months_only_in_repro"].sum()) == 0
    )
    print(
        f"\n-> 39-country reproduction result: {int(cmp_39['rows_equal'].sum())}/{len(bundled_df)} rows equal, "
        f"{int(cmp_39['rows_different'].sum())} different, "
        f"{int(cmp_39['months_only_in_bundled'].sum())} only in bundled, "
        f"{int(cmp_39['months_only_in_repro'].sum())} only in repro "
        f"(exact match = {exact_39})."
    )

    extra_26 = cmp_all_65[cmp_all_65["bundled_rows"] == 0]
    print(
        f"\n2. Additional countries with T_res == 'Month' in National_extract_V1_3 not in bundled file: "
        f"{len(extra_26)} countries ({int(extra_26['repro_rows'].sum())} rows)"
    )
    print(extra_26[["iso3", "repro_rows", "repro_total"]].to_string(index=False))

    print("\n3. Empirical test of weekly (T_res == 'Week') assignment rules across the 39 bundled countries:")
    print(weekly_rules_df.to_string(index=False))

    temporal_summary: dict[str, Any] | None = None
    if temporal_zip_path is not None and temporal_zip_path.exists():
        print(f"\n4. Checking OpenDengue V1.3 Temporal extract ({temporal_zip_path})...")
        temp_df = load_opendengue_extract_csv(temporal_zip_path, s_res="Admin0")
        temp_m = build_national_monthly_df(temp_df, iso3_filter=bundled_isos, include_weekly_rule="none")
        cmp_temp = compare_with_bundled(temp_m, bundled_df)
        temporal_summary = {
            "rows_equal": int(cmp_temp["rows_equal"].sum()),
            "rows_different": int(cmp_temp["rows_different"].sum()),
            "months_only_in_bundled": int(cmp_temp["months_only_in_bundled"].sum()),
            "months_only_in_repro": int(cmp_temp["months_only_in_repro"].sum()),
        }
        print(
            f"   Temporal extract (Admin0, T_res == 'Month') vs bundled: "
            f"{temporal_summary['rows_equal']} equal, "
            f"{temporal_summary['rows_different']} different, "
            f"{temporal_summary['months_only_in_bundled']} only in bundled, "
            f"{temporal_summary['months_only_in_repro']} only in temporal."
        )

    print("=" * 78)
    return {
        "exact_39": exact_39,
        "comparison_39": cmp_39,
        "comparison_all_65": cmp_all_65,
        "weekly_rules": weekly_rules_df,
        "temporal_summary": temporal_summary,
    }


def main(argv: list[str] | None = None) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(
        description=(
            "Reproduce and compare dengue_monthly_by_iso3.csv from OpenDengue V1.3 "
            "without overwriting the bundled file (Task J3 / A13)."
        )
    )
    parser.add_argument(
        "--out",
        type=Path,
        required=True,
        help="Output CSV path for the reproduced national monthly file (must not be the bundled file).",
    )
    parser.add_argument(
        "--national-zip",
        type=Path,
        default=None,
        help="Optional local path to National_extract_V1_3.zip (downloads from GitHub if omitted).",
    )
    parser.add_argument(
        "--temporal-zip",
        type=Path,
        default=None,
        help="Optional local path to Temporal_extract_V1_3.zip for cross-extract comparison.",
    )
    parser.add_argument(
        "--all-countries",
        action="store_true",
        help="Write all 65 countries with T_res=='Month' in V1.3 National extract to --out (default: the 39 bundled countries).",
    )
    args = parser.parse_args(argv)
    run_build_and_compare(
        out_path=args.out,
        national_zip_path=args.national_zip,
        temporal_zip_path=args.temporal_zip,
        all_countries=args.all_countries,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
