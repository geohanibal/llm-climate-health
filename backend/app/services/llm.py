"""Gemini-backed plain-language explanation of the ETL pipeline, and
Gemini-backed extraction of a structured request from free-text user input.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

import json
import time
from collections import deque
from datetime import date
from threading import Lock

from app.config import GEMINI_API_KEY, GEMINI_MODEL
from app.models import ParsedRequest, PeriodRecord

_client = None
if GEMINI_API_KEY:
    from google import genai

    _client = genai.Client(api_key=GEMINI_API_KEY)


def is_llm_available() -> bool:
    return _client is not None


FALLBACK_EXPLANATION = (
    "This dataset combines monthly disease case counts from the selected "
    "surveillance source with monthly climate figures derived from a "
    "reanalysis-based archive. The two sources were aligned to the same "
    "year-month key so climate conditions can be compared against disease "
    "activity in the same period. This is harmonized input data, not a "
    "forecast or risk prediction."
)

# NFR: never exceed the Gemini free-tier rate limit (kept conservative at
# 15 requests/minute) so the demo does not fail mid-session with a 429.
_MAX_CALLS_PER_MINUTE = 15
_call_timestamps: deque[float] = deque()
_rate_limit_lock = Lock()


def _wait_for_rate_limit_slot() -> None:
    # The sleep must happen outside the lock: holding it during time.sleep()
    # would block every other thread from even checking the rate limit,
    # serializing all concurrent requests behind whichever one is waiting.
    while True:
        with _rate_limit_lock:
            now = time.monotonic()
            while _call_timestamps and now - _call_timestamps[0] > 60:
                _call_timestamps.popleft()
            if len(_call_timestamps) < _MAX_CALLS_PER_MINUTE:
                _call_timestamps.append(time.monotonic())
                return
            sleep_for = 60 - (now - _call_timestamps[0])
        if sleep_for > 0:
            time.sleep(sleep_for)


def build_prompt(
    disease: str, region: str, steps: list[str], records: list[PeriodRecord]
) -> str:
    sample = records[:3] + records[-3:] if len(records) > 6 else records
    sample_text = "\n".join(
        f"- {r.period}: case_count={r.case_count}, "
        f"temp_mean_c={r.temperature_mean_c}, "
        f"precip_sum_mm={r.precipitation_sum_mm}"
        for r in sample
    )
    return (
        "You are explaining a climate-health data integration pipeline to a "
        "user who has no programming or climate-science background. Given "
        "the processing steps and a sample of the resulting joined dataset "
        "below, write a short (4-6 sentence) plain-language explanation of "
        "what was done and what the data shows. Mention that "
        "temperature/precipitation figures come from reanalysis (a "
        "physically consistent reconstruction of historical weather, not a "
        "raw station reading), highlight any observable seasonal trends or "
        "associations between weather conditions (e.g. wetter or warmer seasons) "
        "and disease activity, and make clear this is descriptive "
        "integrated data, not a disease prediction.\n\n"
        f"Disease: {disease}\nRegion: {region}\n\n"
        "Pipeline steps performed:\n"
        + "\n".join(f"- {s}" for s in steps)
        + "\n\nSample of joined data (each row is one time period):\n"
        + sample_text
    )


def explain_pipeline(
    disease: str, region: str, steps: list[str], records: list[PeriodRecord]
) -> tuple[str, str]:
    """Returns (explanation_text, source) where source is "llm" or
    "fallback" — the caller surfaces this to the user so a canned string is
    never mistaken for a real model response."""
    if _client is None:
        return FALLBACK_EXPLANATION, "fallback"

    prompt = build_prompt(disease, region, steps, records)

    try:
        _wait_for_rate_limit_slot()
        resp = _client.models.generate_content(model=GEMINI_MODEL, contents=prompt)
        return resp.text.strip(), "llm"
    except Exception:
        return FALLBACK_EXPLANATION, "fallback"


def build_parse_prompt(
    text: str,
    diseases: dict[str, str],
    regions: list[str],
    variables: list[str],
    aggregations: list[str],
    climate_sources: list[str],
) -> str:
    """diseases maps key -> label; everything else is a flat list of valid
    values. The model must only ever choose from these closed vocabularies,
    or omit the field, never invent a value outside them."""
    disease_list = "\n".join(f"- {key}: {label}" for key, label in diseases.items())
    return (
        "You turn a non-expert's free-text description of a climate-health "
        "data request into a structured JSON plan. Only pick values from the "
        "closed lists given below (use the exact spelling/casing shown) or "
        "leave the field null if the text does not clearly imply one — never "
        "invent a value that is not in a list. Resolve relative dates (e.g. "
        f"\"the last 10 years\") against today's date, {date.today().isoformat()}. "
        "Dates must be the first day of a month, formatted YYYY-MM-01. If the "
        "text names only a year for the start of the range, use January of "
        "that year; if it names only a year for the end of the range, use "
        "December of that year, so the full range the user meant is covered "
        "(e.g. \"from 2015 to 2023\" means start_date=2015-01-01, "
        "end_date=2023-12-01).\n\n"
        f"Valid diseases (key: label):\n{disease_list}\n\n"
        f"Valid regions (must match exactly): {', '.join(regions)}\n\n"
        f"Valid variables: {', '.join(variables)}\n"
        f"Valid aggregations: {', '.join(aggregations)} — \"native\" means "
        "the data's own original/as-reported resolution (e.g. \"monthly\", "
        "\"as reported\", or no granularity mentioned at all); map wording "
        "like that to \"native\" rather than leaving aggregation null.\n"
        f"Valid climate_source values: {', '.join(climate_sources)}\n\n"
        "Respond with a single JSON object with exactly these keys: "
        "disease, region, variables (array), start_date, end_date, "
        "aggregation, climate_source, notes. \"notes\" is a short "
        "plain-language sentence noting any assumptions you made or "
        "anything the text left unclear.\n\n"
        f'User request: "{text}"'
    )


def _coerce_parsed_json(
    raw: dict,
    valid_diseases: set[str],
    valid_regions: set[str],
    valid_climate_sources: set[str],
) -> ParsedRequest:
    """Pure validation/clamping of the model's raw JSON reply: any value
    outside the closed vocabulary this platform actually supports is
    dropped to None (never guessed at) and called out in `notes`, so a
    hallucinated disease/region can never silently reach the ETL pipeline."""
    notes = str(raw.get("notes") or "").strip()
    extra_notes: list[str] = []

    disease = raw.get("disease")
    if disease is not None and disease not in valid_diseases:
        extra_notes.append(f"model suggested an unrecognized disease '{disease}'")
        disease = None

    region = raw.get("region")
    if region is not None and region not in valid_regions:
        extra_notes.append(f"model suggested an unrecognized region '{region}'")
        region = None

    variables = raw.get("variables")
    if not isinstance(variables, list) or not variables:
        variables = None
    else:
        variables = [v for v in variables if v in ("temperature", "precipitation")] or None

    def _clean_date(value):
        try:
            return date.fromisoformat(value) if value else None
        except (TypeError, ValueError):
            return None

    aggregation = raw.get("aggregation")
    if aggregation not in ("native", "yearly", "decadal"):
        aggregation = None

    climate_source = raw.get("climate_source")
    if climate_source not in valid_climate_sources:
        climate_source = None

    if extra_notes:
        notes = (notes + " " if notes else "") + "; ".join(extra_notes) + "."

    return ParsedRequest(
        disease=disease,
        region=region,
        variables=variables,
        start_date=_clean_date(raw.get("start_date")),
        end_date=_clean_date(raw.get("end_date")),
        aggregation=aggregation,
        climate_source=climate_source,
        notes=notes or "No assumptions needed.",
    )


def parse_request(
    text: str,
    diseases: dict[str, str],
    regions: list[str],
    variables: list[str],
    aggregations: list[str],
    climate_sources: list[str],
) -> ParsedRequest:
    """Raises RuntimeError if the LLM is unavailable or the call/parse fails
    — callers should turn that into a clear error, not a silent guess,
    since (unlike `explain_pipeline`) there is no safe canned fallback for
    "what did the user actually ask for"."""
    if _client is None:
        raise RuntimeError("LLM is not configured (no GEMINI_API_KEY).")

    prompt = build_parse_prompt(text, diseases, regions, variables, aggregations, climate_sources)
    try:
        _wait_for_rate_limit_slot()
        resp = _client.models.generate_content(
            model=GEMINI_MODEL,
            contents=prompt,
            config={"response_mime_type": "application/json"},
        )
        raw = json.loads(resp.text)
    except Exception as exc:
        raise RuntimeError(f"Could not parse the request with the LLM: {exc}") from exc

    return _coerce_parsed_json(raw, set(diseases), set(regions), set(climate_sources))


def _fallback_audit_explanation(audit: dict) -> str:
    date_col = audit.get("selected_date_column") or "date"
    val_col = audit.get("selected_value_column") or "cases"
    total = audit.get("total_rows_received", 0)
    valid = audit.get("valid_rows_retained", 0)
    dropped = audit.get("dropped_rows_count", 0)
    transforms = ", ".join(audit.get("transformations_applied", [])) or "standard temporal normalization"

    msg = (
        f"Received {total} row(s) with columns: {audit.get('original_columns')}. "
        f"Identified '{date_col}' as the temporal index and '{val_col}' as the disease case metric. "
        f"Applied: {transforms}. Retained {valid} valid record(s)"
    )
    if dropped > 0:
        msg += f" ({dropped} row(s) dropped due to unparseable dates)."
    else:
        msg += "."
    return msg


def explain_data_transformation(audit: dict, disease: str = "", region: str = "") -> str:
    """Generates a plain-language explanation of how the custom dataset was
    harmonized, which columns were selected, and what was filtered out."""
    if _client is None:
        return _fallback_audit_explanation(audit)

    prompt = (
        "You are an expert data engineer explaining an automated data transformation "
        "and harmonization step to a researcher or public health official.\n"
        f"Context: Preparing case data for {disease or 'disease'} in {region or 'region'}.\n"
        "Audit Log Details:\n"
        f"- Original Columns Received: {audit.get('original_columns')}\n"
        f"- Selected Date Column: {audit.get('selected_date_column')}\n"
        f"- Selected Case Value Column: {audit.get('selected_value_column')}\n"
        f"- Total Input Rows: {audit.get('total_rows_received')}\n"
        f"- Valid Rows Retained: {audit.get('valid_rows_retained')}\n"
        f"- Dropped / Filtered Rows: {audit.get('dropped_rows_count')}\n"
        f"- Transformations Applied: {audit.get('transformations_applied')}\n\n"
        "Write a concise, transparent 2-4 sentence explanation in plain language explaining: "
        "1. What raw data was received.\n"
        "2. Which columns were chosen for dates and case counts.\n"
        "3. Any rows or noise filtered out/dropped and why.\n"
        "4. The final clean dataset ready for climate integration."
    )
    try:
        _wait_for_rate_limit_slot()
        resp = _client.models.generate_content(model=GEMINI_MODEL, contents=prompt)
        return resp.text.strip()
    except Exception:
        return _fallback_audit_explanation(audit)

