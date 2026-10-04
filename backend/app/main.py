"""FastAPI application entry point for the Climate-Health ETL demo backend.

Exposes:
  - GET  /api/health            liveness check
  - GET  /api/options           diseases/regions/sources the frontend can offer
  - POST /api/integrate         run the pipeline for a JSON request
  - POST /api/integrate/upload  run the pipeline using a user-uploaded case-data file

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

from datetime import date
from pathlib import Path

import requests
from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.config import (
    AGGREGATIONS,
    CASE_DATA_SOURCES,
    CLIMATE_SOURCE_REGIONS,
    CLIMATE_SOURCES,
    DISEASE_REGION_COVERAGE,
    DISEASES,
    DISEASES_WITH_DATA,
    POPULATION_SOURCES,
    REGIONS,
    TMD_API_UID,
    TMD_API_UKEY,
)
from pydantic import BaseModel

from app.models import (
    ChatRequest,
    ChatResponse,
    DataTransformationAudit,
    DiscoveredSource,
    IntegrationRequest,
    IntegrationResponse,
    ParsedRequest,
    StatisticalSummary,
)
from app.services import cache
from app.services.chat import process_chat
from app.services.etl import run_integration
from app.services.llm import (
    explain_data_transformation,
    explain_pipeline,
    is_llm_available,
    parse_request,
)
from app.services.source_discovery import search_case_sources
from app.services.tmd import ConfigurationError

_MAX_UPLOAD_BYTES = 10 * 1024 * 1024  # 10 MB — a case-count CSV has no business being larger

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
                # Per-region (earliest, latest) period actually present in
                # the builtin file — a region can have data at all while
                # only covering a narrow recent window (e.g. Italy/France
                # dengue is 2024-2025 only, a real 2024 local outbreak, not
                # decades of history), so the frontend can warn before a
                # query whose date range can't overlap any real case data.
                "region_coverage": {
                    region: list(span)
                    for region, span in DISEASE_REGION_COVERAGE.get(key, {}).items()
                },
            }
            for key, meta in DISEASES.items()
        },
        "regions": {
            name: {"label": info["label"], "lat": info["lat"], "lon": info["lon"]}
            for name, info in REGIONS.items()
        },
        "variables": ["temperature", "precipitation"],
        "scenarios": ["historical"],
        "aggregations": AGGREGATIONS,
        "climate_sources": CLIMATE_SOURCES,
        "climate_source_regions": {
            source: sorted(regions) for source, regions in CLIMATE_SOURCE_REGIONS.items()
        },
        "case_data_sources": CASE_DATA_SOURCES,
        "population_sources": POPULATION_SOURCES,
    }


class ParseRequestBody(BaseModel):
    text: str


@app.post("/api/parse-request", response_model=ParsedRequest)
def parse_request_endpoint(body: ParseRequestBody):
    """Turns a free-text description into a best-effort request plan the
    frontend uses to prefill the form — it never runs the pipeline itself,
    so a bad guess only costs a review, not a bad run."""
    if not is_llm_available():
        raise HTTPException(
            503,
            "AI-assisted parsing needs an API key configured on the server "
            "— fill the form in below instead.",
        )
    try:
        return parse_request(
            body.text,
            diseases={key: meta.label for key, meta in DISEASES.items()},
            regions=list(REGIONS.keys()),
            variables=["temperature", "precipitation"],
            aggregations=AGGREGATIONS,
            climate_sources=list(CLIMATE_SOURCES.keys()),
        )
    except RuntimeError as exc:
        raise HTTPException(503, str(exc)) from exc


@app.post("/api/chat", response_model=ChatResponse)
def chat_endpoint(body: ChatRequest):
    """Conversational endpoint for the Climate-Health Copilot assistant.
    Features multilingual response (replies in the user's language),
    domain expertise, UI context awareness, and safe form actions."""
    return process_chat(body)



@app.get("/api/search-case-sources", response_model=list[DiscoveredSource])
def search_case_sources_endpoint(disease: str, region: str):
    """Searches WHO GHO and HDX for real, citable case-data sources for the
    given disease/region, so the user can pick one instead of being stuck
    with the single hardcoded built-in source. Best-effort: if both
    upstream APIs fail, this returns an empty list rather than an error —
    the user can still fall back to a custom URL/upload."""
    if disease not in DISEASES:
        raise HTTPException(400, f"Disease '{disease}' is not supported.")
    if region not in REGIONS:
        raise HTTPException(400, f"Region '{region}' is not available in this demo yet.")
    return search_case_sources(DISEASES[disease].label, region)


def _validate_common(req: IntegrationRequest) -> None:
    if req.region not in REGIONS:
        raise HTTPException(400, f"Region '{req.region}' is not available in this demo yet.")
    if req.disease not in DISEASES:
        raise HTTPException(400, f"Disease '{req.disease}' is not supported.")
    if req.start_date >= req.end_date:
        raise HTTPException(400, "start_date must be before end_date.")
    if req.end_date > date.today():
        raise HTTPException(
            400,
            "end_date can't be in the future — climate archives only cover "
            "dates up to today.",
        )
    allowed_regions = CLIMATE_SOURCE_REGIONS.get(req.climate_source)
    if allowed_regions is not None and req.region not in allowed_regions:
        raise HTTPException(
            400,
            f"Climate source '{req.climate_source}' only covers "
            f"{', '.join(sorted(allowed_regions))} — choose a different source or region.",
        )


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
    if req.case_data_source == "who_gho" and not req.who_indicator_code:
        raise HTTPException(
            400,
            "who_indicator_code is required when case_data_source='who_gho' — "
            "call GET /api/search-case-sources first to pick one.",
        )


def _run_integration_or_502(*args, **kwargs):
    """Thin wrapper around `run_integration` that turns a known, expected
    upstream failure (e.g. TMD credentials not configured, a custom source
    with unrecognized columns, a dead/unreachable custom URL, a climate API
    rejecting the request) into a clear error response instead of an opaque
    500 — the same honest-failure principle already used for
    /api/parse-request."""
    try:
        return run_integration(*args, **kwargs)
    except ConfigurationError as exc:
        raise HTTPException(503, str(exc)) from exc
    except (RuntimeError, ValueError) as exc:
        raise HTTPException(502, str(exc)) from exc
    except requests.exceptions.RequestException as exc:
        raise HTTPException(502, f"Could not reach an upstream data source: {exc}") from exc


def _build_response(
    req: IntegrationRequest,
    steps: list[str],
    records,
    resolution: str,
    cached: bool,
    last_verified: str,
    uploaded_file_name: str | None = None,
    transformation_audit: DataTransformationAudit | None = None,
    statistical_summary: StatisticalSummary | None = None,
) -> IntegrationResponse:
    explanation, explanation_source = explain_pipeline(
        req.disease, req.region, steps, records, statistical_summary=statistical_summary
    )

    if req.case_data_source == "builtin":
        case_source_citation = f"Case counts: {DISEASES[req.disease].citation}"
    elif req.case_data_source == "who_gho":
        indicator_desc = req.who_indicator_name or req.who_indicator_code
        case_source_citation = (
            f"Case counts: WHO Global Health Observatory, indicator "
            f"{req.who_indicator_code} — {indicator_desc} (ghoapi.azureedge.net)"
        )
    elif req.case_data_source == "custom_url":
        case_source_citation = f"Case counts: user-provided CSV at {req.custom_source_url}"
    else:
        case_source_citation = f"Case counts: user-uploaded file '{uploaded_file_name}'"

    pop_source = POPULATION_SOURCES.get(req.population_source, {})
    pop_citation = pop_source.get(
        "citation",
        "World Bank Group (2024), World Development Indicators: Population, total (SP.POP.TOTL)",
    )
    sources = [
        f"Climate data: {CLIMATE_SOURCES[req.climate_source]['citation']}",
        case_source_citation,
        f"Demographics & Population: {pop_citation}",
    ]
    return IntegrationResponse(
        request_echo=req,
        resolution=resolution,
        steps=steps,
        explanation=explanation,
        explanation_source=explanation_source,
        data=records,
        sources=sources,
        cached=cached,
        last_verified=last_verified,
        transformation_audit=transformation_audit,
        statistical_summary=statistical_summary,
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
        population_source=req.population_source,
        custom_source_url=req.custom_source_url,
        who_indicator_code=req.who_indicator_code,
    )
    hit = cache.get(cache_key)
    if hit is not None:
        cached_audit = (
            DataTransformationAudit(**hit["transformation_audit"])
            if hit.get("transformation_audit")
            else None
        )
        cached_stats = (
            StatisticalSummary(**hit["statistical_summary"])
            if hit.get("statistical_summary")
            else None
        )
        return _build_response(
            req,
            hit["steps"],
            hit["records"],
            hit["resolution"],
            True,
            hit["last_verified"],
            transformation_audit=cached_audit,
            statistical_summary=cached_stats,
        )

    steps, records, resolution, audit_data, stat_summary = _run_integration_or_502(
        req.disease,
        req.region,
        req.variables,
        req.start_date,
        req.end_date,
        aggregation=req.aggregation,
        climate_source=req.climate_source,
        case_data_source=req.case_data_source,
        population_source=req.population_source,
        custom_source_url=req.custom_source_url,
        who_indicator_code=req.who_indicator_code,
        who_indicator_name=req.who_indicator_name,
    )
    transformation_audit = None
    if audit_data:
        human_explanation = explain_data_transformation(audit_data, req.disease, req.region)
        transformation_audit = DataTransformationAudit(
            original_columns=audit_data.get("original_columns", []),
            selected_date_column=audit_data.get("selected_date_column"),
            selected_value_column=audit_data.get("selected_value_column"),
            total_rows_received=audit_data.get("total_rows_received", 0),
            valid_rows_retained=audit_data.get("valid_rows_retained", 0),
            dropped_rows_count=audit_data.get("dropped_rows_count", 0),
            transformations_applied=audit_data.get("transformations_applied", []),
            human_explanation=human_explanation,
        )

    last_verified = cache.now_iso()
    cache.set(
        cache_key,
        {
            "steps": steps,
            "records": records,
            "resolution": resolution,
            "last_verified": last_verified,
            "transformation_audit": (
                transformation_audit.model_dump() if transformation_audit else None
            ),
            "statistical_summary": (
                stat_summary.model_dump() if stat_summary else None
            ),
        },
    )
    return _build_response(
        req,
        steps,
        records,
        resolution,
        False,
        last_verified,
        transformation_audit=transformation_audit,
        statistical_summary=stat_summary,
    )


@app.post("/api/integrate/upload", response_model=IntegrationResponse)
async def integrate_with_upload(
    disease: str = Form(...),
    region: str = Form(...),
    variables: str = Form(...),
    start_date: str = Form(...),
    end_date: str = Form(...),
    aggregation: str = Form("native"),
    climate_source: str = Form("open-meteo-era5"),
    population_source: str = Form("worldbank"),
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
        population_source=population_source,
    )
    _validate_common(req)

    content = await file.read()
    if len(content) > _MAX_UPLOAD_BYTES:
        raise HTTPException(
            413, f"Uploaded file exceeds the {_MAX_UPLOAD_BYTES // (1024 * 1024)} MB limit."
        )
    steps, records, resolution, audit_data, stat_summary = _run_integration_or_502(
        req.disease,
        req.region,
        req.variables,
        req.start_date,
        req.end_date,
        aggregation=req.aggregation,
        climate_source=req.climate_source,
        case_data_source="custom_upload",
        population_source=req.population_source,
        upload_content=content,
    )
    transformation_audit = None
    if audit_data:
        human_explanation = explain_data_transformation(audit_data, req.disease, req.region)
        transformation_audit = DataTransformationAudit(
            original_columns=audit_data.get("original_columns", []),
            selected_date_column=audit_data.get("selected_date_column"),
            selected_value_column=audit_data.get("selected_value_column"),
            total_rows_received=audit_data.get("total_rows_received", 0),
            valid_rows_retained=audit_data.get("valid_rows_retained", 0),
            dropped_rows_count=audit_data.get("dropped_rows_count", 0),
            transformations_applied=audit_data.get("transformations_applied", []),
            human_explanation=human_explanation,
        )

    return _build_response(
        req,
        steps,
        records,
        resolution,
        False,
        cache.now_iso(),
        uploaded_file_name=file.filename,
        transformation_audit=transformation_audit,
        statistical_summary=stat_summary,
    )


# Serve the built Flutter web app (if present) so a single deployed
# container or local server can host both the API and the frontend on one URL.
_STATIC_DIR = Path(__file__).resolve().parent.parent / "static"
if _STATIC_DIR.exists():
    app.mount("/", StaticFiles(directory=_STATIC_DIR, html=True), name="static")
