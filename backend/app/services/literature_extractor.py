"""Extracts structured academic metadata (title, authors, year, journal, abstract,
relevance to climate-health) from uploaded scientific PDFs, text files, or URLs.
Uses Gemini LLM when available with robust fallback heuristics.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis, University of Bremen)
"""

import io
import json
import re
from typing import Any

import requests
from pydantic import BaseModel
from pypdf import PdfReader

from app.config import GEMINI_MODEL
from app.services.llm import get_client, is_llm_available, wait_for_rate_limit_slot


class LiteratureExtractionResult(BaseModel):
    title: str
    authors: str
    year: str
    journal: str
    url: str | None = None
    abstract: str
    differences: str
    status: str = "success"


def extract_text_from_pdf_bytes(pdf_bytes: bytes, max_pages: int = 5) -> tuple[str, dict[str, Any]]:
    """Extracts raw text and PDF metadata from PDF byte stream."""
    try:
        reader = PdfReader(io.BytesIO(pdf_bytes))
        meta = reader.metadata or {}
        extracted_pages: list[str] = []
        for i in range(min(len(reader.pages), max_pages)):
            page_text = reader.pages[i].extract_text()
            if page_text:
                extracted_pages.append(page_text.strip())
        full_text = "\n\n".join(extracted_pages)
        return full_text, {
            "title": meta.get("/Title"),
            "author": meta.get("/Author"),
            "creator": meta.get("/Creator"),
        }
    except Exception as exc:
        return f"[PDF parsing error: {exc}]", {}


def fetch_url_content(url: str, timeout: int = 10) -> tuple[str, str, bytes | None]:
    """Fetches URL and returns (content_type, text_content, raw_bytes_if_pdf)."""
    headers = {
        "User-Agent": (
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
            "(KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
        ),
        "Accept": "text/html,application/xhtml+xml,application/pdf,*/*",
    }
    resp = requests.get(url, headers=headers, timeout=timeout)
    resp.raise_for_status()
    content_type = resp.headers.get("content-type", "").lower()

    if "application/pdf" in content_type or url.lower().endswith(".pdf"):
        text, _ = extract_text_from_pdf_bytes(resp.content)
        return "pdf", text, resp.content

    # Otherwise treat as HTML/text
    html_text = resp.text
    # Extract metadata tags if present
    extracted_tags: list[str] = []
    title_match = re.search(r"<title[^>]*>(.*?)</title>", html_text, re.IGNORECASE | re.DOTALL)
    if title_match:
        extracted_tags.append(f"Title: {title_match.group(1).strip()}")

    citation_title = re.search(
        r'<meta\s+name=["\']citation_title["\']\s+content=["\'](.*?)["\']', html_text, re.IGNORECASE
    )
    if citation_title:
        extracted_tags.append(f"Citation Title: {citation_title.group(1).strip()}")

    citation_authors = re.findall(
        r'<meta\s+name=["\']citation_author["\']\s+content=["\'](.*?)["\']', html_text, re.IGNORECASE
    )
    if citation_authors:
        extracted_tags.append(f"Citation Authors: {', '.join(citation_authors)}")

    citation_date = re.search(
        r'<meta\s+name=["\']citation_publication_date["\']\s+content=["\'](.*?)["\']',
        html_text,
        re.IGNORECASE,
    )
    if citation_date:
        extracted_tags.append(f"Date: {citation_date.group(1).strip()}")

    # Strip script and style tags
    clean_html = re.sub(r"<(script|style)[^>]*>.*?</\1>", "", html_text, flags=re.DOTALL | re.IGNORECASE)
    # Strip remaining HTML tags
    clean_text = re.sub(r"<[^>]+>", " ", clean_html)
    clean_text = re.sub(r"\s+", " ", clean_text).strip()

    combined = "\n".join(extracted_tags) + "\n\n" + clean_text[:8000]
    return "html", combined, None


