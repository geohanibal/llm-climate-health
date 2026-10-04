"""Chat service for the Climate-Health Copilot assistant.

Provides a domain-aware, multilingual conversational AI assistant that understands
the thesis platform's data, ETL pipeline, statistical analysis, and current UI state.
Supports Google Gemini cloud models and local Ollama instances (e.g. llama3.2).

Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
"""

import json
import os
import re
from datetime import date
from typing import Any

import requests

from app.config import (
    AGGREGATIONS,
    CLIMATE_SOURCES,
    DISEASE_REGION_COVERAGE,
    DISEASES,
    DISEASES_WITH_DATA,
    GEMINI_MODEL,
    REGIONS,
)
from app.models import (
    ChatContext,
    ChatMessage,
    ChatRequest,
    ChatResponse,
    FormPrefillAction,
)
from app.services.llm import get_client, wait_for_rate_limit_slot


def _detect_language_fallback(text: str) -> str:
    """Heuristic for fallback messages when LLMs are unavailable."""
    if re.search(r"[\u10A0-\u10FF]", text):
        return "ka"
    german_indicators = ["hallo", "wie", "was", "daten", "klima", "dengue", "warum", "deutsch", "bitte"]
    text_lower = text.lower()
    if any(re.search(rf"\b{word}\b", text_lower) for word in german_indicators):
        return "de"
    return "en"


