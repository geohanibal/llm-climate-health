# Backend — LLM-Climate-Health ETL API

FastAPI service that fetches, harmonizes, and joins disease case-count data
with climate (reanalysis) data for a chosen disease/region/period, and uses
Gemini for two LLM-facing pieces: turning a free-text request into a form
prefill, and writing a plain-language explanation of a finished run.

## Setup

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate      # Windows
pip install -r requirements.txt
copy .env.example .env      # then fill in GEMINI_API_KEY
uvicorn app.main:app --port 8000 --reload
```

Without `GEMINI_API_KEY` set, the service still runs: `explain_pipeline`
falls back to a static description (and the response flags this via
`explanation_source: "fallback"`), and `POST /api/parse-request` returns
`503` instead of guessing.

`TMD_API_UID`/`TMD_API_UKEY` (free registration at data.tmd.go.th) enable
the Thailand-only `"tmd"` climate source; without them, requests with
`climate_source=tmd` fail with a clear error and the other two climate
sources (Open-Meteo ERA5, NASA POWER) are unaffected. **Note:** TMD's exact
response field names haven't been verified against a live account yet —
`app/services/tmd.py`'s `_parse_tmd_response` may need a quick adjustment
once real credentials are available (see that file's module docstring).

## Endpoints

| Method | Path                            | Purpose                                                        |
|--------|---------------------------------|------------------------------------------------------------------|
| GET    | `/api/health`                   | Liveness check                                                   |
| GET    | `/api/options`                  | Diseases/regions/sources the frontend can offer                  |
| POST   | `/api/parse-request`            | Free-text → best-effort request plan (prefill only, never runs)  |
| POST   | `/api/integrate`                | Run the ETL pipeline for a JSON request (supports `lag_periods`) |
| POST   | `/api/integrate/upload`         | Same pipeline, case data from an uploaded CSV (supports `lag_periods`) |
| POST   | `/api/chat`                     | Interactive Copilot assistant for domain inquiries and prefill   |
| POST   | `/api/extract-literature`       | AI-based metadata extraction from uploaded paper PDFs or URLs    |
| GET    | `/api/search-case-sources`      | Real-time search of official WHO GHO indicators and HDX datasets |
| GET    | `/api/search-population-sources`| Real-time search of World Bank indicators and HDX demographics   |
| POST   | `/api/compare-sources`          | Empirical comparison of two sources over overlapping periods (FR-27) |
| POST   | `/api/compare-sources/upload`   | Multipart comparison of Source A against an uploaded Source B CSV (FR-27) |

## Request Options (`/api/integrate`)

In addition to core parameters (`disease`, `region`, `start_date`, `end_date`, `climate_source`), the API supports:
- `variables: list[str]` — supported climate variables: `"temperature"` (mean), `"precipitation"` (sum), `"temperature_min"` (daily minimum mean), `"temperature_max"` (daily maximum mean) (Suttirat et al. 2026).
- `lag_periods: list[int]` — optional list of temporal lags (1..6) for climate features (e.g. `[1, 3]`, producing `<variable>_lag<k>`). Uses a lag buffer (Lowe et al. 2021) to compute lagged predictors without dropping initial observation rows.
- `case_lag_periods: list[int]` — optional list of temporal lags (1..6) for case counts (e.g. `[1, 2]`, producing `cases_lag<k>`; candidate FR-29 / A1b, Suttirat et al. 2026, pp. 9–10; Colón-González et al. 2021, p. 9). Fetches case data with a `max(k)`-period lag buffer before `start_date`; missing periods produce `NaN/null` (rule A20).
- `climate_moving_average: list[int]` — optional list of trailing window lengths in periods (2..6) for climate moving averages (e.g. `[3]`, producing `<variable>_ma<w>` as the mean of lag 0 .. lag `w-1`, including the mean of monthly sums for precipitation; candidate FR-30, Colón-González et al. 2021, p. 9). Reuses the climate lag buffer; if any period in the window is missing, the result is `NaN/null` (rule A20).

## Provenance fields in the response (FR-25)

Every `/api/integrate` and `/api/integrate/upload` response contains, next to
`sources`, a `licenses` list (licence / terms of use of each source, same
order as `sources`) and `system_version` (`APP_VERSION` environment variable,
otherwise Render's `RENDER_GIT_COMMIT`, otherwise the local `git-<short commit>`, otherwise `unknown`). Licences are defined in
`app/config.py`, each with the official page and check date in a comment.
The frontend exports them with the data.

## Data Coverage & Gap Detection (FR-26)

Every integration response includes `data_coverage: list[DataCoverage]` analyzing
temporal completeness for each integrated data column (case_count, population,
incidence, climate variables). It computes total periods, periods with values,
missing counts, missing percentage, consecutive missing ranges, first/last available
period, and deterministic reasons (`outside_source_coverage`, `gaps_inside_source`,
`not_provided_by_source`, or `unknown`). Excludes any Task B climate lag-buffer
periods from the analysis. In accordance with A20, the backend never fills gaps
with synthetic values.

## Source Comparison (FR-27 / A19)

`POST /api/compare-sources` and `POST /api/compare-sources/upload` compare two sources
over their overlapping period. Source B options include:
- **Climate:** Open-Meteo ERA5, NASA POWER MERRA-2, TMD (only if configured and region is Thailand), or an uploaded CSV.
- **Disease cases:** WHO GHO indicator chosen via search, `custom_url`, or an uploaded CSV.

Key features:
- **WHO GHO complete calendar years:** When comparing with WHO GHO, both runs aggregate to yearly resolution. To avoid distortion from incomplete years, baseline monthly records are checked for all 12 complete calendar months; incomplete or partial years are excluded from the comparison, listed in `excluded_years`, and presented to the user with a low-sample warning if $n < 6$. No disaggregation to months is ever performed.
- **Multipart upload (`/api/compare-sources/upload`):** Accepts `request` (JSON string) and `file` (multipart CSV, max 10 MB). The file is used strictly in-memory for the comparison and never stored. If Source A was an upload, the endpoint returns 400.
- **Bivariate metrics & verdicts:** Computes bivariate metrics for each base variable (Pearson $r$, formatted $p$-value, mean difference $B - A$, MAD, relative MAD%), returns deterministic heuristic verdicts (`very_similar`, `similar`, `clearly_different`, `too_few_points`), and surfaces domain notes on the shared seasonal cycle (climate) and case definition differences (cases; Clarke et al. 2024).
- **Non-destructive & fast:** Calls `run_integration` directly with `lag_periods=[]`, bypassing LLM generation for speed and preserving zero Gemini quota usage. The primary integrated dataset and cache remain completely unmodified.

## Regional (Admin1) Case Data — Multi-Country Monthly Datasets (FR-28 Part 1 / Tasks H & I)

To support province-level climate-health modelling for endemic countries (Suttirat et al. 2026, p. 5; Lowe et al. 2021, p. e211), the backend includes a generic reproducible offline build pipeline and loader for monthly Admin1 dengue case counts across four countries (`THA`, `LAO`, `LKA`, `SLV`):

- **Offline build script (`scripts/build_dengue_admin1.py`):** Accepts a list of ISO3 codes (default: `THA LAO LKA SLV`), downloads (or reads from `--spatial-zip` / `--hdx-dir` / `--hdx-xlsx`) the pinned OpenDengue V1.3 Spatial extract (`Spatial_extract_V1_3.zip`, CC BY 4.0) and each country's HDX COD-AB boundaries (`<iso3>_admin_boundaries.xlsx`, CC BY-IGO), maps OpenDengue `adm_1_name` strings to official HDX Admin1 English names and P-codes via `app/data/admin1_name_map_<ISO3>.csv`, checks for duplicate `(admin1_pcode, month)` pairs (never summing silently), and writes `app/data/dengue_monthly_admin1_<ISO3>.csv`:
  - `THA` (Thailand): 77 provinces (`TH10`–`TH96`), 1993-01 to 2022-12, 27,024 rows (source: Royal Thai Survey Department).
  - `LAO` (Lao PDR): 16 mapped provinces (`LA01` Vientiane Capital and `LA10` Vientiane excluded), 1998-01 to 2010-12, 2,419 rows (source: National Geographic Department). The two OpenDengue series `VIENTIANE CAPITAL` and `VIENTIANE CAPITAL [PREFECTURE]` cover the same 156 months with identical `FAO_GAUL_code=1768` / `RNE_iso_code=LA-VI` but different counts, so neither can be assigned to `LA01` or `LA10` without guessing; both stay unresolved and are excluded.
  - `LKA` (Sri Lanka): 9 provinces (`LK1`–`LK9`), 1996-01 to 2004-12, 960 rows (source: Survey Department of Sri Lanka).
  - `SLV` (El Salvador): 14 departments (`SV01`–`SV14`), 2000-01 to 2009-08, 1,587 rows (source: `www.gadm.org`).
- **Loader (`app/services/case_data.py::load_dengue_admin1`):** `load_dengue_admin1(iso3, start, end, merge_changed_units=True)` returns `admin1_pcode, admin1_name, month, cases` within `[start, end]`. When `merge_changed_units=True` (default), Thailand's Bueng Kan (`TH38`, split from Nong Khai in 2011) is explicitly merged into Nong Khai (`TH43`) via `CHANGED_UNITS = {"THA": {"TH38": "TH43"}}` following Suttirat et al. (2026, p. 5). Missing months remain absent (rule A20). Licences and citations are registered in `app/config.py::REGIONAL_CASE_DATA_SOURCES`.

## Reproducible National Dengue Dataset Verification (Task J3 / A13)

`scripts/build_dengue_national.py` reproduces and empirically verifies the bundled national monthly dengue file (`app/data/dengue_monthly_by_iso3.csv`, 2,308 rows across 39 countries) against the pinned OpenDengue V1.3 National extract (`National_extract_V1_3.zip`, CC BY 4.0) and optionally compares with the Temporal extract (`Temporal_extract_V1_3.zip`). It never overwrites the bundled file by default (writes to `--out` and prints a per-country comparison table):
- **Empirical finding:** 100 % of the 2,308 bundled rows across all 39 countries are reproduced identically (`rows_equal=2,308`, `rows_different=0`, `months_only_in_bundled=0`, `months_only_in_repro=0`) from OpenDengue **V1.3 National extract** filtered strictly to `T_res == "Month"` (`S_res == "Admin0"`). No weekly (`T_res == "Week"`) or yearly (`T_res == "Year"`) records were converted into the bundled file.

## Tests

```bash
pip install -r requirements-dev.txt
pytest -v
```

All tests are network-free except `test_api.py::test_integrate_end_to_end_dengue_thailand`,
which hits the real Open-Meteo climate API — needs internet access.

## Layout

```text
app/
  main.py              FastAPI app, routes
  config.py            env vars, disease/region/source registries
  models.py            Pydantic request/response schemas
  services/
    etl.py             orchestrates one integration run
    coverage.py        data coverage and gap detection (FR-26)
    source_comparison.py  two-source comparison engine (FR-27)
    climate.py         Open-Meteo / NASA POWER clients
    case_data.py       builtin CSV + custom URL/upload case data
    lags.py            climate feature lag computation and lag buffer
    population.py      World Bank / UN WPP population data and interpolation
    statistics.py      cross-correlation analysis and summary metrics
    tmd.py             Thai Meteorological Department client
    who_gho.py         WHO Global Health Observatory client
    hdx.py             Humanitarian Data Exchange search client
    literature_extractor.py  PDF / URL metadata extractor via LLM
    llm.py             Gemini: parse_request, explain_pipeline
    chat.py            Copilot dialogue handling
    cache.py           in-process TTL cache
  data/                bundled case-count CSVs (national + Thailand Admin1) + name map + region registry
scripts/
  build_dengue_admin1.py    offline reproducible builder for dengue_monthly_admin1_<ISO3>.csv (FR-28)
  build_dengue_national.py  offline reproducible builder & verifier for dengue_monthly_by_iso3.csv (A13 / J3)
tests/                 pytest suite, mirrors services/ + main.py
```
