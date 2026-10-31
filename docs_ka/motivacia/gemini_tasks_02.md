# Gemini დავალებები — რაუნდი 2

როგორ გამოიყენო: Gemini CLI გახსენი პროექტის საქაღალდეში და **ერთ ჯერზე ერთი
დავალება** მიეცი: ჯერ A, შემდეგ B, შემდეგ C, შემდეგ D. თითოეულის შემდეგ Claude-ს უთხარი
„შეამოწმე დავალება A“ (B, C ან D). Claude შედეგს ფაილებიდან წაიკითხავს.

ზოგადი წესები, რომლებიც ყოველ დავალებაშია ჩაწერილი:
- Gemini არაფერს აკომიტებს (`git commit`-ს არ აკეთებს).
- შედეგები კონკრეტულ ფაილებში უნდა ჩაიწეროს, რომ შემოწმება შესაძლებელი იყოს.
- აკრძალულია მოგონილი წყაროები და ციტატები.
- კოდის დავალებებში (B, C, D) Gemini-ს დოკუმენტებიც უნდა განაახლოს:
  `docs/thesis/CHANGE_DOCUMENTATION_GUIDE.md` (ნაწილი 3, შესაბამისი დავალება).
  Gemini-ს prompt-ის ბოლოს დაუმატე: *"Also follow docs/thesis/CHANGE_DOCUMENTATION_GUIDE.md
  (section for this task) and list every changed document in your report."*

---

## დავალება A — ლიტერატურა (კოდი არ იცვლება)

```
You are helping with a computer-science bachelor thesis. Read
docs_ka/motivacia/gemini_prompts.md and README.md for context.

STRICT RULES
- Only cite publications you have actually opened. For every claim about a
  paper give the section name (e.g. "Methods > Data sources") and a VERBATIM
  quote in English. If you cannot open the full text, write "FULL TEXT NOT
  ACCESSED" and do not describe its methods.
- Never paraphrase something as if the authors said it. No invented numbers.
- Do not modify any file except the two output files below. Do not commit.

TASK A1 — Requirements from the main paper
Paper: Suttirat P. et al. (2026) "Machine learning reveals temperature as a key
predictor of dengue risk across Thailand's provinces: A 20-year analysis",
PLOS Negl Trop Dis 20(7): e0014590, DOI 10.1371/journal.pntd.0014590.
Extract every DATA PREPARATION step the authors performed (data sources,
variables, spatial aggregation, temporal aggregation/interpolation, lags,
incidence calculation, administrative boundary harmonisation, missing data,
train/test split by time). For each step write:
  | Step | Verbatim quote | Section | Needed system capability |
Write the result to docs_ka/motivacia/A1_suttirat_steps.md

TASK A2 — Find a second case-study paper
Find 2-3 real peer-reviewed papers (2015-2026) that model MALARIA or CHOLERA
with climate data at MONTHLY or WEEKLY resolution (not annual), ideally with
openly available data (Zenodo, Figshare, Dryad, GitHub, supplementary CSV).
For each give: full citation, DOI, link, disease, country, resolution,
health data source, climate data source + variables, lags used, model,
whether data is openly downloadable (give the exact link), and 2-3 verbatim
quotes from Methods. Then recommend ONE paper for the case study and explain
why. Write the result to docs_ka/motivacia/A2_case_study_2.md
```

---

## დავალება B — კოდი: lag სვეტები გამოსატან ცხრილში (FR-new-4)

```
You are working in the repository of a bachelor thesis (Python FastAPI backend
in backend/, Flutter frontend in frontend/). Read README.md, backend/README.md,
backend/app/services/etl.py, backend/app/services/statistics.py and
backend/app/models.py before changing anything.

MOTIVATION
Suttirat et al. (2026, PLOS NTD) used climate variables lagged by 1, 2 and 3
months as model inputs. Currently the system only reports lagged correlations
in the text (statistics.compute_lagged_correlations), but the integrated output
table has no lagged climate columns, so a researcher cannot use them directly.

TASK
Add optional lagged climate feature columns to the integrated dataset.
1. New request option (in the request model in backend/app/models.py):
   `lag_periods: list[int]` — default empty list (= current behaviour,
   nothing changes). Allowed values 1..6. Validate with pydantic.
2. In the ETL pipeline, after the climate and case data are joined and sorted
   by period, for each climate variable present and each lag k add a column
   `<variable>_lag<k>` (e.g. `temperature_lag1`) = value of that variable k
   periods EARLIER. Use the period of the target resolution (month/week/day/
   year), shift within the sorted series, leave NaN where no earlier value
   exists. Do NOT drop these rows.
3. Put the lag computation in its own small, documented function (e.g. in a
   suitable services module) so it can be unit-tested in isolation.
4. Add a short step to the pipeline step list / provenance so the user sees
   "Added lagged climate features: lags 1, 2, 3".
5. Tests: add pytest tests in backend/tests/ covering: default (no lag columns),
   lags [1,3] produce the right column names and values on a small handmade
   DataFrame, first k rows are NaN, invalid lag (0 or 7) is rejected.
6. Run `cd backend && python -m pytest -q` and paste the final summary line
   into the report.

RULES
- Match the existing code style: module docstrings with
  "Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)", type
  hints, comments explaining WHY, same naming conventions.
- Change only what is needed. Do not reformat unrelated code. Do not touch
  the frontend in this task. Do not commit.
- At the end write docs_ka/motivacia/B_report.md with: list of changed files,
  short explanation of each change, test output summary, and any open issues.
```

