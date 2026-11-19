# Gemini დავალება — რაუნდი 6: I (რეგიონული შემთხვევები სხვა ქვეყნებისთვის, FR-28)

როგორ გამოიყენო:
- სამუშაო მდგომარეობა უკვე დაკომიტებულია (დავალება H შემოწმებულია, commit `29e6e35`).
- Gemini CLI-ში ჩასვი ქვემოთ მოცემული ტექსტი.
- დასრულების შემდეგ Claude-ს უთხარი „შეამოწმე დავალება I“.

---

```
You are working in the repository of a bachelor thesis (LLM-driven ETL platform
for climate and health data; Python FastAPI backend in backend/).

CONTEXT: Task H (already reviewed and committed) added Thailand province-level
(Admin1) monthly dengue cases:
- backend/scripts/build_dengue_admin1.py
- backend/app/data/dengue_monthly_admin1_THA.csv, admin1_name_map_THA.csv
- load_dengue_admin1() and CHANGED_UNITS in backend/app/services/case_data.py
- REGIONAL_CASE_DATA_SOURCES in backend/app/config.py
Read these files, docs_ka/motivacia/H_report.md and
docs/thesis/supervisor_meetings/2026-11-19_regionuli_monacemebi_gegma.md
(section 2b: verified OpenDengue vs HDX province counts per country).

GOAL (task I): make the build reproducible for SEVERAL countries and add three
countries whose OpenDengue Admin1 data are MONTHLY and whose Admin1 count
matches HDX COD-AB:
  - LAO (Lao PDR): OpenDengue 18 regions, 1998-2010, monthly; HDX cod-ab-lao 18
  - LKA (Sri Lanka): OpenDengue 9 regions, 1996-2004, monthly; HDX cod-ab-lka 9
  - SLV (El Salvador): OpenDengue 14 regions, 2000-2009, monthly; HDX cod-ab-slv 14
Do NOT add countries with weekly data (MEX, BOL, ...) in this task.

RULES
1. Do NOT commit, push, or edit docs/thesis/THESIS_KNOWLEDGE_BASE.md.
2. Never invent names, P-codes, licences or data. Get P-codes and English names
   from each country's HDX COD-AB XLSX (find its URL via
   https://data.humdata.org/api/3/action/package_show?id=cod-ab-<iso3 lowercase>
   -> resource whose name ends with .xlsx). Record each country's HDX licence
   and source exactly as the API returns them ("license_title",
   "dataset_source").
3. A name that cannot be matched automatically must be resolved only with
   evidence (e.g. OpenDengue's own RNE_iso_code / FAO_GAUL_code columns) and
   documented in the name map "note" column; otherwise list it as unresolved
   in the report and leave it out of the CSV.
4. The Thailand output (dengue_monthly_admin1_THA.csv, admin1_name_map_THA.csv)
   must stay byte-for-byte identical. Verify this and say so in the report.
5. Never sum duplicates silently; report them.
6. Run the full backend test suite with the project venv
   (backend/.venv/Scripts/python.exe -m pytest -q) and report the numbers.

WHAT TO BUILD
A) Refactor backend/scripts/build_dengue_admin1.py so that it takes a list of
   ISO3 codes (CLI argument, default: all configured) and uses ONE generic code
   path. Country specifics (OpenDengue adm_0_name, HDX dataset id, Admin1 sheet
   name) live in a small table in the script or in config.py.
B) For LAO, LKA, SLV produce
   backend/app/data/dengue_monthly_admin1_<ISO3>.csv (same columns as THA) and
   backend/app/data/admin1_name_map_<ISO3>.csv.
C) Check for each country whether Admin1 units changed over time (a unit that
   appears/disappears in some years, or the province count per year changes).
   If yes: describe it in the report with evidence; do NOT add CHANGED_UNITS
   entries unless a published source states the change (then cite it). Gaps
   stay gaps.
D) Extend REGIONAL_CASE_DATA_SOURCES in config.py for the new countries
   (sources, citations, licences as returned by HDX).
E) load_dengue_admin1() must work for the new ISO3 codes without changes to its
   logic (only data/config). Add tests: one per new country on the bundled file
   (row count, province count, period), plus a test that the THA output is
   unchanged (e.g. row count 27,024 and total 1,410,795).
F) Report docs_ka/motivacia/I_report.md (Georgian is fine): per country rows,
   regions per year, period, case_definition per year, unmatched/extra names
   and how resolved, unit changes found, licences, test results, and a short
   note on what would be needed for WEEKLY countries (MEX, BOL): how many
   epi-weeks span two months, and the options (assign by start date / split by
   days) without implementing them.
```
