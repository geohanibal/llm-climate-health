"""Humanitarian Data Exchange (HDX, data.humdata.org) search client.

HDX is UN OCHA's catalog of datasets shared by governments, WHO, national
ministries of health, and other official/humanitarian organizations. Unlike
WHO GHO (structured indicators), HDX hosts ready-to-download files, so a
dataset found here can be used directly as a `custom_url` case-data source —
no new ingestion path needed, it reuses the existing, tested CSV pipeline in
`services/case_data.py`.

Only datasets with at least one CSV/XLSX resource are returned, since those
are the only formats `get_case_data_from_url` can parse.

API docs: https://data.humdata.org/dev

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

import requests

_SEARCH_URL = "https://data.humdata.org/api/3/action/package_search"
_TABULAR_FORMATS = {"CSV", "XLSX", "XLS"}


def search_case_datasets(keyword: str, limit: int = 8) -> list[dict]:
    """Searches HDX for datasets matching `keyword`. Returns only real
    metadata HDX itself reports — title, organization, and the first
    tabular (CSV/XLSX) resource's direct download URL, if any."""
    params = {"q": keyword, "rows": limit}
    resp = requests.get(_SEARCH_URL, params=params, timeout=15)
    resp.raise_for_status()
    payload = resp.json()
    if not payload.get("success"):
        return []

    results = []
    for pkg in payload["result"]["results"]:
        resource_url = next(
            (
                r["url"]
                for r in pkg.get("resources", [])
                if (r.get("format") or "").upper() in _TABULAR_FORMATS and r.get("url")
            ),
            None,
        )
        if resource_url is None:
            continue
        title = pkg.get("title", "Untitled dataset")
        notes = (pkg.get("notes") or "").strip()
        combined_text = f"{title} {notes}".lower()

        # Score relevance: prefer datasets describing disease case surveillance
        score = 0
        for kw in ["cases", "surveillance", "monthly", "yearly", "annual", "time series", "outbreak", "epidemic"]:
            if kw in combined_text:
                score += 2
        for kw in ["boundary", "boundaries", "spending", "facility", "facilities", "roads", "shapefile"]:
            if kw in combined_text:
                score -= 3

        results.append(
            {
                "title": title,
                "organization": pkg.get("organization", {}).get("title", "Unknown organization"),
                "notes": notes,
                "dataset_url": f"https://data.humdata.org/dataset/{pkg.get('name', pkg.get('id', ''))}",
                "resource_url": resource_url,
                "score": score,
            }
        )

    results.sort(key=lambda x: x.get("score", 0), reverse=True)
    for r in results:
        r.pop("score", None)
    return results

