"""Combines WHO GHO and HDX search into one ranked list of candidate
case-data sources for a disease, so the frontend can let the user pick
instead of being stuck with one hardcoded built-in source.

Both underlying searches are best-effort and independent: if one API is
down or returns nothing, the other's results still come through. Nothing
here is invented — every field traces back to a real API response.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

import logging

from app.models import DiscoveredSource
from app.services import hdx, who_gho

logger = logging.getLogger(__name__)


def search_case_sources(disease_label: str, region_label: str) -> list[DiscoveredSource]:
    sources: list[DiscoveredSource] = []

    try:
        for indicator in who_gho.search_indicators(disease_label):
            sources.append(
                DiscoveredSource(
                    source_type="who_gho",
                    title=indicator["name"],
                    organization="World Health Organization (WHO)",
                    description=(
                        f"Official WHO Global Health Observatory indicator. Yearly "
                        f"values for {region_label}, fetched live from WHO's API."
                    ),
                    citation=(
                        f"WHO Global Health Observatory, indicator {indicator['code']} "
                        f"— {indicator['name']} (ghoapi.azureedge.net)"
                    ),
                    dataset_url=(
                        f"https://www.who.int/data/gho/data/indicators/indicator-details/"
                        f"GHO/{indicator['code'].lower()}"
                    ),
                    indicator_code=indicator["code"],
                )
            )
    except Exception:
        logger.warning("WHO GHO indicator search failed for %r", disease_label, exc_info=True)

    try:
        for ds in hdx.search_case_datasets(f"{disease_label} {region_label}") or hdx.search_case_datasets(
            disease_label
        ):
            sources.append(
                DiscoveredSource(
                    source_type="hdx",
                    title=ds["title"],
                    organization=ds["organization"],
                    description=ds["notes"][:280] if ds["notes"] else "No description provided.",
                    citation=f"{ds['organization']}, \"{ds['title']}\" via HDX (data.humdata.org)",
                    dataset_url=ds["dataset_url"],
                    resource_url=ds["resource_url"],
                )
            )
    except Exception:
        logger.warning("HDX dataset search failed for %r", disease_label, exc_info=True)

    return sources
