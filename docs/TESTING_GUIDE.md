# Testing Guide — LLM-Climate-Health

This document is for anyone evaluating the platform (e.g. for the thesis
defense) who wants to verify it actually works, both by running its
automated test suites and by exercising every feature by hand. It assumes
no prior familiarity with the codebase.

## 1. What you're testing

LLM-Climate-Health is an ETL platform: a user describes a disease, a
region, a time span, and which climate variables matter (either through a
form or in plain language, parsed by an LLM), and the platform retrieves,
harmonizes, and joins disease case-count data with climate (reanalysis)
data into one dataset, with a plain-language explanation of what was done.
It is not a prediction tool. The validated case is **dengue in Thailand**
(OpenDengue case counts + ERA5 reanalysis climate data); malaria and
cholera are also wired up via WHO GHO data.

Two ways to test it, both covered below:

- **The deployed URL** Sergi shares with you — nothing to install, but the
  free-tier host sleeps after ~15 minutes idle and takes ~30-50s to wake up
  on the first request.
- **Running it locally** — Section 2 below. Needed anyway to run the
  automated test suites.

## 2. Running it locally

Requirements: Python 3.12+, Flutter (stable channel), and optionally a
[free Gemini API key](https://aistudio.google.com/apikey) — the platform
runs without one, just with the AI-assisted parsing/explanation features
degraded (see §5).

```bash
# Terminal 1 — backend
cd backend
python -m venv .venv
.venv\Scripts\activate        # Windows; use `source .venv/bin/activate` on macOS/Linux
pip install -r requirements.txt
copy .env.example .env        # Windows; `cp` on macOS/Linux — then optionally fill in GEMINI_API_KEY
uvicorn app.main:app --port 8000 --reload

# Terminal 2 — frontend
cd frontend
flutter pub get
flutter run -d chrome --web-port=5173
```

The frontend opens in Chrome at `http://localhost:5173` and talks to the
backend at `http://127.0.0.1:8000` by default.

## 3. Running the automated test suites

Both suites are self-contained: they mock every external API (Open-Meteo,
NASA POWER, WHO GHO, HDX, Gemini, TMD) except for one deliberately
network-dependent backend test, so a normal run needs no API keys and, for
the fast/offline command below, no internet access either.

### Backend (pytest)

```bash
cd backend
python -m venv .venv          # skip if you already created one in §2
.venv\Scripts\activate
pip install -r requirements.txt -r requirements-dev.txt

pytest -m "not network"       # fast, fully offline — what CI would run
pytest                        # everything, including one live Open-Meteo call
```

Expected result: `pytest -m "not network"` reports **80 passed**; the full
`pytest` run reports **81 passed** (the extra one is
`test_integrate_end_to_end_dengue_thailand`, which needs internet access to
reach the real Open-Meteo API — it's the only test in the suite that does).

### Frontend (flutter test)

```bash
cd frontend
flutter pub get               # skip if you already ran this in §2
flutter test
flutter analyze
```

Expected result: `flutter test` reports **34 tests passed**, `flutter
analyze` reports **No issues found**.

### What's covered

- **Backend**: every endpoint (`/api/health`, `/api/options`,
  `/api/parse-request`, `/api/integrate`, `/api/integrate/upload`,
  `/api/search-case-sources`), every validation branch (unknown
  disease/region, invalid date range, future end date, climate-source/region
  mismatch, missing custom-source fields), the full case-data pipeline (all
  four sources: builtin CSV, custom URL, custom upload, WHO GHO), climate
  data aggregation (Open-Meteo, NASA POWER, TMD, including missing-data
  edge cases), the in-memory cache, and the Gemini-backed parsing/
  explanation logic (both success and graceful-fallback paths).
- **Frontend**: every model's JSON decoding (including malformed/partial
  backend responses), the request form's region/source-compatibility logic
  and validation, the world-map region picker, the API client (including
  its multipart file-upload path and error handling), and the CSV/JSON/PDF
  export logic.

## 4. Manual walkthrough

With the app open (locally or via the deployed URL), work through this in
order — it touches every major feature.

1. **Health check.** `GET /api/health` (e.g. open
   `http://127.0.0.1:8000/api/health` in a new tab) should return
   `{"status": "ok"}`.

2. **AI-assisted request parsing.** In the "Describe what you need" free-text
   box at the top, type something like *"dengue in Thailand from 2015 to
   2023, yearly"* and submit. If a `GEMINI_API_KEY` is configured, the form
   below prefills with disease=Dengue, region=Thailand, and the given dates,
   with a short note on any assumptions made. Without a key configured, this
   instead shows a clear message that AI-assisted parsing isn't available —
   the form itself remains fully usable manually either way.

3. **Region picker.** Click the globe icon next to the region field to open
   the map dialog. Countries with real built-in data for the selected
   disease are shaded; clicking one — or a marker dot, for small countries
   without a visible polygon — selects it and enables "Use this region".

4. **Source compatibility filtering.** Switch the disease dropdown between
   Dengue/Malaria/Cholera and watch the region field, the climate-source
   dropdown, and the case-data-source dropdown all adjust to what's actually
   available — e.g. the "TMD" climate source only appears when the region is
   Thailand, and "Built-in scientific source" disappears for a disease/region
   combination with no real data.

5. **Coverage-window warning.** Pick Disease=Dengue, Region=Italy, and a date
   range before 2024 (e.g. 2015-01 to 2020-01). You should see an amber
   warning that Italy's built-in dengue data only covers 2024-2025 and this
   date range won't overlap it — the query still runs (climate data comes
   back, case counts come back empty), it's advisory rather than blocking.

