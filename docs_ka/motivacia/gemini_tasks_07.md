# Gemini დავალება — რაუნდი 7: J (lag-იანი შემთხვევები, მოძრავი საშუალო, ეროვნული ფაილის აღდგენა)

როგორ გამოიყენო:
- სამუშაო მდგომარეობა დაკომიტებულია (დავალება I შემოწმებულია, `b01a668`).
- Gemini CLI-ში ჩასვი ქვემოთ მოცემული ტექსტი.
- დასრულების შემდეგ Claude-ს უთხარი „შეამოწმე დავალება J“.

სამი პატარა, ერთმანეთისგან დამოუკიდებელი ნაწილია (J1, J2, J3). თითოეული ცალკე დაასრულოს და ცალკე ატესტოს.

---

```
You are working in the repository of a bachelor thesis (LLM-driven ETL platform
for climate and health data; Python FastAPI backend in backend/, Flutter web
frontend in frontend/).

READ FIRST:
- GEMINI.md, backend/README.md, docs/thesis/CHANGE_DOCUMENTATION_GUIDE.md
  (you MUST follow it)
- backend/app/services/lags.py, backend/app/services/etl.py (run_integration,
  where lag_periods are applied), backend/app/models.py (IntegrationRequest,
  PeriodRecord), backend/tests/test_lags.py
- backend/app/services/case_data.py, backend/app/config.py
- backend/scripts/build_dengue_admin1.py (task H/I, reviewed) and
  docs_ka/motivacia/I_report.md

RULES
1. Do NOT commit, push, or edit docs/thesis/THESIS_KNOWLEDGE_BASE.md.
2. Never invent data, sources, page numbers or licences.
3. Existing behaviour must not change when the new options are not used
   (default off). All existing tests must still pass.
4. Run the full backend suite with backend/.venv/Scripts/python.exe -m pytest -q
   and report the numbers. If pytest hangs, stop and tell the user.
5. Gaps are never filled (rule A20): a lag or moving average that would need a
   missing period must be empty (NaN/null), not computed from fewer values.

J1 — LAGGED CASE COUNTS (requirement candidate A1b)
Evidence (already verified, cite exactly): Suttirat et al. 2026, pp. 9-10
(previous month's risk status added as a predictor to remove residual
autocorrelation); Colon-Gonzalez et al. 2021, PLOS Medicine 18(3):e1003542,
p. 9 ("log of the observed number of dengue cases in the previous month").
- Add an optional request field `case_lag_periods: list[int]` (allowed 1..6,
  same validation style as `lag_periods`, default empty).
- For each k, add a column `cases_lag<k>` = case count k periods earlier
  (same resolution logic and same "reindex to complete period grid" safety
  as the climate lags in lags.py).
- Case data must also be fetched for max(k) periods BEFORE start_date (buffer),
  like the climate lag buffer, so the first rows are not empty when data
  exist; rows outside [start_date, end_date] are not returned.
- If incidence is computed, do NOT add incidence lags in this task (only
  cases).
- Tests: shift correctness, buffer used, missing period -> NaN, default off.

J2 — MOVING-AVERAGE CLIMATE LAG (new candidate)
Evidence: Colon-Gonzalez et al. 2021, p. 9 ("a 3-month moving average of
temperature, precipitation, specific humidity, and DTR centred at lag of
1 month (i.e., each value is given the average of lag 0 to a lag of 2
months)").
- Add an optional request field `climate_moving_average: list[int]` giving
  window lengths in periods (allowed 2..6, default empty).
- For each window w and each climate variable, add `<var>_ma<w>` = mean of
  lag 0 .. lag (w-1) (i.e. the current and the w-1 previous periods).
- If ANY value in the window is missing, the result is NaN (do not average
  fewer values).
- Precipitation note: the mean of monthly sums is correct here (it is what
  the paper does); document it in a code comment.
- Reuse the climate lag buffer so the first rows are not empty.
- Tests: values for a small hand-made series, NaN propagation, default off.

J3 — REPRODUCIBLE NATIONAL DENGUE FILE (recommendation A13)
Problem: backend/app/data/dengue_monthly_by_iso3.csv (columns iso3, month,
dengue_total) has no build script, so we do not know which OpenDengue
version / extract produced it.
- Write backend/scripts/build_dengue_national.py that tries to REPRODUCE the
  existing file from OpenDengue V1.3 (National extract and, if needed,
  Temporal extract; pinned URLs under
  https://raw.githubusercontent.com/OpenDengue/master-repo/main/data/releases/V1.3/).
  The script must NOT overwrite the bundled file by default; it writes to a
  path given by --out and then COMPARES with the bundled file.
- Report per country: rows equal / different, months only in one file,
  totals; and for weekly sources how epi-weeks were assigned to months
  (start date / end date / split) — determine this EMPIRICALLY by checking
  which rule reproduces the bundled numbers. If no rule reproduces them,
  say so; do not guess.
- Do NOT replace the bundled file in this task. The decision is Sergi's.

DOCUMENTATION: follow CHANGE_DOCUMENTATION_GUIDE.md (requirements catalogue
DE/EN/KA as candidates, dokumentacia.tex, backend/README.md,
TESTING_GUIDE.md, RECOMMENDATIONS.md). Frontend: do NOT change the UI in this
task; only make sure the new response columns do not break existing
frontend tests (the table shows dynamic columns).

REPORT: docs_ka/motivacia/J_report.md with J1/J2/J3 sections: files changed,
example output rows (Thailand 2019, national, monthly), test results, J3
comparison table and the reproduced (or not reproduced) assignment rule,
open questions.
```
