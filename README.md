# LLM-Climate-Health

An LLM-driven ETL platform for climate-health data integration — the
practical component of Sergi Koniashvili's bachelor thesis (Informatics,
University of Bremen).

A user describes what they need — a disease, a region, a time span, which
climate variables matter — either by filling in a form or in plain language,
which an LLM (Gemini) turns into a form prefill for review. The platform then
retrieves, cleans, and temporally joins gridded/reanalysis climate data with
disease case-count surveillance data into one harmonized, analysis-ready
dataset, and has the LLM explain each step in plain language for a user with
no programming or climate-science background. It is not a prediction tool —
the output is integrated input data for downstream disease modeling.

Validation case: dengue in Thailand, using the OpenDengue case-count archive
and ERA5 reanalysis climate data. The disease/case-data layer is designed to
extend to other diseases (malaria and cholera are already wired up via WHO
GHO data) and, in principle, other mosquito/vector-borne diseases.

## Architecture

Single Docker image, one public URL: a FastAPI backend serves both the REST
API and the built Flutter web frontend.

- **Backend** (`backend/`, FastAPI + pandas): fetches case-count data (bundled
  CSVs or user-supplied URL/upload) and climate data (Open-Meteo ERA5 archive
  or NASA POWER), aggregates and joins them on a shared period key, and calls
  Gemini for request-parsing and result-explanation. See
  [`backend/README.md`](backend/README.md).
- **Frontend** (`frontend/`, Flutter web): a natural-language request box, a
  structured form, and a results view (pipeline steps, explanation, chart,
  data table, sources, PDF export). See [`frontend/README.md`](frontend/README.md).

## Quick start (local)

```bash
# Terminal 1 — backend
cd backend
pip install -r requirements.txt
uvicorn app.main:app --port 8000

# Terminal 2 — frontend
cd frontend
flutter pub get
flutter run -d chrome --web-port=5173
```

For deploying to a public URL (Render.com, single Docker image), see
[`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md).

## Docs

- [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) — deploy runbook
- [`docs/requirements/anforderungskatalog.tex`](docs/requirements/anforderungskatalog.tex) —
  bilingual (DE/EN) requirements catalog for the thesis
- [`docs_ka/dokumentacia.tex`](docs_ka/dokumentacia.tex) — Georgian-language
  technical documentation
