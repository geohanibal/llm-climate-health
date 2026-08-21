"""Shared pytest fixtures.

`cache._store`, `llm._call_timestamps`, and `case_data._load_builtin`'s
lru_cache are all process-global singletons — without resetting them, one
test's cache hit / rate-limiter state / stale file read can leak into an
unrelated test. Reset before and after every test rather than relying on
test ordering.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

import pytest

from app.services import cache as cache_module
from app.services import llm as llm_module
from app.services.case_data import _load_builtin


@pytest.fixture(autouse=True)
def _reset_shared_module_state():
    cache_module._store.clear()
    llm_module._call_timestamps.clear()
    _load_builtin.cache_clear()
    yield
    cache_module._store.clear()
    llm_module._call_timestamps.clear()
    _load_builtin.cache_clear()