6. **Run the validation case.** Set Disease=Dengue, Region=Thailand, dates
   2015-01 to 2023-12, both climate variables checked, source=Open-Meteo
   ERA5 + Built-in, and click "Run integration". You should get: a
   step-by-step pipeline trace, a plain-language explanation, a chart and
   data table of monthly case counts + temperature + precipitation, and two
   source citations.

7. **TMD (Thailand-only) climate source.** Switch the climate source to
   "Thai Meteorological Department (TMD)" with region=Thailand and run
   again. Without `TMD_API_UID`/`TMD_API_UKEY` configured, this correctly
   fails with a clear "TMD_API_UID/TMD_API_UKEY are not configured" error
   (502) rather than a generic failure — this is expected unless those
   credentials have been set up (see §5).

8. **Custom case-data sources.** Switch the case-data source to "Custom URL"
   and paste a link to any CSV with a recognizable date and case-count
   column (e.g. from the WHO GHO/HDX search results — see next point), or to
   "Uploaded file" and pick a local CSV. Both should run the same pipeline
   using your data instead of the built-in source.

9. **Live source search.** Switch the case-data source to "WHO GHO" — a
   search dialog opens automatically. Search for a term like "malaria" and
   pick a result; the indicator gets wired in as the case-data source for
   the next run.

10. **Export.** After a successful run, use the download buttons to export
    the dataset as CSV, as JSON, and as a PDF report; check that each file
    opens and contains the expected columns/sections.

11. **Error handling.** Try: an end date in the future (rejected with a
    clear message), a disease/region combination with no data (the
    "no built-in data" message, prompting a custom source instead).

## 5. Configuration reference

| Variable | Required? | Effect if unset |
|---|---|---|
| `GEMINI_API_KEY` | No | AI-assisted parsing (§4.2) shows an unavailable message; explanations fall back to a static description (`explanation_source: "fallback"` in the API response). |
| `GEMINI_MODEL` | No | Defaults to `gemini-flash-lite-latest`. |
| `TMD_API_UID` / `TMD_API_UKEY` | No | The TMD climate source (§4.7) fails with a clear error; Open-Meteo and NASA POWER are unaffected. |

Set these in `backend/.env` (copy `backend/.env.example`) for local runs, or
in the hosting provider's environment-variable settings for the deployed
instance.

## 6. Quick API reference

```bash
BASE=http://127.0.0.1:8000   # or the deployed URL

curl "$BASE/api/health"
curl "$BASE/api/options"
curl "$BASE/api/search-case-sources?disease=malaria&region=Kenya"

curl -X POST "$BASE/api/integrate" \
  -H "Content-Type: application/json" \
  -d '{"disease":"dengue","region":"Thailand","variables":["temperature","precipitation"],"start_date":"2020-01-01","end_date":"2020-06-01"}'
```

## 7. Known limitations (by design, not oversights)

- **TMD's endpoint is plain HTTP, not HTTPS** — that's the Thai
  Meteorological Department's own documented endpoint
  (`data.tmd.go.th`); its exact JSON response shape also hasn't been
  verified against a live account yet (see `backend/app/services/tmd.py`'s
  module docstring) since no credentials were available during development.
- **The coverage-window warning (§4.5) is advisory, not enforced** — the
  backend deliberately still runs an out-of-window query rather than
  rejecting it, so a user can still explore what data does exist.
- **One backend test needs internet access** —
  `test_integrate_end_to_end_dengue_thailand` is the only test that calls a
  real external API (Open-Meteo); everything else mocks its network calls.
