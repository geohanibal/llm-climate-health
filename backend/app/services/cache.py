"""In-memory cache for integration results.

Avoids re-hitting the upstream climate/case-data APIs (and the rate-limited
Gemini API) when the same request is repeated, and lets the response report
a ``last_verified`` timestamp for the data it returns, per FR: the system
should surface pre-processed/cached data together with the time it was last
verified against its sources.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

import time
from datetime import datetime, timezone
from threading import Lock

_TTL_SECONDS = 15 * 60
_store: dict[tuple, tuple[float, dict]] = {}
_lock = Lock()


def make_key(**fields) -> tuple:
    return tuple(sorted(fields.items()))


def get(key: tuple):
    with _lock:
        entry = _store.get(key)
        if entry is None:
            return None
        cached_at, payload = entry
        if time.monotonic() - cached_at > _TTL_SECONDS:
            del _store[key]
            return None
        return payload


def set(key: tuple, payload: dict) -> None:
    with _lock:
        _store[key] = (time.monotonic(), payload)


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")