def _generate_fallback_response(
    user_text: str, context: ChatContext | None, error_detail: str | None = None
) -> ChatResponse:
    lang = _detect_language_fallback(user_text)
    has_result = context is not None and context.active_result is not None

    quota_issue = error_detail and ("402" in error_detail or "RESOURCE_EXHAUSTED" in error_detail or "credits are depleted" in error_detail)

    if lang == "ka":
        if quota_issue:
            status_note = (
                "\n\n---\n"
                "⚠️ **Gemini API-ს კვოტა ამოწურულია (Error 402: Credits Depleted).**\n"
                "ცოცხალი, ულიმიტო პასუხებისთვის გაქვთ 2 მარტივი გზა:\n"
                "1. **უფასო Gemini გასაღები:** აიღეთ უფასო API გასაღები [Google AI Studio](https://aistudio.google.com/apikey)-დან და ჩაწერეთ `backend/.env`-ში;\n"
                "2. **ლოკალური ხელსაწყო (Ollama):** დააყენეთ Ollama თქვენს კომპიუტერზე (`ollama run llama3.2`) და ბექენდი მას ავტომატურად დაუკავშირდება ლოკალურად!"
            )
        else:
            status_note = "\n\n*(შენიშვნა: AI სერვისი ამჟამად მუშაობს ოფლაინ რეჟიმში. მონაცემები ამოღებულია პირდაპირ ეკრანის შედეგებიდან.)*"

        if has_result and context and context.active_result:
            r = context.active_result
            reply = (
                f"**მიმდინარე მონაცემების შეჯამება ({r.disease} - {r.region}):**\n\n"
                f"- **სულ დაფიქსირებული შემთხვევები:** {int(r.total_cases) if r.total_cases else 'N/A'}\n"
                f"- **პიკური პერიოდი:** {r.peak_period} ({int(r.peak_cases) if r.peak_cases else 'N/A'} შემთხვევა)\n"
                f"- **საშუალო ტემპერატურა:** {r.mean_temperature_c or 'N/A'} °C\n"
                f"- **საშუალო ნალექი:** {r.mean_precipitation_mm or 'N/A'} მმ\n"
                f"{status_note}"
            )
            prompts = ["როგორ მუშაობს Lagged კორელაცია?", "რა მონაცემთა წყაროებია ხელმისაწვდომი?"]
        else:
            reply = (
                "მოგესალმებით! მე ვარ **Climate-Health Copilot**, კლიმატისა და ჯანდაცვის მონაცემთა ინტეგრაციის პლატფორმის AI ასისტენტი.\n\n"
                "მე შემიძლია დაგეხმაროთ:\n"
                "- დაავადებებისა (დენგე, მალარია, ქოლერა) და რეგიონების არჩევაში;\n"
                "- ERA5 კლიმატური მონაცემების (ტემპერატურა, ნალექი) განმარტებაში;\n"
                "- დროითი დაგვიანების (Lagged cross-correlation) ბიოლოგიური მნიშვნელობის გაგებაში;\n"
                "- ფორმის ავტომატურ შევსებაში.\n"
                f"{status_note}"
            )
            prompts = [
                "რა მონაცემებია ხელმისაწვდომი ტაილანდზე?",
                "რას ნიშნავს ERA5 reanalysis?",
                "დამიყენე ფორმა დენგეზე ტაილანდში (2018-2022)",
            ]
    elif lang == "de":
        if quota_issue:
            status_note = (
                "\n\n---\n"
                "⚠️ **Hinweis: Das Gemini-API-Guthaben ist erschöpft (Fehler 402: Credits Depleted).**\n"
                "Optionen für unbegrenzte KI-Antworten:\n"
                "1. **Kostenloser Gemini-Schlüssel:** Erstellen Sie einen Schlüssel unter [Google AI Studio](https://aistudio.google.com/apikey) und tragen Sie ihn in `backend/.env` ein.\n"
                "2. **Lokales LLM (Ollama):** Starten Sie Ollama auf diesem Rechner (`ollama run llama3.2`), die Plattform verbindet sich automatisch lokal!"
            )
        else:
            status_note = "\n\n*(Hinweis: Der AI-Dienst läuft im Offline-Modus.)*"

        if has_result and context and context.active_result:
            r = context.active_result
            reply = (
                f"**Zusammenfassung der aktuellen Ergebnisse ({r.disease} - {r.region}):**\n\n"
                f"- **Gesamtfälle:** {int(r.total_cases) if r.total_cases else 'N/A'}\n"
                f"- **Höchststand:** {r.peak_period} ({int(r.peak_cases) if r.peak_cases else 'N/A'} Fälle)\n"
                f"- **Durchschnittstemperatur:** {r.mean_temperature_c or 'N/A'} °C\n"
                f"- **Durchschnittsniederschlag:** {r.mean_precipitation_mm or 'N/A'} mm\n"
                f"{status_note}"
            )
            prompts = ["Was bedeutet zeitverzögerte Korrelation (Lag)?", "Welche Datenquellen werden genutzt?"]
        else:
            reply = (
                "Willkommen beim **Climate-Health Copilot**, dem intelligenten Assistenten für die "
                "Klima- und Gesundheitsdaten-Integrationsplattform (Bachelorarbeit Sergi Koniashvili, Universität Bremen).\n\n"
                "Ich kann Ihnen helfen bei:\n"
                "- Auswahl von Krankheiten (Dengue, Malaria, Cholera) und Regionen\n"
                "- Erklärung von ERA5-Reanalysedaten und biologischen Zusammenhängen (z. B. Überträgerzyklen)\n"
                "- Interpretation von Kreuzkorrelationen mit Zeitverzögerung (Lags 0–3)\n"
                "- Automatisches Ausfüllen des Abfrageformulars.\n"
                f"{status_note}"
            )
            prompts = [
                "Welche Daten gibt es für Thailand?",
                "Was ist ERA5-Reanalyse?",
                "Formular für Dengue in Thailand (2018-2022) vorbereiten",
            ]
    else:
        if quota_issue:
            status_note = (
                "\n\n---\n"
                "⚠️ **Note: The configured Gemini API key quota is depleted (Error 402: Credits Depleted).**\n"
                "To get live, generated responses you have two easy options:\n"
                "1. **Free Gemini Key:** Generate a free API key at [Google AI Studio](https://aistudio.google.com/apikey) and put it in `backend/.env` as `GEMINI_API_KEY=...`;\n"
                "2. **Local AI Engine (Ollama):** Install and run Ollama on your computer (`ollama run llama3.2`). The backend will automatically detect and connect to it locally with zero cost and no rate limits!"
            )
        else:
            status_note = "\n\n*(Note: Running in offline fallback mode with current data from your active screen.)*"

        if has_result and context and context.active_result:
            r = context.active_result
            reply = (
                f"**Summary of Active Results ({r.disease} - {r.region}):**\n\n"
                f"- **Total Cases:** {int(r.total_cases) if r.total_cases else 'N/A'}\n"
                f"- **Peak Outbreak:** {r.peak_period} ({int(r.peak_cases) if r.peak_cases else 'N/A'} cases)\n"
                f"- **Mean Temperature:** {r.mean_temperature_c or 'N/A'} °C\n"
                f"- **Mean Precipitation:** {r.mean_precipitation_mm or 'N/A'} mm\n"
                f"{status_note}"
            )
            prompts = ["How does lagged correlation work?", "What climate data sources are used?"]
        else:
            reply = (
                "Hello! I am the **Climate-Health Copilot**, your AI research assistant for the "
                "Climate-Health Data Integration Platform (Sergi Koniashvili's bachelor thesis, University of Bremen).\n\n"
                "I can help you with:\n"
                "- Selecting diseases (Dengue, Malaria, Cholera) and regions with verified data coverage;\n"
                "- Understanding ERA5 climate reanalysis vs raw station readings;\n"
                "- Interpreting lagged cross-correlations and vector breeding biology;\n"
                "- Automatically populating the query form for you.\n"
                f"{status_note}"
            )
            prompts = [
                "What data is available for Thailand?",
                "Explain ERA5 reanalysis",
                "Set form for Dengue in Thailand (2018-2022)",
            ]

    return ChatResponse(reply=reply, suggested_action=None, suggested_prompts=prompts)


