"""FastAPI application entry point for the Climate-Health ETL demo backend.

Exposes:
  - GET  /api/health            liveness check
  - GET  /api/options           diseases/regions/sources the frontend can offer
  - POST /api/integrate         run the pipeline for a JSON request
  - POST /api/integrate/upload  run the pipeline using a user-uploaded case-data file

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

from pathlib import Path

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.config import (
    AGGREGATIONS,
    CASE_DATA_SOURCES,
    CLIMATE_SOURCES,
    DISEASES,
    DISEASES_WITH_DATA,
    REGIONS,
)
from app.models import IntegrationRequest, IntegrationResponse
from app.services import cache
from app.services.etl import run_integration
from app.services.llm import explain_pipeline

app = FastAPI(title="LLM-Driven Climate-Health ETL Platform (demo)")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/api/health")
def health():
    return {"status": "ok"}


@app.get("/api/options")
def options():
    """Describe what this validation-scope demo currently supports, so the
    frontend can populate its dropdowns without hardcoding anything."""
    return {
        "diseases": {
            key: {
                "label": meta.label,
                "native_resolution": meta.native_resolution,
                "regions": sorted(DISEASES_WITH_DATA.get(key, set())),
            }
            for key, meta in DISEASES.items()
        },
        "regions": {name: info["label"] for name, info in REGIONS.items()},
        "variables": ["temperature", "precipitation"],
        "scenarios": ["historical"],
        "aggregations": AGGREGATIONS,
        "climate_sources": CLIMATE_SOURCES,
        "case_data_sources": CASE_DATA_SOURCES,
    }


def _validate_common(req: IntegrationRequest) -> None:
    if req.region not in REGIONS:
        raise HTTPException(400, f"Region '{req.region}' is not available in this demo yet.")
    if req.disease not in DISEASES:
        raise HTTPException(400, f"Disease '{req.disease}' is not supported.")
    if req.start_date >= req.end_date:
        raise HTTPException(400, "start_date must be before end_date.")


def _validate_for_builtin_source(req: IntegrationRequest) -> None:
    _validate_common(req)
    supported_regions = DISEASES_WITH_DATA.get(req.disease, set())
    if req.case_data_source == "builtin" and req.region not in supported_regions:
        raise HTTPException(
            400,
            f"No built-in case-surveillance data source is wired up for "
            f"disease='{req.disease}' in region='{req.region}'. Choose a "
            f"custom source instead, or pick one of the supported regions.",
        )
    if req.case_data_source == "custom_url" and not req.custom_source_url:
        raise HTTPException(
            400, "custom_source_url is required when case_data_source='custom_url'."
        )


def _build_response(
    req: IntegrationRequest,
    steps: list[str],
    records,
    resolution: str,
    cached: bool,
    last_verified: str,
) -> IntegrationResponse:
    explanation = explain_pipeline(req.disease, req.region, steps, records)
    case_source_citation = (
        DISEASES[req.disease].citation
        if req.case_data_source == "builtin"
        else CASE_DATA_SOURCES[req.case_data_source]["citation"]
    )
    sources = [CLIMATE_SOURCES[req.climate_source]["citation"], case_source_citation]
    return IntegrationResponse(
        request_echo=req,
        resolution=resolution,
        steps=steps,
        explanation=explanation,
        data=records,
        sources=sources,
        cached=cached,
        last_verified=last_verified,
    )


@app.post("/api/integrate", response_model=IntegrationResponse)
def integrate(req: IntegrationRequest):
    if req.case_data_source == "custom_upload":
        raise HTTPException(
            400, "Use POST /api/integrate/upload (multipart) for the custom_upload source."
        )
    _validate_for_builtin_source(req)

    cache_key = cache.make_key(
        disease=req.disease,
        region=req.region,
        variables=tuple(sorted(req.variables)),
        start_date=str(req.start_date),
        end_date=str(req.end_date),
        aggregation=req.aggregation,
        climate_source=req.climate_source,
        case_data_source=req.case_data_source,
        custom_source_url=req.custom_source_url,
    )
    hit = cache.get(cache_key)
    if hit is not None:
        return _build_response(
            req, hit["steps"], hit["records"], hit["resolution"], True, hit["last_verified"]
        )

    steps, records, resolution = run_integration(
        req.disease,
        req.region,
        req.variables,
        req.start_date,
        req.end_date,
        aggregation=req.aggregation,
        climate_source=req.climate_source,
        case_data_source=req.case_data_source,
        custom_source_url=req.custom_source_url,
    )
    last_verified = cache.now_iso()
    cache.set(
        cache_key,
        {"steps": steps, "records": records, "resolution": resolution, "last_verified": last_verified},
    )
    return _build_response(req, steps, records, resolution, False, last_verified)


@app.post("/api/integrate/upload", response_model=IntegrationResponse)
async def integrate_with_upload(
    disease: str = Form(...),
    region: str = Form(...),
    variables: str = Form(...),
    start_date: str = Form(...),
    end_date: str = Form(...),
    aggregation: str = Form("native"),
    climate_source: str = Form("open-meteo-era5"),
    file: UploadFile = File(...),
):
    """Same pipeline as /api/integrate, but the case-count series comes from
    a user-uploaded CSV instead of a built-in scientific source."""
    req = IntegrationRequest(
        disease=disease,
        region=region,
        variables=variables.split(","),
        start_date=start_date,
        end_date=end_date,
        aggregation=aggregation,
        climate_source=climate_source,
        case_data_source="custom_upload",
    )
    _validate_common(req)

    content = await file.read()
    steps, records, resolution = run_integration(
        req.disease,
        req.region,
        req.variables,
        req.start_date,
        req.end_date,
        aggregation=req.aggregation,
        climate_source=req.climate_source,
        case_data_source="custom_upload",
        upload_content=content,
    )
    return _build_response(req, steps, records, resolution, False, cache.now_iso())


# Serve the built Flutter web app (if present) so a single deployed
# container can host both the API and the frontend on one URL. Mounted
# last so it never shadows the /api/* routes registered above.
_STATIC_DIR = Path(__file__).resolve().parent.parent / "static"
if _STATIC_DIR.exists():
    app.mount("/", StaticFiles(directory=_STATIC_DIR, html=True), name="static")
