# Change Documentation Guide — where every code change must be described

> **ქართულად:** ეს ფაილი განსაზღვრავს, კოდის ყოველი ცვლილება **რომელ
> დოკუმენტებში** უნდა აღიწეროს. წესი ერთნაირია Gemini-სთვის, Claude-სთვის და
> სერგისთვის. დავალება მხოლოდ მაშინ ითვლება დასრულებულად, როცა კოდი,
> ტესტები **და** დოკუმენტები განახლებულია (Definition of Done). ცხრილი 1
> ზოგადი წესია, ნაწილი 3 თითოეული დავალების კონკრეტული სიაა.

Applies to: Gemini tasks B, C, D (`docs_ka/motivacia/gemini_tasks_02.md`),
E, F (`docs_ka/motivacia/gemini_tasks_03.md`), Sergi's task A16
(`docs_ka/motivacia/A16_gegma.md`) and every future code change.

## 1. General rule — which document for which kind of change

| Document | What it is | Update when … | Language |
|---|---|---|---|
| Code docstrings / comments | in-code documentation | always (new module, class, public function, non-obvious decision such as a threshold or aggregation choice) | English |
| Tests (`backend/tests/`, `frontend/test/`) | executable spec | always | English |
| `README.md` (root) | high-level system overview | a new user-visible capability | English |
| `backend/README.md` | endpoints table + layout | new/changed endpoint, new service module | English |
| `frontend/README.md` | layout | new widget/service/model file | English |
| `docs/TESTING_GUIDE.md` | how to test, what is covered, manual walkthrough, API reference, known limitations | new tests, new manual check, new endpoint, new limitation | English |
| `docs/requirements/anforderungskatalog.tex` (+ `.pdf`) | requirements catalogue, **German part AND English part in the same file** | new requirement or changed requirement text/status | DE + EN |
| `docs_ka/anforderungskatalog_ka.tex` (+ `.pdf`) | same catalogue in Georgian | same as above (keep IDs identical) | KA |
| `docs_ka/dokumentacia.tex` (+ `.pdf`) | Georgian technical documentation (sections: ETL, sources, "ამჟამად განხორციელებული ფუნქციები", "შემდეგი ნაბიჯები") | new feature (add to implemented list, describe in the matching section), remove from "next steps" if done | KA |
| `docs/thesis/THESIS_KNOWLEDGE_BASE.md` | thesis memory | §5 capability table, §5.1 requirements, §9 TODOs, §10 decision log. **Gemini: propose the change in your report; do not silently edit VERIFIED entries** (§0 of the KB) | EN |
| `docs/thesis/RECOMMENDATIONS.md` | roadmap | mark the item done (✅ + date) | KA |
| `docs/thesis/evaluation_protocol_CS1.md` | case-study test protocol | only if the change affects the CS1 scope (e.g. lags, Tmin/Tmax) | EN |
| `docs_ka/motivacia/<X>_report.md` | task report for review by Claude | always for Gemini tasks | KA or EN |

**Requirement IDs.** The catalogue currently has FR-01 … FR-22 and NFR-01 …
NFR-07 (checked 2026-10-31). New requirements get the next free number. The
IDs below are **proposals**: Sergi confirms them, then they must be identical
in all three catalogue versions (DE, EN, KA) and in the KB.

**Every new requirement row must name its origin** ("Herkunft" / origin column),
e.g. "Literatur: Suttirat et al. 2026" or "Literatur: Clarke et al. 2024". This
is the traceability the supervisors asked for (requirement derived from a
publication).

**Compiling the LaTeX documents** (MiKTeX, XeLaTeX, Georgian font Sylfaen):
```
cd docs/requirements && xelatex anforderungskatalog.tex && xelatex anforderungskatalog.tex
cd docs_ka && xelatex anforderungskatalog_ka.tex && xelatex anforderungskatalog_ka.tex
cd docs_ka && xelatex dokumentacia.tex && xelatex dokumentacia.tex
```
(Run twice for the table of contents.) Commit `.tex` and `.pdf` together. Do
not use Unicode arrows/check marks in Georgian documents (Sylfaen lacks them):
use `$\rightarrow$`, `$\checkmark$`, `$\times$` (package `amssymb`).

## 2. Known existing inconsistencies (fix when touching these files)

- `backend/README.md` endpoints table lists only 5 endpoints; missing:
  `/api/chat`, `/api/extract-literature`, `/api/search-case-sources`,
  `/api/search-population-sources` (+ any new ones).
- FR-19 (all three catalogues) says "Pearson-r", but Spearman is already
  computed (`statistics.py`, `spearmanr`). Update the text to
  "Pearson-r und Spearman-ρ".
- KB §5 previously claimed population is interpolated — corrected
  2026-10-31; task D fixes the code.

## 3. Task-specific checklists

