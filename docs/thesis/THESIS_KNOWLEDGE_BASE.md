# Thesis Knowledge Base — LLM-Climate-Health

> **ქართულად:** ეს ფაილი ბაკალავრის ნაშრომის „მეხსიერებაა“. აქ ინახება ყველა
> შემოწმებული ფაქტი, წყარო, ციტატა, გადაწყვეტილება და ღია საკითხი. ტექსტი
> ინგლისურადაა, რომ Gemini-მ და Claude-მ ზუსტად წაიკითხონ და თეზისის (გერმანულ)
> ტექსტში გამოიყენონ. ყოველი ახალი მნიშვნელოვანი რამ აქ დაამატე.

**Purpose:** Single source of truth for writing the bachelor thesis. Any AI
assistant (Gemini, Claude) helping to write the thesis MUST read this file first
and follow the rules in §0.

**Last updated:** 2026-10-31

---

## Current status (start here in a new chat)

*Update this block at the end of every work session.*

- **Phase:** literature-based motivation + requirements derivation (after
  supervisor feedback, §3). Code changes started 2026-10-31: A17 population
  interpolation DONE (by Claude, task D spec); 2026-11-01 task B DONE (Gemini,
  reviewed by Claude): FR-23 lag columns 1–6 + lag buffer (A1, A22); task C DONE
  (FR-24 Tmin/Tmax, A2, backend + minimal frontend); A16 package DONE (FR-25
  provenance export + A14 licences + A15a disclaimer + lag/Tmin/Tmax columns in
  table/CSV/PDF); task E DONE (FR-26 gap detection, Gemini, reviewed); task F DONE
  (FR-27 source comparison, Gemini, reviewed); task F2 DONE (source B:
  WHO GHO yearly / URL / upload). Draft of thesis ch. 1 + 3 (German):
  `docs/thesis/entwurf/`. Next: A13
  (which OpenDengue release built the bundled file).
- **Read + translated (Georgian study PDFs in `docs_ka/motivacia/papers/`):**
  P1 Suttirat 2026 (main case study), P3 OpenDengue 2024, P4 Lowe 2021
  (Brazil; confirms preprocessing steps are typical).
- **Next paper to read:** P2 Colón-González (PARTLY) or a malaria/cholera
  paper for Case Study 2 (see Gemini task A2) — ask Sergi.
- **Open P0 items:** see `docs/thesis/RECOMMENDATIONS.md` (A1–A3, A13, A14,
  A16; B1–B4) and §9 below.
- **Gemini:** tasks in `docs_ka/motivacia/gemini_tasks_02.md` (A literature,
  B lag columns, C Tmin/Tmax, D population interpolation) and
  `docs_ka/motivacia/gemini_tasks_03.md` (E gap detection = A18, F source
  comparison = A19) — results to be reviewed by Claude. Every code change must
  also update the documents listed in `docs/thesis/CHANGE_DOCUMENTATION_GUIDE.md`. Sergi's own code task: A16 provenance in export
  (`docs_ka/motivacia/A16_gegma.md`).
- **Supervisor meetings:** questions + answers in `docs/thesis/supervisor_meetings/` (one file per meeting). Next meeting: **Mon 2026-11-02** (motivation, requirements, case studies). After the meeting, transfer decisions to §10.
- **Working style:** user (Sergi) wants explanations in Georgian, to be taught
  (not just handed results), and every important finding recorded here.

## 0. Rules for AI assistants (read first)

1. **Only use facts marked VERIFIED in this file** for claims about publications.
   Anything else must be marked `[UNVERIFIED]` or `[CITE: ...]` in drafts.
2. **Never invent** publications, quotes, numbers, page numbers, or author
   statements. If unsure, write `[TODO: verify]`.
3. **Never attribute an opinion to authors that they did not write.** See §6
   (known false claims) — these were produced by an AI earlier and are WRONG.
4. Thesis language is **German** (academic register, Bachelorarbeit Informatik,
   University of Bremen). Quotes from English sources stay in English (see §8).
5. Do not overclaim system capabilities. Use the capability table in §5;
   the system's real behaviour is defined by the code in `backend/app/`.
6. Do not modify this file's VERIFIED entries without re-checking the source.

---

## 1. Project in one paragraph

An LLM-driven ETL platform for climate-health data integration (practical part
of the thesis). A researcher describes the dataset they need (disease, region,
time span, climate variables) in a form or in natural language; Gemini turns
the text into a structured request. The system selects suitable data sources
(disease case counts, ERA5 via Open-Meteo or NASA POWER climate, population
data), cleans, temporally aggregates and joins them into one analysis-ready
table, computes incidence per 100,000 and lagged correlations, documents every
step (provenance / audit trail) and explains it in plain language. Alternative
sources can be requested and own CSV data uploaded. **It is not a prediction
model** — it prepares input data for downstream data-based models.
Validation case: dengue in Thailand (OpenDengue + ERA5).
Stack: FastAPI + pandas backend, Flutter web frontend, single Docker image.

### 1.1 Core statement (Kernaussage)

> Das System nimmt Forschenden die der Modellierung vorgelagerte
> Datenvorbereitung ab (Quellensuche, Bereinigung, Harmonisierung,
> Zusammenführung, Dokumentation) – ohne Programmierkenntnisse und
> nachvollziehbar –, sodass sie sich auf das eigentliche Modell konzentrieren
> können.

Value is NOT only "saves searching on websites": it covers find → download →
clean → harmonise resolution → join → derive (incidence, lags) → document.
Plus: no programming needed (P1 used pandas/R scripts) and transparency /
reproducibility (P1 omits e.g. its spatial averaging method; the system logs
every step). "Saves time" must be MEASURED in case studies before claiming it;
until then write "reduziert den manuellen Aufwand", not "spart Wochen".

## 2. People