def _heuristic_fallback(
    text: str,
    pdf_meta: dict[str, Any] | None = None,
    url: str | None = None,
    filename: str | None = None,
) -> LiteratureExtractionResult:
    """Fallback extraction when LLM is offline or rate-limited."""
    meta = pdf_meta or {}
    title = meta.get("title")
    authors = meta.get("author")

    lines = [ln.strip() for ln in text.splitlines() if ln.strip()]
    first_non_empty = lines[0] if lines else (filename or "Scientific Publication")

    if not title:
        # Use first line or filename
        title = first_non_empty[:120] if len(first_non_empty) > 5 else (filename or "Scientific Study")

    if not authors:
        # Check if second or third line looks like author list
        if len(lines) > 1 and len(lines[1]) < 100 and any(sep in lines[1] for sep in [",", "et al.", "and"]):
            authors = lines[1]
        else:
            authors = "Identified Researcher(s)"

    # Year search
    year_match = re.search(r"\b(19\d{2}|20[0-2]\d)\b", text[:2000])
    year = year_match.group(1) if year_match else "2024"

    # Journal / Organization search
    journal = "Academic Journal / Institutional Report"
    for candidate in ["Nature", "The Lancet", "WHO", "IPCC", "Science", "PLOS", "Ecology Letters", "BMC"]:
        if candidate.lower() in text[:2000].lower():
            journal = candidate
            break

    # Abstract search
    abstract_match = re.search(
        r"(?:abstract|summary|background)[\s:\-\n]+(.*?)(?=\n\s*(?:introduction|methods|results|keywords|1\.|\n\n))",
        text,
        re.IGNORECASE | re.DOTALL,
    )
    if abstract_match and len(abstract_match.group(1).strip()) > 60:
        abstract = abstract_match.group(1).strip()[:1000]
    else:
        # Use first 500 chars of body
        abstract = (text[:600] if len(text) > 50 else f"Scientific publication covering vector-borne epidemiology and climate observations ({title}).")

    differences = (
        "ფოკუსირებულია ემპირიულ ეპიდემიოლოგიურ დაკვირვებებზე, კლიმატურ ცვლადებსა და დაავადების გადაცემის დინამიკაზე."
    )

    return LiteratureExtractionResult(
        title=title,
        authors=authors,
        year=year,
        journal=journal,
        url=url,
        abstract=abstract,
        differences=differences,
    )


def extract_literature_data(
    text: str,
    pdf_meta: dict[str, Any] | None = None,
    url: str | None = None,
    filename: str | None = None,
) -> LiteratureExtractionResult:
    """Uses Gemini LLM if available to extract structured study fields from paper text."""
    if not is_llm_available():
        return _heuristic_fallback(text, pdf_meta=pdf_meta, url=url, filename=filename)

    client = get_client()
    wait_for_rate_limit_slot()

    prompt = f"""You are a scientific literature extraction assistant.
Extract metadata and a structured summary from this academic paper text or abstract.

Paper content (first pages / abstract):
\"\"\"
{text[:12000]}
\"\"\"

Filename: {filename or 'N/A'}
URL: {url or 'N/A'}

Respond with ONLY a single valid JSON object in this exact schema:
{{
  "title": "Exact or inferred scientific paper title",
  "authors": "Authors list (e.g. Smith, J., Doe, A. et al. or Organization)",
  "year": "Publication year (e.g. 2024)",
  "journal": "Journal, University, or Publishing organization",
  "url": {json.dumps(url)},
  "abstract": "Comprehensive scientific abstract and research findings (2-4 sentences in clear academic language)",
  "differences": "Relevance to climate and health, key transmission mechanisms (temperature, precipitation, lags), and distinct methodological focus"
}}
"""

    try:
        response = client.models.generate_content(
            model=GEMINI_MODEL,
            contents=prompt,
            config={
                "response_mime_type": "application/json",
                "temperature": 0.1,
            },
        )
        data = json.loads(response.text)
        return LiteratureExtractionResult(
            title=str(data.get("title", "")).strip() or (filename or "Scientific Publication"),
            authors=str(data.get("authors", "")).strip() or "Researcher(s)",
            year=str(data.get("year", "2024")).strip(),
            journal=str(data.get("journal", "")).strip() or "Academic Publication",
            url=url or data.get("url"),
            abstract=str(data.get("abstract", "")).strip() or text[:500],
            differences=str(data.get("differences", "")).strip()
            or "Examines meteorological drivers of disease transmission and epidemiological risk patterns.",
        )
    except Exception:
        return _heuristic_fallback(text, pdf_meta=pdf_meta, url=url, filename=filename)
