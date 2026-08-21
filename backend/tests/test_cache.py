"""Unit tests for app.services.cache.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

from app.services import cache


def test_make_key_is_order_independent():
    assert cache.make_key(b=2, a=1) == cache.make_key(a=1, b=2)


def test_set_then_get_returns_the_stored_payload():
    key = cache.make_key(disease="dengue")
    cache.set(key, {"value": 1})
    assert cache.get(key) == {"value": 1}


def test_get_returns_none_for_missing_key():
    assert cache.get(cache.make_key(disease="nope")) is None


def test_get_expires_entries_past_the_ttl(monkeypatch):
    key = cache.make_key(disease="dengue")
    cache.set(key, {"value": 1})

    real_monotonic = cache.time.monotonic()
    monkeypatch.setattr(cache.time, "monotonic", lambda: real_monotonic + cache._TTL_SECONDS + 1)
    assert cache.get(key) is None


def test_now_iso_returns_a_parseable_utc_timestamp():
    from datetime import datetime

    parsed = datetime.fromisoformat(cache.now_iso())
    assert parsed.tzinfo is not None
