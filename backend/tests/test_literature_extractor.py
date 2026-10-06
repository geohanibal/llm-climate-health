"""Unit tests for the scientific literature extraction service and endpoint.

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis, University of Bremen)
"""

import io
from pypdf import PdfWriter
from fastapi.testclient import TestClient

from app.main import app
from app.services.literature_extractor import (
    _heuristic_fallback,
    extract_literature_data,
    extract_text_from_pdf_bytes,
)

client = TestClient(app)


def _create_sample_pdf_bytes(title: str, text: str) -> bytes:
    writer = PdfWriter()
    writer.add_blank_page(width=200, height=200)
    writer.add_metadata({
        "/Title": title,
        "/Author": "Dr. Scientist, A.",
    })
    buf = io.BytesIO()
    writer.write(buf)
    return buf.getvalue()


def test_heuristic_fallback_extracts_fields():
    sample_text = (
        "Thermal performance curves of Aedes mosquitoes in 2023\n"
        "Smith, J., Doe, A. and Lee, K.\n"
        "Abstract: This research investigates temperature thresholds for dengue virus transmission.\n"
        "Methods: Laboratory trials conducted between 18C and 34C.\n"
    )
    res = _heuristic_fallback(sample_text)
    assert "Thermal performance" in res.title
    assert "Smith, J." in res.authors
    assert res.year == "2023"
    assert "temperature thresholds" in res.abstract


def test_extract_text_from_pdf_bytes():
    pdf_bytes = _create_sample_pdf_bytes("Test Climate Paper", "Sample Body")
    text, meta = extract_text_from_pdf_bytes(pdf_bytes)
    assert meta.get("title") == "Test Climate Paper"
    assert meta.get("author") == "Dr. Scientist, A."


def test_extract_literature_endpoint_with_text_file():
    content = (
        b"Impact of Precipitation on Malaria Outbreaks (2024)\n"
        b"Authors: Doe, J. et al.\n"
        b"Published in Nature Medicine.\n"
        b"Abstract: High rainfall anomalies strongly correlate with increased Anopheles abundance after a 2-month delay.\n"
    )
    response = client.post(
        "/api/extract-literature",
        files={"file": ("malaria_study.txt", content, "text/plain")},
    )
    assert response.status_code == 200
    data = response.json()
    assert "Impact of Precipitation" in data["title"]
    assert data["year"] == "2024"
    assert len(data["abstract"]) > 10


def test_extract_literature_endpoint_requires_file_or_url():
    response = client.post("/api/extract-literature")
    assert response.status_code == 400