### Task B — lag columns (proposed FR-23)
- Catalogue DE/EN/KA: new FR-23 "Das System muss optional zeitverzögerte
  Klimavariablen (Lag 1–6) als eigene Spalten im integrierten Datensatz
  bereitstellen." Origin: Suttirat et al. 2026.
- `docs_ka/dokumentacia.tex`: ETL section + implemented features list.
- `backend/README.md` (request field), `docs/TESTING_GUIDE.md` (coverage + a
  manual step).
- KB §5 table: "lag columns" ✗ → ✓; RECOMMENDATIONS A1 ✅.
- `evaluation_protocol_CS1.md`: remove "[if task B done]".

### Task C — Tmin/Tmax (proposed FR-24)
- Catalogue: FR-24 "Tagesminimum- und -maximumtemperatur (ERA5, NASA POWER)".
  Origin: Suttirat et al. 2026. Also update the variable list in FR-01/FR-02 if
  variables are enumerated there.
- `docs_ka/dokumentacia.tex`: data-sources section (field names
  `temperature_2m_min/max`, `T2M_MIN/T2M_MAX`, aggregation = mean of daily
  values).
- READMEs / TESTING_GUIDE; KB §5; RECOMMENDATIONS A2 ✅;
  `evaluation_protocol_CS1.md`: remove "[if task C done]".

### Task D — population interpolation (extends FR-17)
- Catalogue: extend FR-17 text: "… jährliche Bevölkerungswerte werden linear
  auf Monats-/Tageswerte interpoliert." Origin: Suttirat et al. 2026.
- `docs_ka/dokumentacia.tex`: ETL section (how monthly population is derived).
- KB §5 table row 7 ✗ → ✓, §9 TODO closed; RECOMMENDATIONS A17 ✅.
- TESTING_GUIDE "What's covered".

### Task A16 — provenance in export (proposed FR-25, strengthens NFR-01)
- Catalogue: FR-25 "Exportierte Datensätze (CSV/JSON) müssen Metadaten zur
  Herkunft enthalten: Region, Parameter, Quellen, Datensatzversion, Lizenz,
  Abrufzeitpunkt, Systemversion." Origin: Clarke et al. 2024 (pp. 4, 12).
- `docs_ka/dokumentacia.tex`: "გამჭვირვალობა და კეშირება" subsection.
- `frontend/README.md` (new model file), TESTING_GUIDE.
- KB §5/§9; RECOMMENDATIONS A14 + A16 ✅.

### Task E — gap detection + alternative sources (proposed FR-26)
- Catalogue: FR-26 "Das System muss fehlende Perioden je Variable erkennen,
  dem Nutzer verständlich anzeigen (Umfang, Zeitraum, wahrscheinlicher Grund)
  und passende alternative Quellen zur Suche anbieten." Origin: own
  evaluation (export check 2026-10-31) + Clarke et al. 2024 (data gaps,
  comparability). Also mention in NFR-03 (comprehensibility) if useful.
- `docs_ka/dokumentacia.tex`: new subsection under ETL ("მონაცემთა
  სისრულის შემოწმება"), implemented features list; update
  "დაავადების მონაცემთა წყაროების ცოცხალი ძებნა" (search is now also offered
  automatically).
- `backend/README.md`: response field `data_coverage`, new module
  `coverage.py`; `frontend/README.md`: `data_coverage_card.dart`.
- TESTING_GUIDE: manual step "request Thailand 2005–2010 → warning card
  appears, button opens source search".
- `docs_ka/testkit/Testireba_Prezentaciistvis.md`: optional demo scenario.
- KB §5 + §10 decision log; RECOMMENDATIONS A18 ✅.

### Task F — source comparison (proposed FR-27)
- Catalogue: FR-27 "Das System muss zwei Quellen derselben Größe über den
  gemeinsamen Zeitraum vergleichen (r, mittlere Abweichung) und das Ergebnis
  verständlich einordnen, ohne den Datensatz zu verändern." Origin: Clarke et
  al. 2024 (comparability between sources).
- `docs_ka/dokumentacia.tex`: new subsection; state the heuristic thresholds
  and that they are not a statistical test.
- `backend/README.md` endpoints table: `POST /api/compare-sources`;
  TESTING_GUIDE API reference + coverage.
- KB §5/§10; RECOMMENDATIONS A19 ✅. Note in KB that it can support the CS1
  correctness check (ERA5 vs NASA POWER).

### A20 — automatic gap filling (NOT implemented)
- Catalogue: do not add as FR. Mention in "Validierung"/limitations or in the
  thesis "Future Work" with the reasons (different case definitions, annual
  vs monthly resolution, hidden mixing of sources).
- `docs_ka/dokumentacia.tex`: "შემდეგი ნაბიჯები" — one bullet.
- TESTING_GUIDE §7 "Known limitations".