def _build_system_instruction() -> str:
    disease_info = []
    for k, v in DISEASES.items():
        regions = sorted(DISEASES_WITH_DATA.get(k, []))
        reg_str = ", ".join(regions) if regions else "Global / Custom"
        disease_info.append(f"- {k.upper()} ({v.label}): native resolution={v.native_resolution}, citation={v.citation}. Regions with verified built-in data: {reg_str}")

    return f"""You are the Climate-Health AI Copilot, an expert scientific assistant for the LLM-driven Climate-Health Data Integration Platform (Sergi Koniashvili's bachelor thesis in Informatics, University of Bremen).

### CRITICAL LANGUAGE RULE:
Always detect the language of the user's latest query (e.g., English, Georgian, German, etc.) and respond in the EXACT SAME LANGUAGE with natural, grammatically correct phrasing.
- If the user writes in English, reply in English.
- If the user writes in Georgian (ქართული), your entire response must be in fluent Georgian.
- If the user writes in German (Deutsch), your entire response must be in fluent academic German.
Keep technical/scientific abbreviations intact (e.g. ERA5, ECMWF, WHO GHO, HDX, OpenDengue, Pearson r, p-value, incidence per 100,000).

### PLATFORM DOMAIN KNOWLEDGE:
1. Nature of the Platform:
   - This platform is an ETL and data harmonization system. It joins disease surveillance data with climate reanalysis (temperature, precipitation) and demographic data (World Bank/UN WPP).
   - "Descriptive, not predictive": It outputs analysis-ready data for downstream modeling. It is NOT a disease prediction tool and does NOT claim causal proof. Causal inference requires subnational spatial microdata and confounder control.

2. Supported Diseases & Built-in Coverage:
{chr(10).join(disease_info)}

3. Climate Sources:
   - Open-Meteo ERA5 (ECMWF ERA5 reanalysis archive, global coverage).
   - NASA POWER (global solar/meteorological archive).
   - TMD (Thai Meteorological Department, Thailand only).
   - Key concept: Reanalysis is a physically consistent numerical model reconstruction combining physics equations with past observations across a grid, NOT raw isolated gauge readings.

4. Biological Vector Mechanisms & Lagged Cross-Correlations:
   - Vector-borne diseases (Aedes mosquitoes for Dengue, Anopheles for Malaria) depend on temperature and precipitation for larval development and viral replication (extrinsic incubation period).
   - Because life cycles take several weeks (egg -> larva -> adult -> biting -> incubation period in humans), climate conditions show a delayed (lagged) correlation with outbreaks.
   - The platform calculates cross-correlations at Lags 0, 1, 2, and 3 months/periods (Pearson r and Spearman rho with p-values).

5. Interactive Form Actions ("Fill, never run"):
   - If the user requests to configure or examine a specific disease/region query (e.g. "Set up Dengue in Thailand 2018 to 2022" or "დამიყენე მალარია კენიაში 2016-2020"), you can provide a `suggested_action` JSON object.
   - The user will see a button in the UI to apply these parameters to the form with one click.
   - Allowed diseases: {list(DISEASES.keys())}
   - Valid regions: {list(REGIONS.keys())}
   - Valid climate sources: {list(CLIMATE_SOURCES.keys())}
   - Valid aggregations: {AGGREGATIONS}

### RESPONSE JSON FORMAT:
You MUST respond with a single valid JSON object containing:
{{
  "reply": "Your helpful, formatted markdown response in the user's language.",
  "suggested_action": {{
    "disease": "dengue",
    "region": "Thailand",
    "variables": ["temperature", "precipitation"],
    "start_date": "2018-01-01",
    "end_date": "2022-12-01",
    "aggregation": "native",
    "climate_source": "open-meteo-era5"
  }} or null,
  "suggested_prompts": [
    "Follow-up question 1 in user's language",
    "Follow-up question 2 in user's language"
  ]
}}
"""


def _sanitize_action(raw_action: Any) -> FormPrefillAction | None:
    if not isinstance(raw_action, dict):
        return None

    disease = raw_action.get("disease")
    if disease and disease not in DISEASES:
        disease = None

    region = raw_action.get("region")
    if region and region not in REGIONS:
        region = None

    variables = raw_action.get("variables")
    if isinstance(variables, list):
        valid_vars = [v for v in variables if v in ("temperature", "precipitation")]
        variables = valid_vars if valid_vars else None
    else:
        variables = None

    start_date = raw_action.get("start_date")
    end_date = raw_action.get("end_date")

    aggregation = raw_action.get("aggregation")
    if aggregation not in AGGREGATIONS:
        aggregation = None

    climate_source = raw_action.get("climate_source")
    if climate_source not in CLIMATE_SOURCES:
        climate_source = None

    if not any([disease, region, variables, start_date, end_date, aggregation, climate_source]):
        return None

    return FormPrefillAction(
        disease=disease,
        region=region,
        variables=variables,
        start_date=start_date,
        end_date=end_date,
        aggregation=aggregation,
        climate_source=climate_source,
    )