| Role | Name |
|---|---|
| Author | Sergi Koniashvili (Informatics, University of Bremen) |
| Supervisor | Prof. Dr. Peter Haddawy (Bremen Spatial Cognition Center, Uni Bremen; also Mahidol University, Thailand) |
| Supervisor | Dr. Thomas Barkowsky |

Note: Peter Haddawy is a co-author of the main case-study paper (§4, P1).
His listed author contribution there is "Writing – review & editing" only;
data curation was done by Suttirat, Chadsuthi, Aekthong, Su Yin (Mahidol).

## 3. Supervisor feedback and resulting thesis strategy

**Feedback (Barkowsky, mail to Haddawy and "Lin", Oct 2026):** The system does
what it should (describe a dataset → suitable sources selected → integrated
table; alternatives, more data; well documented and interactively explorable).
Missing: a grounded motivation. Next step: look into **sample publications
(data-based modeling)** and use them

1. as **motivation** for the work,
2. to **derive the system's requirements**,
3. as **case studies** to demo the system's capabilities.

**Core weakness to fix:** the original requirements catalogue
(`docs/requirements/anforderungskatalog.tex`, FR-01…FR-22, NFR-01…NFR-09) was
written without derivation from literature. Each requirement should be traced
to a publication (traceability matrix) or justified otherwise (e.g. usability
for non-programmers).

### 3.1 Argument chain for the Motivation chapter

```
(1) Researchers build data-based climate-health models
      e.g. Suttirat et al. 2026 (dengue, Thailand)
(2) Before modelling they must perform many manual data-preparation steps
      evidence: P1 Methods, p. 4–5 (see §4 quotes)
(3) These steps are typical, not specific to one study
      evidence: P4 Lowe et al. 2021 + further papers [TODO]
(4) They require programming (pandas, R), knowledge of data sources, time
      evidence: P1 p. 4–5, 8 ("pandas for data manipulation", R 'dismo');
      P3 OpenDengue quotes on difficulty of finding/standardising data
(5) Existing tools do not cover these steps together
      evidence: Related Work [TODO: verify each tool from its docs]
(6) This system automates steps X of them → researchers focus on modelling
      evidence: capability table §5 + case studies §7
```

### 3.2 Evaluation idea ("P → data → model → system → P")

Take a published study P → extract its data needs → state them as a natural-
language request to the system → obtain the integrated dataset → compare with
P's data (variables, sources, resolution, lags) and count manual steps in P vs.
in the system → optionally rerun a simple analysis (e.g. lagged correlation)
and check whether P's main finding qualitatively holds.

---

## 4. Verified literature

Status legend: **VERIFIED** = existence + DOI checked and the listed facts
were read in the full text. **PARTLY** = existence/DOI checked, details not yet
read in full text.

### P1 — Suttirat et al. 2026 (MAIN CASE STUDY) — VERIFIED

- **Citation:** Suttirat P, Chadsuthi S, Aekthong S, Rocklöv J, Bicout DJ,
  Haddawy P, Su Yin M, Lawpoolsri S, Modchang C. *Machine learning reveals
  temperature as a key predictor of dengue risk across Thailand's provinces:
  A 20-year analysis.* PLoS Negl Trop Dis 20(7): e0014590, published
  2026-07-28. DOI: 10.1371/journal.pntd.0014590. License CC BY.
- **Data + code:** https://doi.org/10.5281/zenodo.21053822
- **Local files:** `docs_ka/motivacia/papers/suttirat_2026_plosntd.pdf`
  (original), `docs_ka/motivacia/papers/suttirat_2026_targmani.pdf`
  (Georgian study translation — NOT citable).
- **Facts (from full text):**
  - Monthly dengue hemorrhagic fever (DHF) cases, 77 provinces, 2003–2022,
    Bureau of Epidemiology, Ministry of Public Health Thailand (p. 5).
  - Bueng Kan cases merged into Nong Khai (administrative split 2011) (p. 5).
  - Climate: **TerraClimate** (~4 km grid), NOT ERA5. Six variables:
    precipitation, Tmin, Tmax, soil moisture, vapour pressure, wind speed (p. 5).
  - Gridded data "spatially averaged to the provincial level" — weighting
    method not stated (p. 5).
  - 19 bioclimatic indicators via R package `dismo` (p. 5).
  - Socioeconomic: GPP (NESDC, inflation-adjusted), population + household
    size (BORA), household income (NSO, biennial, linearly interpolated with
    pandas) (p. 5).
  - Annual socioeconomic values assigned to every month of the year (p. 4–5).
  - Remote sensing: MODIS MOD09A1, NDVI and MNDWI as % of provincial pixels (p. 5).
  - 54 features total, of which 24 are lag features (lags 1, 2, 3 months for
    all climate and remote-sensing variables) (Table 1, p. 6–7; p. 7).
  - Outcome: monthly DHF incidence per 100,000 per province, binarised at the
    training-period national median 2.78/100,000 (p. 7).
  - Model: XGBoost + SHAP; train 2003–2016, test 2017–2022 (p. 5–8).
  - Tools: Python 3.10, pandas, numpy, scikit-learn, XGBoost, SHAP (p. 8).
  - Findings: temperature 7 of top-10 features; thresholds ~21 °C (tmin lag 1)
    and ~32 °C (tmax lag 3); precipitation minor; GPP 4th; COVID-19 degraded
    AUC to 0.62 (2021) (p. 9–14).
  - Maps use HDX Thailand subnational boundaries (cod-ab-tha) (Fig. 1, p. 10).
