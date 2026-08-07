"""Gemini-backed plain-language explanation of the ETL pipeline.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

import time
from collections import deque
from threading import Lock

from app.config import GEMINI_API_KEY, GEMINI_MODEL
from app.models import PeriodRecord

_client = None
if GEMINI_API_KEY:
    from google import genai

    _client = genai.Client(api_key=GEMINI_API_KEY)

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
    with _rate_limit_lock:
        now = time.monotonic()
        while _call_timestamps and now - _call_timestamps[0] > 60:
            _call_timestamps.popleft()
        if len(_call_timestamps) >= _MAX_CALLS_PER_MINUTE:
            sleep_for = 60 - (now - _call_timestamps[0])
            if sleep_for > 0:
                time.sleep(sleep_for)
        _call_timestamps.append(time.monotonic())


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
        "raw station reading), and make clear this is descriptive "
        "integrated data, not a disease prediction.\n\n"
        f"Disease: {disease}\nRegion: {region}\n\n"
        "Pipeline steps performed:\n"
        + "\n".join(f"- {s}" for s in steps)
        + "\n\nSample of joined data (each row is one time period):\n"
        + sample_text
    )


def explain_pipeline(
    disease: str, region: str, steps: list[str], records: list[PeriodRecord]
) -> str:
    if _client is None:
        return FALLBACK_EXPLANATION

    prompt = build_prompt(disease, region, steps, records)

    try:
        _wait_for_rate_limit_slot()
        resp = _client.models.generate_content(model=GEMINI_MODEL, contents=prompt)
        return resp.text.strip()
    except Exception:
        return FALLBACK_EXPLANATION