def _call_ollama(full_prompt: str) -> dict | None:
    """Attempts to call a local Ollama instance if available at localhost:11434."""
    ollama_host = os.environ.get("OLLAMA_HOST", "http://127.0.0.1:11434")
    ollama_model = os.environ.get("OLLAMA_MODEL", "llama3.2")
    try:
        resp = requests.post(
            f"{ollama_host}/api/generate",
            json={
                "model": ollama_model,
                "prompt": full_prompt,
                "stream": False,
                "format": "json",
            },
            timeout=25,
        )
        if resp.status_code == 200:
            raw = resp.json().get("response", "")
            return json.loads(raw)
    except Exception:
        pass
    return None


def process_chat(req: ChatRequest) -> ChatResponse:
    """Processes a user chat message with context awareness, Gemini LLM,
    and automatic Ollama fallback support."""
    client = get_client()
    latest_user_message = next(
        (m.content for m in reversed(req.messages) if m.role == "user"), ""
    )

    # Format context for prompt
    context_str = "CURRENT APPLICATION STATE / CONTEXT:\n"
    if req.context:
        ctx = req.context
        if ctx.current_disease or ctx.current_region:
            context_str += f"- Selected in Form: Disease={ctx.current_disease}, Region={ctx.current_region}, Dates={ctx.current_start_date} to {ctx.current_end_date}\n"
        if ctx.active_result:
            ar = ctx.active_result
            context_str += (
                f"- Active Loaded Result on Screen:\n"
                f"  * Disease: {ar.disease}, Region: {ar.region}, Resolution: {ar.resolution}\n"
                f"  * Total reported cases: {ar.total_cases}\n"
                f"  * Peak outbreak period: {ar.peak_period} (Cases: {ar.peak_cases}, Incidence/100k: {ar.peak_incidence_per_100k})\n"
                f"  * Mean climate: Temp={ar.mean_temperature_c} °C, Precip={ar.mean_precipitation_mm} mm\n"
                f"  * Statistical correlations: {ar.correlations_summary or 'None'}\n"
                f"  * Active explanation: {ar.explanation or 'None'}\n"
            )
    else:
        context_str += "- No specific query or result currently active.\n"

    # Build conversation history
    history_str = "CONVERSATION HISTORY:\n"
    for msg in req.messages[-6:]:  # last 6 messages for context window efficiency
        role = "User" if msg.role == "user" else "Copilot"
        history_str += f"{role}: {msg.content}\n\n"

    full_prompt = (
        f"{_build_system_instruction()}\n\n"
        f"{context_str}\n\n"
        f"{history_str}\n"
        f"Respond to the latest user message. Remember to reply in the EXACT SAME LANGUAGE as the user."
    )

    gemini_error = None

    # 1. Try Gemini cloud if client is configured
    if client is not None:
        try:
            wait_for_rate_limit_slot()
            resp = client.models.generate_content(
                model=GEMINI_MODEL,
                contents=full_prompt,
                config={"response_mime_type": "application/json"},
            )
            data = json.loads(resp.text)
            reply = str(data.get("reply", "")).strip()
            if reply:
                raw_action = data.get("suggested_action")
                action = _sanitize_action(raw_action)
                raw_prompts = data.get("suggested_prompts", [])
                prompts = [str(p).strip() for p in raw_prompts if isinstance(p, (str, int))]
                return ChatResponse(
                    reply=reply,
                    suggested_action=action,
                    suggested_prompts=prompts[:4],
                )
        except Exception as exc:
            gemini_error = str(exc)

    # 2. Try local Ollama if available
    ollama_data = _call_ollama(full_prompt)
    if ollama_data and isinstance(ollama_data, dict):
        reply = str(ollama_data.get("reply", "")).strip()
        if reply:
            raw_action = ollama_data.get("suggested_action")
            action = _sanitize_action(raw_action)
            raw_prompts = ollama_data.get("suggested_prompts", [])
            prompts = [str(p).strip() for p in raw_prompts if isinstance(p, (str, int))]
            return ChatResponse(
                reply=reply,
                suggested_action=action,
                suggested_prompts=prompts[:4],
            )

    # 3. Fallback with honest error disclosure
    return _generate_fallback_response(latest_user_message, req.context, error_detail=gemini_error)