---

## დავალება C — კოდი: Tmin / Tmax ცვლადები (FR-new-3)

მხოლოდ მას შემდეგ მიეცი, რაც B შემოწმდება.

```
Same repository and same RULES as before (read them again in
docs_ka/motivacia/gemini_tasks_02.md, task B). Read
backend/app/services/climate.py, backend/app/models.py, backend/app/services/
llm.py and the relevant frontend form code before changing anything.

MOTIVATION
Suttirat et al. (2026) found lagged MINIMUM temperature (~21 °C, lag 1) and
MAXIMUM temperature (~32 °C, lag 3) to be key predictors. The system only
offers mean temperature and precipitation.

TASK
1. Add two climate variables: "temperature_min" and "temperature_max".
   - Open-Meteo ERA5 daily fields: temperature_2m_min, temperature_2m_max
   - NASA POWER daily parameters: T2M_MIN, T2M_MAX
   Verify these field names against the official API docs and write the doc
   URLs in your report.
2. Aggregation to coarser resolution: monthly/yearly value = MEAN of the daily
   min (resp. max) values. Document this choice in a comment.
3. Extend every place that lists allowed variables (pydantic Literal types,
   custom-upload column aliases, LLM request-parsing prompt/schema, frontend
   form checkboxes and labels in German and English). Search the whole
   codebase for "precipitation" to find them all.
4. Lag columns from task B must also work for the new variables.
5. Tests for: field mapping, aggregation, request validation, parse-request.
   Run the full backend test suite and, if possible, `flutter analyze` in
   frontend/. Paste summaries.
6. Write docs_ka/motivacia/C_report.md (same structure as B_report.md).
```

---

## დავალება D — კოდი: მოსახლეობის წრფივი ინტერპოლაცია (RECOMMENDATIONS A17)

```
Same repository and same RULES as before (read them again in
docs_ka/motivacia/gemini_tasks_02.md, task B: no commits, no invented sources,
default behaviour of other features must not change). Read
backend/app/services/population.py, backend/app/services/etl.py and the
existing population tests before changing anything.

MOTIVATION
Suttirat et al. (2026) linearly interpolated annual covariates to monthly
values. In this system, for resolution "month" (and "day"),
population.py currently REPEATS the annual population value for every month of
the year and fills missing years with the NEAREST available year. This creates
an artificial step every January (e.g. Thailand 2009-12: 68,121,080 ->
2010-01: 68,579,447), which also produces a step in incidence_rate_per_100k.

TASK
1. In population.py, for resolution "month" and "day": anchor each annual value
   at the middle of its year (1 July), then linearly interpolate in time
   (pandas interpolate(method="time")) to every month (first day of month) /
   every day in the requested range. Outside the range of available years,
   keep the nearest value (constant extrapolation, as today) — do NOT
   extrapolate a trend. Round population to integers.
2. Resolutions "year" and "decade" must stay exactly as they are.
3. Add a processing-step text so the user sees it in the pipeline steps / PDF,
   e.g. "Annual population linearly interpolated to monthly values (anchored at
   mid-year); years outside the available range held constant."
4. Tests (pytest):
   - two consecutive years -> monthly values strictly increase/decrease
     monotonically, no jump at January;
   - July value equals the annual value;
   - range before the first available year -> constant = first year's value;
   - a missing year in the middle is interpolated (not nearest-year copied);
   - year/decade output unchanged.
   Run the full backend test suite and paste the summary.
5. Write docs_ka/motivacia/D_report.md: changed files, before/after example for
   Thailand 2009-11 ... 2010-02, test summary, open questions.
```
