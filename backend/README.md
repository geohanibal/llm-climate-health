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
- `lag_periods: list[int]` — optional list of temporal lags (1..6) for climate features (e.g. `[1, 3]`). Uses a lag buffer (Lowe et al. 2021) to compute lagged predictors without dropping initial observation rows.

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
  data/                bundled case-count CSVs + region registry
tests/                 pytest suite, mirrors services/ + main.py
```
