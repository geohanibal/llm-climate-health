# Gemini დავალება — რაუნდი 5: H (ტაილანდის პროვინციების შემთხვევები, FR-28 ნაწილი 1)

როგორ გამოიყენო:
- დაწყებამდე **დააკომიტე** მიმდინარე მდგომარეობა.
- Gemini CLI გახსენი პროექტის საქაღალდეში და ქვემოთ მოცემული ტექსტი ჩასვი.
- დასრულების შემდეგ Claude-ს უთხარი „შეამოწმე დავალება H“.

ეს დავალება **მხოლოდ შემთხვევების მონაცემებს** ეხება (პროვინცია × თვე). კლიმატი, მოსახლეობა და UI შემდეგ
ეტაპებზე იქნება.

---

```
You are working in the repository of a bachelor thesis: an LLM-driven ETL
platform that joins disease case data, climate data and population data
(Python FastAPI backend in backend/, Flutter web frontend in frontend/).

GOAL (task H, first part of new requirement FR-28 "regional data"):
Provide MONTHLY DENGUE CASE COUNTS PER PROVINCE (Admin1) FOR THAILAND as a
bundled, reproducible dataset plus a small loader function. NO climate, NO
population, NO frontend, NO API endpoint in this task.

READ FIRST:
- GEMINI.md, README.md, backend/README.md
- docs/thesis/CHANGE_DOCUMENTATION_GUIDE.md   <- you MUST follow it
- backend/app/config.py (DATA_DIR, DiseaseMeta, licence fields)
- backend/app/services/case_data.py and backend/tests/test_case_data.py
- docs/thesis/supervisor_meetings/2026-11-19_regionuli_monacemebi_gegma.md
  (verified facts about the sources; Georgian)

VERIFIED SOURCES (do not change, do not invent others):
- Cases: OpenDengue V1.3 Spatial extract (licence CC BY 4.0):
  https://raw.githubusercontent.com/OpenDengue/master-repo/main/data/releases/V1.3/Spatial_extract_V1_3.zip
  CSV columns: adm_0_name, adm_1_name, adm_2_name, full_name, ISO_A0,
  FAO_GAUL_code, RNE_iso_code, IBGE_code, calendar_start_date,
  calendar_end_date, Year, dengue_total, case_definition_standardised,
  S_res, T_res, UUID.
  Thailand: filter adm_0_name == "THAILAND", S_res == "Admin1",
  T_res == "Month". 1993-2022. Province count: 72 (1993-2002), 76
  (2003-2010), 77 (2011-2022). "BUNGKAN" (Bueng Kan) exists only from
  2011; it was split from Nong Khai.
- Boundaries / official province codes: HDX COD-AB Thailand, licence
  CC BY-IGO, 77 provinces at Admin1. Metadata API:
  https://data.humdata.org/api/3/action/package_show?id=cod-ab-tha
  (resources include tha_admin_boundaries.xlsx with Admin1 names and
  P-codes such as TH10). Use the XLSX only to obtain the 77 Admin1 English
  names and P-codes.

RULES
1. Do NOT commit, do NOT push, do NOT edit docs/thesis/THESIS_KNOWLEDGE_BASE.md.
2. Never invent data, names, codes, licences or sources. If a province name
   in OpenDengue cannot be matched to an HDX Admin1 name automatically,
   list it in the report; do not guess silently.
3. Do not download large files at runtime of the web app. The dataset must
   be built OFFLINE by a script and bundled as a CSV.
4. Run the full backend test suite at the end (pytest) and report the
   numbers. If pytest hangs, stop it and tell the user.

WHAT TO BUILD
A) backend/scripts/build_dengue_admin1.py  (reproducible build script)
   - Downloads the pinned OpenDengue V1.3 Spatial extract (URL above),
     filters Thailand Admin1 monthly rows.
   - Normalises month as YYYY-MM from calendar_start_date.
   - Maps adm_1_name to the HDX Admin1 English name and P-code using a
     hand-checkable mapping file (B). Matching: case-insensitive, ignore
     spaces/hyphens; anything still unmatched goes to the mapping file as
     an explicit entry that a human can review.
   - Detects duplicates (same province + month) and reports them; never
     sums duplicates silently.
   - Writes backend/app/data/dengue_monthly_admin1_THA.csv with columns:
     iso3, admin1_pcode, admin1_name, month, dengue_total,
     case_definition
   - Prints a summary: rows, provinces per year, unmatched names,
     duplicates, case_definition counts per year.

B) backend/app/data/admin1_name_map_THA.csv
   columns: opendengue_name, hdx_admin1_name, admin1_pcode, note
   One row per distinct OpenDengue adm_1_name for Thailand (expect 77-78;
   explain any extra name in the note column).

C) Loader in backend/app/services/case_data.py:
   load_dengue_admin1(iso3: str, start: date, end: date,
                      merge_changed_units: bool = True) -> pd.DataFrame
   - Returns columns: admin1_pcode, admin1_name, month (period start
     date), cases.
   - merge_changed_units=True: Bueng Kan rows are added to Nong Khai for
     ALL months, so the province set is constant over time (this follows
     Suttirat et al. 2026, p. 5, who merged Bueng Kan into Nong Khai).
     The merge must be explicit in the code (a small table
     CHANGED_UNITS = {"THA": {<BuengKan pcode>: <NongKhai pcode>}}) with a
     comment citing the source.
   - merge_changed_units=False: return the data as published.
   - Months inside the requested period that have no row stay ABSENT
     (gaps are not filled, rule A20).
   - Unknown iso3 -> clear ValueError ("no regional dengue data for ...").

D) Tests in backend/tests/test_case_data.py (or a new
   test_case_data_admin1.py):
   - loader returns only rows inside [start, end];
   - with merge: Bueng Kan pcode never appears, and Nong Khai total for a
     2015 month equals Nong Khai + Bueng Kan from the raw CSV;
   - without merge: Bueng Kan appears only from 2011;
   - province count per year matches 72 / 76 / 77 (or the merged count);
   - unknown iso3 raises ValueError;
   - use a small fixture CSV for unit tests where possible, plus one test
     on the bundled file.

E) Documentation per CHANGE_DOCUMENTATION_GUIDE.md, plus licence fields in
   config.py for the new dataset (OpenDengue V1.3 CC BY 4.0; HDX COD-AB
   Thailand CC BY-IGO, source Royal Thai Survey Department / OCHA).

F) Report: docs_ka/motivacia/H_report.md with
   - file list and what changed,
   - the build script summary output (paste it),
   - unmatched / extra names and how you resolved them,
   - case_definition per year table,
   - test results,
   - open questions for Claude/Sergi.
```
