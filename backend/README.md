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

## Request Options (`/api/integrate`)

In addition to core parameters (`disease`, `region`, `variables`, `start_date`, `end_date`, `climate_source`), the API supports:
- `lag_periods: list[int]` — optional list of temporal lags (1..6) for climate features (e.g. `[1, 3]`). Uses a lag buffer (Lowe et al. 2021) to compute lagged predictors without dropping initial observation rows.

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