- **Verified quotes:**
  - "Gridded climatic and remote-sensing data were spatially aggregated to the
    provincial level; lagged variables and bioclimatic indices were then
    derived from monthly provincial temperature and precipitation series.
    Socioeconomic data were obtained directly at the provincial level: the
    biennially reported household income series was linearly interpolated to
    fill missing years, and all socioeconomic series were then upsampled to
    monthly resolution by assigning each year's reported value (typically
    released at year-end) to every month of that year." (Methods >
    Methodology workflow, p. 4)
  - "To capture delayed environmental effects on dengue transmission, we
    generated 1-, 2-, and 3-month lagged values for all climate and remote
    sensing variables, expanding our feature set to account for temporal
    dependencies in disease dynamics." (Methods, p. 7)
  - "Most existing models suffer from a limited geographic scope or analyze
    only short time periods [28,30,31]." (Introduction, p. 3)
  - "Future modeling efforts should consider incorporating real-time mobility
    data, healthcare utilization patterns, and other behavioral indicators to
    maintain predictive accuracy during unprecedented circumstances."
    (Discussion, p. 18)
  - "More broadly, our findings suggest that the next generation of dengue
    prediction systems will need to combine environmental signals with
    real-time indicators of mobility, vector populations, and surveillance
    coverage to remain reliable through periods of societal change."
    (Conclusions, p. 19)
  - "All analyses were conducted using Python 3.10 with the following key
    packages: pandas for data manipulation, numpy for numerical operations,
    scikit-learn for preprocessing and evaluation, XGBoost for model
    training, and SHAP for interpretability analysis." (Methods > Machine
    learning approach > Implementation details, p. 8)
  - "we derived 19 bioclimatic indicators from monthly temperature and
    precipitation data using the R package `dismo'" (Methods > Climate
    variables, p. 5)
  - "The household income series, reported biennially by the Thai
    authorities, was linearly interpolated using the pandas interpolate
    method to fill missing years." (Methods > Socioeconomic indicators, p. 5)
- **Argument "programming required" (chain step 4; NFR usability /
  no-code):** P1's data preparation was done with own scripts in Python
  (pandas) and R (`dismo`) — see the three quotes above. The system offers
  the same preparation steps via natural language / form without programming.
  ⚠ Careful wording: the P1 authors are modelers who CAN program; they do not
  say it was hard. The argument is: *this workflow presupposes programming
  skills*, which is a barrier for researchers without them (e.g.
  epidemiologists, public-health staff) — that is the thesis author's
  interpretation, not the paper's claim.
  German draft: „Die Datenaufbereitung erfolgte in eigenen Skripten mit
  Python (pandas) und R (dismo) [P1, S. 5, 8]. Ein solcher Arbeitsablauf
  setzt Programmierkenntnisse voraus, über die nicht alle Forschenden im
  Bereich Public Health verfügen [CITE: TODO — find a source on programming
  skills / data-science skills gap in public health]. Das hier entwickelte System stellt
  vergleichbare Aufbereitungsschritte ohne Programmierung bereit.“
- **Use in thesis:** motivation (manual ETL steps), requirement derivation
  (incidence/100k, lags 1–3, Tmin/Tmax, subnational aggregation), case study 1.

### P2 — Colón-González et al. 2021 — PARTLY

- *Projecting the risk of mosquito-borne diseases in a warmer and more
  populated world: a multi-model, multi-scenario intercomparison modelling
  study.* Lancet Planet Health 2021; 5: e404–14.
  DOI: 10.1016/S2542-5196(21)00132-7.
- Uses climate MODEL PROJECTIONS (4 GCMs, RCP/SSP scenarios), outcome =
  length of transmission season and population at risk (not incidence/100k,
  not ERA5).
- **Use only for general motivation** (climate change expands dengue/malaria
  risk). Not suitable to justify FR-17 or ERA5.

### P3 — Clarke et al. 2024 (OpenDengue) — VERIFIED (full text read 2026-10-31)

- Clarke J, Lim A, Gupte P, Pigott DM, van Panhuis WG, Brady OJ.
  *A global dataset of publicly available dengue case count data.*
  Sci Data 11, 296 (2024). DOI: 10.1038/s41597-024-03120-7. Type: Data Descriptor.
  (Correct title — NOT "OpenDengue: data platform for global dengue
  surveillance and forecasting".)
- **Dataset citation (preferred, cite IN ADDITION to the paper):** Clarke J,
  Lim A, Gupte PR, Pigott DM, van Panhuis WG, Brady O (2023). OpenDengue: data
  from the OpenDengue database. Version [1.2]. figshare. Dataset.
  https://doi.org/10.6084/m9.figshare.24259573
- **Local files:** `docs_ka/motivacia/papers/clarke_2024_opendengue.pdf`,
  `docs_ka/motivacia/papers/clarke_2024_targmani.pdf` (Georgian study
  translation — NOT citable).
- **Facts:** v1.2: >56 million cases, 102 countries, 1924–2023, 843 sources;
  99.8 % of records weekly/monthly; subnational for 40 countries; >95 % from
  ministries of health (p. 1, 8). Three extracts: best national (Admin0),
  maximised temporal, maximised spatial resolution (p. 5, 7). Records are not
  made spatially consistent (Admin2 sum may differ from Admin0) (p. 5). Epi
  weeks converted with R `EpiWeek`, CDC definition: week 1 contains >= 4
  January days, Sunday–Saturday (p. 5). `dengue_total` = all severities and
  confirmation methods (p. 5) — differs from P1, which uses DHF only. Imputed /
  zero-filled records flagged with a UUID suffix (p. 5–6). Manual extraction:
  PDF scraping (pdftools, tabulizer), WebPlotDigitizer for figures, Google
  Translate, hand transcription, column standardisation in R (p. 4). Source
  metadata: access date, URL, navigation steps, search terms (p. 4). v1.1 had
  duplicate counts for the Americas, fixed in v1.2 (p. 8). New versions at
  least every 6 months (p. 12). **Licence: CC BY-SA — all adaptations must be
  shared under the same terms** (p. 12).
  **UPDATE 2026-11-01 (Claude, checked online):** the CURRENT release V1.3
  (figshare 10.6084/m9.figshare.24259573, version 4, 2025-05-27) and
  opendengue.org state **CC BY 4.0**. The paper's CC BY-SA applies to the
  earlier releases it describes. Which release built our bundled file is
  still open (A13); data reach 2025-03, consistent with V1.3. Table 1 (p. 2) compares Tycho, PAHO
  PLISA, ECDC, GIDEON, ProMED (useful for Related Work, health-data side).
- **Verified quotes:**
  - "Tracking the expansion of the burden of dengue is challenging due to the
    difficulties in collecting and aggregating consistent and comparable dengue
    incidence and prevalence data." (Background & Summary, p. 1)
  - "While many countries regularly publish dengue case statistics, they can
    often be difficult to find and no single database aggregates data from
    multiple countries to assess trends at the global level." (p. 1)
  - "Gathering data across all dengue endemic regions would enable re-analysis
    to better understand the drivers of transmission, monitor progress towards
    disease reduction targets, evaluate the impact of public health
    interventions and model the possible future burden and spatial limits
    under different climate scenarios." (p. 1)
  - ProMED "does not have tabular machine readable download options and while
    a very useful resource, requires substantial manual processing." (p. 2)
  - "To date, no repository has been able to combine global coverage, public
    availability, machine readable accessible formats at high spatial-temporal
    resolution and sustained updates over long time periods." (p. 2)
  - "Dengue case data exists in multiple formats from a wide variety of sources
    that require various processing methodologies. Detailed source metadata is
    important to ensure case counts can be traced back to their original
    reporting source, and to enable assessment of comparability between
    sources. Locating, extracting, processing and standardising data all takes
    time but is essential to enable reuse and re-analysis." (p. 2) <- KEY QUOTE
  - "Examples include identifying worst affected areas and years,
    understanding drivers of transmission such as climate factors and
    interventions and predicting future trends and outbreak risk."
    (Usage Notes, p. 9)
  - "Applications that explore changes in dengue dynamics over time including
    time series analysis, forecasting and national programme evaluation should
    use the temporal extract which preferentially selects data records that
    maximise the temporal resolution of the data." (Usage Notes > Choice of
    extract, p. 10)
  - "It is recommended for users to specify which version of OpenDengue they
    use in their analyses and routinely check for updates at relevant points in
    their project lifecycle." (Usage Notes > Dataset version control, p. 12)
- WARNING: these quotes concern the HEALTH-data side. The paper does NOT say
  that users must join climate data themselves. Argument (thesis author's
  interpretation): OpenDengue solves case-data collection; joining with
  climate — named by the authors as a use case — remains the researcher's job;
  the system performs that step.
- **Use in thesis:** motivation (chain steps 2 and 4: "takes time", "manual
  processing"), provenance requirement (FR-18), requirements: correct extract,
  version citation, licence; Related Work (Table 1).

### P4 — Lowe et al. 2021 (Brazil) — VERIFIED (full text read 2026-10-31)

- Lowe R, Lee SA, O'Reilly KM, Brady OJ, Bastos L, Carrasco-Escobar G,
  de Castro Catão R, Colón-González FJ, Barcellos C, Carvalho MS,
  Blangiardo M, Rue H, Gasparrini A. *Combined effects of hydrometeorological
  hazards and urbanisation on dengue risk in Brazil: a spatiotemporal
  modelling study.* Lancet Planet Health 2021; 5(4): e209–e219.
  DOI: **10.1016/S2542-5196(20)30292-8**. Licence CC BY 4.0.
  Data + R code: github.com/drrachellowe/hydromet_dengue, Zenodo
  10.5281/zenodo.4632205.
- **Local files:** `docs_ka/motivacia/papers/lowe_2021_lancetph.pdf`
  (original, from Fiocruz ARCA repository), `lowe_2021_targmani.pdf`
  (Georgian study translation — NOT citable). Page numbers = journal pages e209–e219.
- **Data & preprocessing (Methods, p. e211–e212):**
  1. Monthly notified dengue cases, 558 microregions, 2001-01 … 2019-12, SINAN
     via DATASUS (Ministry of Health). (Summary says "January, 2019" —
     inconsistency in the paper; Methods says December 2019.)
  2. Yearly population estimates (IBGE via DATASUS) → incidence per 100 000 per
     month (Ministry definition). Paper does NOT say how annual population was
     mapped to months — do not claim interpolation.
  3. Climate: CRU TS v4.04, monthly mean daily Tmin, Tmax, self-calibrated
     PDSI, 0.5° grid, 2000-01 … 2019-12 — **one extra year before the first
     case observation "to allow for a lag period"**.
  4. Spatial aggregation with R `exactextractr`: mean of grid cells within each
     microregion, partially covered cells **area-weighted**.
  5. Socioeconomic: % urban + % piped water access (2010 census, static);
     water-supply interruptions (SNIS 2000–2016) = count / (years × municipalities).
  6. Collinearity check with **Pearson r** (urban vs water access r = 0.73 →
     water access dropped).
  7. DLNM lags **0–6 months** for Tmin, Tmax, PDSI; Tmin + PDSI fitted better
     than Tmax (p. e215).
  Model (out of system scope): Bayesian hierarchical negative binomial,
  R-INLA, state-month + microregion-year random effects.
- **Findings:** 12 895 293 cases; risk up 0–3 months after extremely wet
  conditions (max RR 1.56 at lag 1) and 3–5 months after drought (max RR 1.43
  at lag 4); drought effect stronger in highly urbanised areas, wet effect
  stronger in rural areas (Table, p. e216).
- **Limitations (p. e217):** passive surveillance; only 10–30 % lab-confirmed;
  misclassification with Zika/chikungunya since 2016; static 2010 urbanisation.
- **Verified quotes:**
  - "The effect of climate variability and climate change on dengue
    transmission is complex, non-linear, and often delayed by several weeks to
    months, which limits the inferences that can be made from traditional
    linear modelling methods." (Introduction, p. e211)
  - "We obtained monthly notified dengue cases for each of the 558
    microregions of Brazil between January, 2001, and December, 2019, from the
    Notifiable Diseases Information System, which is freely available via the
    Ministry of Health Information Department (DATASUS)." (p. e211)
  - "The monthly mean daily minimum temperature (Tmin; °C), maximum
    temperature (Tmax; °C), and the self-calibrated PDSI were obtained from the
    Climatic Research Unit gridded Time Series (version 4.04), for the period
    January, 2000, to December, 2019, at a spatial resolution of 0·5° longitude
    × 0·5° latitude (data for 2000 were extracted to allow for a lag period
    before the first dengue observation in January, 2001)." (p. e211)
  - "The gridded datasets were aggregated to each microregion using the
    exactextractr package in R (version 4.0.2), by calculating the mean of grid
    boxes lying within each microregion. Grid boxes that were partially covered
    by the microregion were weighted by the percentage that lay within the
    microregion." (p. e211)
  - "DLNMs were used to explore possible non-linear and delayed associations
    between dengue incidence, temperature (Tmin and Tmax), and the PDSI from 0
    to 6 months." (p. e212)
  - "All data used in this study is open access and freely available on the
    internet, see the methods section for details." (Data sharing, p. e218)
  - "SAL collated and managed the database and helped with visualisation and
    drafting of the manuscript. CB, RdCC, and MSC collected data and did a
    literature search." (Contributors, p. e218)
- WARNING: the paper does NOT say data preparation was difficult or
  time-consuming. Allowed argument (thesis author's interpretation): data were
  open but came from five heterogeneous sources (SINAN/DATASUS, IBGE, CRU TS,
  2010 census, SNIS) with different formats and resolutions (monthly, annual,
  static, multi-year aggregate, 0.5° grid), and database collation is listed
  as a separate contributor task -> "open is not the same as analysis-ready".
- **Use in thesis:** chain step 3 ("steps are typical": steps 1–4, 6, 7 also
  in P1); requirements FR-17 (incidence), Tmin/Tmax (task C), lag columns
  (task B, 1–6 justified), lag buffer (A22), spatial aggregation limitation
  (A6), case-definition warning (A15a); possible Case Study (open data + code).

### P5 — Keshav 2007 (method, not cited in thesis necessarily)

- S. Keshav, "How to Read a Paper", ACM SIGCOMM CCR, 2007 — reading method.

### Candidates still to find

- Case study 2: malaria or cholera paper with MONTHLY/WEEKLY data and open data.
- Related-work systems to verify from official docs: Copernicus Climate Data
  Store, Google Earth Engine, IRI ENACTS, DHIS2 Climate & Health / CHAP,
  Malaria Atlas Project, WHO GHO.

---

## 5. System capabilities vs. P1 data-preparation steps

(Checked against code on 2026-10-31. Update when code changes.)

| # | Manual step in P1 | System today | Code | Status |
|---|---|---|---|---|
| 1 | Retrieve data from several sources | Source discovery, OpenDengue, WHO GHO, ERA5/NASA POWER, World Bank/UN WPP, upload; NL request via Gemini | `source_discovery.py`, `case_data.py`, `climate.py`, `population.py`, `who_gho.py`, `llm.py` | ✓ |
| 2 | Harmonise changing admin units (Bueng Kan → Nong Khai) | not supported (country level only) | — | ✗ |
| 3 | Climate variables Tmin, Tmax, etc. | mean temperature, precipitation and (since 2026-11-01, FR-24) Tmin/Tmax from ERA5 / NASA POWER (TMD: none); no soil moisture, vapour pressure, wind, bioclim | `climate.py` | ~ |
| 4 | Spatial aggregation of grid to province | climate from ONE point (lat/lon) per country | `climate.py` | ✗ |
| 5 | Lag 1–3 feature columns | lags 0–3 only as correlations in the report | `statistics.py` | ~ |
| 6 | Bioclimatic indices | not supported | — | ✗ |
| 7 | Linear interpolation of missing years | Population: annual values anchored at 1 July and linearly interpolated to monthly/daily values; missing middle years interpolated; outside the available years held constant (`population.py::_interpolate_annual_population`). Before 2026-10-31 it was a step function with nearest-year fill. (`etl.py:202` is the separate case-rate downscaling, FR-20.) | `population.py` | ✓ (fixed 2026-10-31, A17: annual values anchored at 1 July, linear interpolation, constant outside available years) |
| 8 | Annual → monthly resolution | resolution handling, mass-preserving downscaling (FR-20) | `etl.py` | ✓ |
| 9 | Incidence per 100,000 | yes (FR-17) | `population.py`, `etl.py` | ✓ |
| 10 | Remote sensing (NDVI, MNDWI) | out of scope | — | ✗ |
| 11 | Join everything into one table | core function | `etl.py` (`run_integration`) | ✓ |
| 12 | Document steps (provenance) | automatic audit trail + LLM explanation (FR-18) | `etl.py`, `llm.py` | ✓ (P1 omits some details, e.g. averaging method) |

Important data facts: bundled case data is national (`*_by_iso3.csv`);
WHO GHO data (malaria, cholera) is **annual** only. Thailand dengue in the
bundled file: 2009-01 … 2025-03 (195 months) — implies an OpenDengue version
newer than 1.2; extract and build procedure undocumented. OpenDengue
`dengue_total` = all cases (P1 uses DHF only, so numbers will differ).

### 5.1 Requirements derived from literature (candidates)

| ID | Requirement | Source | Decision |
|---|---|---|---|
| FR-new-1 | Subnational (admin-1) spatial units | P1 | open — ask supervisors |
| FR-new-2 | Area-averaged gridded climate per region (instead of a point) | P1 | open |
| FR-24 (was FR-new-3) | Tmin / Tmax variables, aggregated as mean of daily min/max | P1 (p. 5), P4 (p. e211 "monthly mean daily minimum temperature") | implemented 2026-11-01 (task C); PDF table pending (A16) |
| FR-23 (was FR-new-4) | Lagged climate feature columns (lag 1–6) in output table, computed with a climate lag buffer before start_date | P1, P4 (p. e211) | implemented 2026-11-01 (task B); backend only, frontend display/export pending |
| FR-17 (existing) | Incidence per 100,000 | P1 (p. 7) | justified |
| FR-19 (existing) | Lagged correlations 0–3 | P1 (p. 7), P4 | justified |
| FR-new-5 | Lagged outcome columns (cases/incidence lag 1–3) | P1 p. 9–10: residual autocorrelation (lag-1 0.54) removed by adding previous month's risk status | proposed (RECOMMENDATIONS A1b) |
| FR-new-6 | Optional non-climate covariates (interventions, mobility) | P1 p. 18–19 (COVID-19 failure, AUC 0.62) | Future Work |
| — | Limitation of FR-19: Pearson r measures only linear association; P1 found non-linear threshold effects (~21 °C tmin-1, ~32 °C tmax-3, p. 12) | P1 | mention in thesis; Spearman ALREADY implemented (statistics.py) — threshold effects still not captured |
| FR-20 (existing) | Temporal resolution harmonisation | P1 (p. 4–5) | justified; note P1 repeats annual values (level variable) while FR-20 preserves sums (count variable) — discuss in thesis |

---

## 6. Known FALSE claims (from earlier AI output — never use)

- ✗ "Suttirat et al. used ERA5" → they used **TerraClimate**.
- ✗ "Suttirat et al. state that collecting/harmonising the data required huge
  manual effort" → no such sentence in the paper.
- ✗ "Suttirat paper published 2024/2025" → published **2026-07-28**.
- ✗ "Colón-González et al. 2021 required incidence per 100,000 / used ERA5".
- ✗ "OpenDengue authors emphasise that researchers must join climate data
  themselves" — not stated.
- ✗ OpenDengue title "data platform for global dengue surveillance and
  forecasting" → wrong title.
- ✗ Lowe 2021 DOI ending in `-3` → correct `30292-8`.
- ✗ "Lowe et al. / Sirisena et al. — early warning systems" → no concrete paper.
- ✗ "Researchers spend up to 80 % of their time on data preparation" →
  no scientific source; do not use.
- ✗ "The system reproduces the Suttirat dataset exactly" → false (see §5).
- ✗ "90 seconds instead of 2 weeks" → never measured; only use measured numbers.
- ✗ Case study with WHO GHO malaria monthly lags → GHO is annual only.
- ✗ "Compare OpenDengue with WHO GHO dengue data" → WHO GHO has NO dengue indicator (checked 2026-11-01: 0 of
  3102 indicators mention dengue; malaria has many, e.g. MALARIA_CONF_CASES, MALARIA_EST_CASES). The yearly
  WHO comparison of F2 is therefore relevant for malaria/cholera (WHO as A, monthly upload/URL as B), not dengue.
- ✗ "Our 6-month Thailand correlation (Tmin lag 1, Tmax lag 3) confirms
  Suttirat et al." → n = 6, p > 0.05, seasonal confounding; never use as evidence.
- ✗ "Suttirat et al. aggregated daily Tmin/Tmax to monthly means" → they used
  monthly TerraClimate; the mean-of-daily-minima definition is from P4 (p. e211).

---

## 7. Case studies (plan)

| CS | Content | Status |
|---|---|---|
| CS1 | Reproduce (simplified, national-level) data preparation of P1: dengue Thailand, temperature + precipitation, lags, incidence/100k; compare with P1 / Zenodo data; count manual steps | planned |
| CS2 | Malaria or cholera study with monthly/weekly data (via CSV upload if needed) | paper to be found (Gemini task A2) |
| CS3 | Researcher's own CSV + automatic climate matching, ideally using open data of a paper (e.g. P1 Zenodo) | planned |

Measure, don't guess: time, number of manual steps, variable coverage,
correlation between system climate series and paper's series.

**CS1 method (decided 2026-10-31):** comparative run — same simplified target
dataset (Thailand, national, monthly, 2009–2022 (bundled data starts 2009), ERA5 temp + precip,
incidence/100k, lags) built (A) manually with Python/pandas and (B) with the
system; log time per step, manual steps, tools, lines of code, errors; then
check correctness by comparing both tables. Protocol:
`docs/thesis/evaluation_protocol_CS1.md`. Threats: single developer-tester
(learning effect), simplified scope vs. P1.

---

## 8. Citation and language rules (German thesis, English sources)

- Prefer **paraphrase** in German with citation (indirektes Zitat).
- Direct quotes from English sources stay in **English**, in German quotation
  marks „…", exact wording, with page number; omissions […], insertions [ ].
- Own translation of a quote must be marked "[eigene Übersetzung]".
- Translating without citing = plagiarism.
- Citation style: [TODO: ask supervisors — numeric (IEEE) or author-year].
  Use BibLaTeX + `csquotes` (`\enquote{}`).

---

## 9. Open questions / TODO

- [ ] Sergi: read P1 Methods (p. 4–8) + Table 1 in the original.
- [ ] Ask Haddawy: how long did data preparation for P1 take? (→ "persönliche
      Mitteilung" as evidence)
- [ ] Ask Haddawy: may the Zenodo data be used for CS1 comparison?
- [ ] Ask supervisors: which of FR-new-1…4 to implement vs. list as limitation?
- [ ] Ask supervisors: citation style.
- [ ] Find ≥2 more modelling papers (chain step 3) and CS2 paper.
- [ ] Verify Related Work systems from official documentation.
- [x] OpenDengue quotes with page numbers added (2026-10-31).
- [ ] Check which OpenDengue extract (temporal/national/spatial) and version built `backend/app/data/dengue_monthly_by_iso3.csv`, and how epi weeks spanning two months were assigned (no build script in repo).
- [ ] Thailand in the bundled dengue file starts 2009-01 (ends 2025-03): CS1 period must be 2009–2022 unless earlier OpenDengue data exists.
- [x] DONE 2026-11-01 (A16, FR-25): licence + Figshare DOI shown in every export and PDF (`config.py` license fields). Release of the bundled file still open (A13).
- [x] DONE 2026-11-01 (A14): OpenDengue V1.3 = CC BY 4.0 (figshare + opendengue.org); Open-Meteo API data CC BY 4.0 + ERA5 Copernicus licence; NASA POWER names no licence (asks for citation + notification); World Bank CC BY 4.0 (default); UN WPP 2024 CC BY 3.0 IGO; WHO GHO = WHO data terms (no CC; public-health use, no commercial promotion, modification needs authorisation); TMD not verified. URLs + date in `backend/app/config.py` comments. Original task: Verify exact CC BY-SA version (3.0 or 4.0) on opendengue.org / Figshare, and licences of all other sources (ERA5/Copernicus, Open-Meteo, NASA POWER, World Bank, WHO GHO) on official pages — record URL + check date (RECOMMENDATIONS A14).
- [x] DONE 2026-11-01 (task B, `services/lags.py`): Lag columns (task B) must fetch climate data `max(lag)` periods BEFORE start_date, otherwise first rows are empty (Lowe 2021 p. e211; RECOMMENDATIONS A22).
- [ ] Thesis: subsection on licensing (legal/ethical aspects), incl. ShareAlike consequence for system output (RECOMMENDATIONS B11).
- [x] FIXED 2026-10-31 (A17): population now linearly interpolated (`population.py::_interpolate_annual_population`). Former issue: population was NOT linearly interpolated (step function per year, nearest-year fill; verified in export `climate_health_dataset (4).csv`). See RECOMMENDATIONS A17.
- [ ] CSV/JSON export contains ONLY 6 data columns: no region, sources, dataset versions, licence, retrieval date or request parameters (verified 2026-10-31, `dataset_export_service.dart`). PDF report has steps + sources + "Generated" time (= run/cache time, not upstream retrieval date / dataset version). See RECOMMENDATIONS A16.
- [ ] Build traceability matrix (FR ↔ papers) in `anforderungskatalog.tex`.

## 10. Decision log

| Date | Decision |
|---|---|
| 2026-10-30 | Thesis strategy follows supervisor feedback: literature-based motivation, requirements derivation, case studies. |
| 2026-10-31 | P1 (Suttirat et al. 2026) chosen as main case-study paper (co-author = supervisor Haddawy). |
| 2026-10-31 | Why dengue only (prepared answer, see supervisor_meetings/2026-11-02): open MONTHLY data (OpenDengue) needed because climate effects appear at 0–6 month lags (P1, P4 p. e212); malaria (WHO GHO = modelled estimates, annual, 110 countries) and cholera (reported, annual, sparse: 216 rows / 71 countries) are wired in but annual; system is disease-agnostic (FR-12, CSV upload). Limitation acknowledged; CS2 should use another disease. |
| 2026-10-31 | P4 (Lowe 2021) fully read and translated: confirms typical steps (incidence, gridded climate -> area-weighted regional mean, Tmin/Tmax, lags 0–6, Pearson collinearity check); new requirements A22 (climate lag buffer before start date) and A23 (drought index, Future Work). |
| 2026-10-31 | Requirements catalogue deliberately consolidated (Sergi's decision): FR-01…FR-22, NFR-01…NFR-07; trilingual UI, LLM rate limit and API-key protection are no longer listed as requirements (features still exist in code). New requirements start at FR-23. |
| 2026-10-31 | Missing data: system will DETECT gaps and SUGGEST alternative sources (A18) and optionally COMPARE two sources (A19); automatic gap filling from another source deliberately NOT implemented (A20: different case definitions, resolutions, hidden source mixing) — Future Work only with user confirmation + per-row source column. Proposed new FR-23 lags, FR-24 Tmin/Tmax, FR-25 provenance, FR-26 gap detection, FR-27 comparison (to be confirmed by Sergi). |
| 2026-11-01 | Task E (FR-26, A18): `coverage.py` reports per column the share of missing periods, missing ranges and a deterministic reason (`outside_source_coverage`, `gaps_inside_source`, `not_provided_by_source` e.g. TMD temperature, `unknown`); lag-buffer months excluded; result cached and exported (metadata `data_coverage`, PDF). `DataCoverageCard` (ka/en/de) offers search / adjust-period (intersection with requested period) / other climate source — only pre-fills the form; gaps never filled (A20). Origin of FR-26 corrected by Claude: own export check + Clarke 2024 (Gemini had added Suttirat, who FILLS gaps, not detects them). Report: `docs_ka/motivacia/E_report.md`. |
| 2026-11-01 | Task F (FR-27, A19): `POST /api/compare-sources` + `source_comparison.py` re-run `run_integration` for source A and B (lag_periods=[], no LLM call, main cache/export untouched) and report per variable n overlap, Pearson r (formatted p, never "significant"), mean difference B−A, MAD, relative MAD %; heuristic verdict (very_similar r≥0.90 & relMAD≤10 %, similar r≥0.70 & ≤25 %, else clearly_different; n<6 too_few_points) labelled "rule of thumb, not a statistical test"; climate note on shared seasonal cycle, cases note on case definitions. Cases only via custom_url; different resolutions → resolution_mismatch, no numbers. Claude fixes: constant series → r/p empty (was invented r=0, p=1); relative MAD empty when baseline ≈0; requests with uploaded files → clear 400 (uploads not stored server-side). Live Thailand 2010–2020 ERA5 vs NASA POWER: temperature r=0.94, −0.21 °C, relMAD 3.0 % (very_similar); precipitation r=0.93, +2.69 mm, relMAD 23.4 % (similar). Not in PDF/export yet (follow-up). Report: `docs_ka/motivacia/F_report.md`. |
| 2026-11-01 | Task F2 (FR-27 extension): source B can be a WHO GHO indicator (via /api/search-case-sources), custom_url, an uploaded CSV (new multipart POST /api/compare-sources/upload, file kept in memory only, 10 MB limit) or, for climate, TMD (only if API keys configured, `tmd_configured` in /api/options) / uploaded climate CSV. When WHO GHO (yearly) is involved, BOTH sides run at native resolution and are summed to COMPLETE calendar years only (12 months / all days present); partial or gappy years are excluded and listed (`excluded_years`), never filled or scaled (A20); no yearly→monthly disaggregation. Claude fixes: complete-year rule applied to both sides (Gemini applied it only to source A, so WHO as A + monthly B summed partial years), duplicated run_integration calls refactored into `_run_side`, blocking comparison moved to thread pool in the async upload endpoint, TMD hidden while options unknown. Report: `docs_ka/motivacia/F2_report.md`. |
| 2026-11-01 | Significance rule fixed (`statistics.py::is_significant`): a lagged correlation is labelled "significant" only if n >= 10 pairs AND Pearson p < 0.05 AND Spearman p < 0.05. Found during the local Docker test (Thailand 2010-01…06): lag 3 had 3 pairs, Spearman rho = 1 -> scipy p = 0.0 -> labelled significant while Pearson p = 0.25; the step text said "p < 0.05 … p=0.25". Bug existed since commit 7427d3f. Thesis: good example for the validation chapter (tests passed, output still scientifically wrong). Rule now documented in FR-19 (DE/EN/KA) and TESTING_GUIDE; PDF stats table header "Significant*" with footnote; step text uses p<0.001 instead of a rounded p=0.0 and shows n. Also: LLM explanation is stripped of LaTeX $...$ (seen literally in the PDF). |
| 2026-11-01 | A16 (FR-25): provenance travels WITH the data. JSON export = `{"metadata", "data"}`; CSV stays a plain table + separate `<prefix>_metadata.json` (no `#` comment lines: Excel/pandas misread them). Metadata: disease, region, resolution, request echo, table period AND period actually covered by case counts, sources, licences, steps, retrieved_at, exported_at, system_version (APP_VERSION env or git commit), case-definition note (A15a). Backend adds `licenses` + `system_version` to the response. Lag columns now in table + CSV (not in PDF: too wide). Written by Claude with Sergi (plan: `docs_ka/motivacia/A16_gegma.md`). |
| 2026-10-31 | Checked real export (Thailand 2005–2010 monthly): no provenance in CSV/JSON; population step-wise per year — earlier claim "population interpolated (etl.py:202)" was WRONG, corrected. |
| 2026-10-31 | P3 (OpenDengue) fully read and translated; findings: extract / version / licence requirements, Thailand data only from 2009. |
| 2026-10-31 | Gemini tasks prepared (`docs_ka/motivacia/gemini_tasks_02.md`): A literature, B lag columns, C Tmin/Tmax. Code tasks only after A is reviewed. |
| 2026-11-01 | Task B (FR-23): lags are computed on the climate series fetched `max(lag_periods)` periods before start_date (buffer measured in target-resolution periods, decade = 10 years per lag), then cut back to the requested period; case/population rows never include the buffer. The series is reindexed to a complete period grid before shifting, so a missing period yields NaN instead of a silently wrong value (found in Claude review). Lag columns are dynamic fields of `PeriodRecord` (`extra="allow"`); report: `docs_ka/motivacia/B_report.md`. |
| 2026-11-01 | Task C (FR-24): Tmin/Tmax aggregated as MEAN of daily minima/maxima — justified by P4 Lowe 2021 p. e211 ("monthly mean daily minimum temperature"); P1 Suttirat used already-monthly TerraClimate Tmin/Tmax, so do NOT write "following Suttirat's aggregation". Gemini's C_report claimed a 6-month Thailand correlation "matches Suttirat" — rejected (n = 6, p > 0.05, seasonal confounding); the example only shows that columns are produced correctly. Report: `docs_ka/motivacia/C_report.md`. |

## 11. Related files

- `docs_ka/motivacia/gemini_prompts.md` — round-1 Gemini prompts
- `docs_ka/motivacia/gemini_tasks_02.md` — round-2 Gemini tasks (A literature, B lags, C Tmin/Tmax, D population interpolation = A17)
- `docs_ka/motivacia/gemini_tasks_03.md` — round-3 Gemini tasks (E gap detection + alternative sources, F source comparison; A20 auto-filling deliberately NOT implemented)
- `docs/thesis/CHANGE_DOCUMENTATION_GUIDE.md` — which documents must be updated for each code change (Definition of Done), proposed FR-23…FR-27
- `docs_ka/motivacia/A16_gegma.md` — Sergi's own plan: provenance (region, sources, version, licence, dates) in CSV/JSON export
- `docs_ka/motivacia/kitxvis_furceli.md` — reading-sheet template
- `docs_ka/motivacia/papers/` — PDFs and Georgian translation of P1
- `docs/requirements/anforderungskatalog.tex` — requirements catalogue (DE/EN)
- `docs/thesis/RECOMMENDATIONS.md` — prioritised to-do list (code + thesis)
- `docs/thesis/evaluation_protocol_CS1.md` — CS1 test protocol
