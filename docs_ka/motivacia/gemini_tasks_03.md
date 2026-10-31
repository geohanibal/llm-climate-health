# Gemini დავალებები — რაუნდი 3 (ხარვეზები და წყაროების შედარება)

როგორ გამოიყენო:
- Gemini CLI გახსენი პროექტის საქაღალდეში და **ერთ ჯერზე ერთი დავალება**
  მიეცი: ჯერ E, შემდეგ F.
- სანამ დაიწყებ, **დააკომიტე** მიმდინარე მდგომარეობა, რომ Gemini-ს ცვლილებები
  ცალკე ჩანდეს.
- თითოეულის შემდეგ Claude-ს უთხარი „შეამოწმე დავალება E“ (ან F).

რა არის რა (`docs/thesis/RECOMMENDATIONS.md`):

| დავალება | რეკომენდაცია | რას აკეთებს მომხმარებლისთვის |
|---|---|---|
| E | A18 (P1) | თუ მონაცემი რომელიმე თვეს აკლია, სისტემა ამას გასაგებად ეუბნება და სთავაზობს სხვა წყაროს მოძებნას |
| F | A19 (P2) | ორი წყაროს (მაგ. ERA5 vs NASA POWER) გვერდიგვერდ შედარება: რამდენად ემთხვევა |
| — | A20 (Future Work) | ხარვეზების **ავტომატური** შევსება სხვა წყაროდან. **განზრახ არ კეთდება** (მიზეზი ქვემოთ) |

ორივე დავალებას აქვს საერთო მოთხოვნა: ყოველი კოდის ცვლილება უნდა აღიწეროს
დოკუმენტებში, `docs/thesis/CHANGE_DOCUMENTATION_GUIDE.md`-ის მიხედვით.

---

## დავალება E — ხარვეზების აღმოჩენა + ალტერნატიული წყაროს შეთავაზება (A18)

```
You are working in the repository of a bachelor thesis: an LLM-driven ETL
platform that joins disease case data, climate data and population data
(Python FastAPI backend in backend/, Flutter web frontend in frontend/).

READ FIRST (before changing anything):
- GEMINI.md, README.md, backend/README.md, frontend/README.md
- docs/thesis/CHANGE_DOCUMENTATION_GUIDE.md   <- you MUST follow it
- backend/app/models.py (IntegrationResponse, PeriodRecord, DiscoveredSource)
- backend/app/services/etl.py, backend/app/main.py (/api/integrate,
  /api/search-case-sources, /api/search-population-sources)
- frontend/lib/models/integration_result.dart, frontend/lib/widgets/
  results_view.dart, source_search_dialog.dart, population_search_dialog.dart,
  frontend/lib/core/localization.dart

RULES
- Do NOT commit to git.
- Do NOT invent data, sources or citations. The system must never fill a gap
  with made-up or copied values in this task.
- Default behaviour of existing features must not change; existing tests must
  keep passing.
- All user-facing texts in THREE languages: Georgian (ka), English (en),
  German (de), via frontend/lib/core/localization.dart. No mixed languages.
- Code style: match the surrounding code (doc comments, naming, small
  focused files). New widget = new file.

PROBLEM (real example, verified 2026-10-31)
A user requested dengue, Thailand, monthly, 2005-01 ... 2010-12. The bundled
OpenDengue data for Thailand starts in 2009-01, so 48 of 72 months
(2005-01 ... 2008-12) came back with empty case_count and incidence. The
system said NOTHING about this. The user only noticed by reading the CSV.
A system to search alternative case-data sources already exists
(/api/search-case-sources, SourceSearchDialog), but it is not offered when
data is missing.

GOAL
When data is incomplete, the user immediately understands (1) WHAT is
missing, (2) WHY that probably happened, (3) WHAT they can do — with one click.

TASK
1. Backend — coverage report (new module backend/app/services/coverage.py):
   For each data column of the integrated table (case_count, population,
   incidence_rate_per_100k, every requested climate variable) compute:
     - total_periods, periods_with_value, missing_count, missing_percent
       (1 decimal)
     - missing_ranges: list of {start, end} of CONSECUTIVE missing periods
       (e.g. [{"start": "2005-01", "end": "2008-12"}])
     - first_available, last_available (period strings or null)
   Add to the Pydantic models a `DataCoverage` model and an optional field
   `data_coverage: list[DataCoverage]` on IntegrationResponse (default empty,
   so old clients/caches keep working). Compute it in etl.py after the join.
   Also add one pipeline step text, e.g.
   "Checked data completeness: case_count missing for 48 of 72 periods
    (2005-01 – 2008-12)."
   Only when something is missing; otherwise "All requested periods have data."

2. Backend — likely reason (no LLM, deterministic):
   For the built-in case source, compare the requested range with the known
   coverage (config.DISEASE_REGION_COVERAGE). If the gap lies outside the
   source's coverage, set `reason = "outside_source_coverage"` and include the
   source's available range. Other values: "gaps_inside_source" (missing
   months inside the coverage), "unknown". This lets the UI explain the gap
   in plain words instead of guessing.

3. Frontend — new widget frontend/lib/widgets/data_coverage_card.dart:
   - Shown in results_view.dart ABOVE the chart, ONLY if any column has
     missing_count > 0. If everything is complete, show nothing (no noise).
   - Plain-language message, no jargon. Example (en):
       "Case data is missing for 48 of 72 months (2005-01 – 2008-12).
        Reason: the selected source (OpenDengue) only has data for Thailand
        from 2009-01."
     followed by a small per-variable list with a thin progress bar
     (e.g. "Cases 33 %", "Temperature 100 %").
   - Colour: amber/warning when > 0 % missing, red when > 50 % missing.
     Use an icon + text, never colour alone (accessibility).
   - Action buttons, depending on which column has gaps:
       * case_count / incidence -> "Search other case-data sources"
         opens the EXISTING SourceSearchDialog pre-filled with disease and
         region.
       * population -> "Search population sources" opens the EXISTING
         PopulationSearchDialog.
       * climate variable -> hint "Try another climate source (e.g. NASA
         POWER)" — if easy, a button that re-runs the request with the other
         climate source; otherwise just the hint text.
       * "Adjust period to available data" -> sets the form's start/end to
         first_available/last_available (only if that is simple to wire).
   - A short, always-visible note under the buttons:
       "Different sources may count cases differently (e.g. all cases vs.
        severe cases only). Check the source description before combining."

4. Include coverage in outputs:
   - PDF report (report_pdf_service.dart): a small "Data completeness" section
     (table: variable, available %, missing ranges).
   - Do NOT change the CSV columns. (A separate task, A16, adds metadata to
     the export; if A16 already exists, add coverage to that metadata.)

5. Tests:
   - pytest for coverage.py: no gaps; one leading gap; gap in the middle;
     several ranges; all missing; resolution "year" and "day" period strings.
   - pytest: IntegrationResponse contains data_coverage; reason
     "outside_source_coverage" for Thailand 2005–2010.
   - flutter test: card hidden when complete; card shown with correct text
     and the right buttons when cases are missing; tapping the button opens
     SourceSearchDialog.
   Run the full backend suite and `flutter analyze` + `flutter test`; paste
   the summaries.

6. Documentation: follow docs/thesis/CHANGE_DOCUMENTATION_GUIDE.md
   (section "Task E"). List every document you changed in the report.

7. Write docs_ka/motivacia/E_report.md:
   changed/new files, a screenshot description or ASCII sketch of the card,
   the Thailand 2005–2010 example (what the user now sees), test summaries,
   documentation changes, open questions.
```

---

## დავალება F — ორი წყაროს შედარება (A19)

> **ქართულად, რატომ:** Clarke et al. 2024 (OpenDengue) წერს, რომ წყაროები
> ერთმანეთისგან განსხვავდება და მათი შედარებადობის შეფასება საჭიროა (გვ. 2,
> 10–12). ეს ფუნქცია მკვლევარს აჩვენებს, რამდენად ემთხვევა ორი წყარო
> ერთმანეთს, სანამ რომელიმეს აირჩევს. თეზისში ის Case Study 1-ის სისწორის
> შემოწმებასაც გამოადგება (ERA5 vs NASA POWER).

```
Same repository, same READ FIRST list and same RULES as task E
(docs_ka/motivacia/gemini_tasks_03.md). Additionally read
backend/app/services/climate.py, backend/app/services/statistics.py and
frontend/lib/widgets/case_chart_card.dart.

GOAL
A researcher can compare TWO sources for the same quantity over the same
region and period and get a clear, honest answer: "how similar are they?"
— without any data being merged or changed.

SCOPE (keep it small)
- Climate: compare the two climate sources that work for every region:
  "open-meteo-era5" vs "nasa-power", per requested variable.
- Cases: compare the current case source with ONE alternative the user picked
  (built-in vs who_gho / custom_url / custom_upload) — only if the existing
  integration code can already load that alternative; otherwise do climate
  only and say so in the report.

TASK
1. Backend: new endpoint POST /api/compare-sources.
   Request: the normal IntegrationRequest + `compare_kind: "climate" | "cases"`
   + the alternative source settings. Run the integration twice (re-use the
   cache), then for every compared variable compute on the OVERLAP only
   (periods where BOTH sources have a value):
     - overlap_periods (n), pearson_r (reuse statistics.py helpers),
       mean_difference (B − A), mean_absolute_difference,
       relative_mean_absolute_difference_percent (relative to mean of A),
     - both full series for plotting.
   Put the logic in a new module backend/app/services/source_comparison.py.
   If overlap_periods < 6, return the numbers but flag
   `too_few_points = true`.

2. Plain-language verdict (deterministic, NOT from the LLM):
     "very similar"   if r >= 0.9 and relative MAD <= 10 %
     "similar"        if r >= 0.7 and relative MAD <= 25 %
     "clearly different" otherwise
   These thresholds are a HEURISTIC for orientation only. Put them as named
   constants with a comment saying so, and show the user the sentence
   "Rule of thumb, not a statistical test."
   For cases ALWAYS add a warning: case definitions / reporting systems may
   differ (e.g. OpenDengue dengue_total = all cases), so differences in level
   are expected; compare the SHAPE (r) more than the level.

3. Frontend: a "Compare sources" button in the results view (next to the
   download bar) that opens a new dialog
   frontend/lib/widgets/source_comparison_dialog.dart:
   - user picks what to compare (climate / cases) and the alternative source;
   - result: one line chart per variable with both sources (two colours +
     legend with source names), a verdict chip with icon
     (✓ very similar / ≈ similar / ! clearly different) and a one-sentence
     explanation, e.g. (en):
       "Temperature: ERA5 and NASA POWER move almost identically (r = 0.97);
        NASA POWER is on average 0.4 °C warmer."
   - numbers available in a small expandable "details" table for experts.
   - IMPORTANT: comparison never changes the user's main dataset. State this
     in the dialog ("This comparison does not change your dataset.").
   - All texts in ka / en / de.

4. PDF: optional — if simple, a button "Add comparison to report"; otherwise
   skip and mention in the report.

5. Tests:
   - pytest for source_comparison.py with small synthetic series: identical
     series -> r = 1, MAD = 0, "very similar"; shifted series -> correct
     mean_difference; non-overlapping periods ignored; n < 6 flagged.
   - pytest for the endpoint with mocked upstream sources (no network).
   - flutter test: dialog shows verdict chip and both legend entries.
   Run full suites, paste summaries.

6. Documentation: follow docs/thesis/CHANGE_DOCUMENTATION_GUIDE.md
   (section "Task F").

7. Write docs_ka/motivacia/F_report.md: files, example result for Thailand
   2010–2020 monthly ERA5 vs NASA POWER (real numbers from a real run if
   network is available; otherwise say clearly that it was not run),
   tests, documentation changes, open questions.

DO NOT implement automatic gap filling (merging values of source B into gaps
of source A). This is a deliberate design decision, see
docs/thesis/RECOMMENDATIONS.md A20.
```

---

## A20: რატომ **არ** ვავსებთ ხარვეზებს ავტომატურად (თეზისისთვის)

- **განსხვავებული განსაზღვრებები:** OpenDengue-ს `dengue_total` ყველა
  შემთხვევაა, სხვა წყარო შეიძლება მხოლოდ DHF-ს ან დადასტურებულ შემთხვევებს
  ითვლიდეს. შეერთებისას ხელოვნური ნახტომი ჩნდება, რომელიც მოდელს „ეპიდემიის
  ცვლილებად“ მოეჩვენება.
- **განსხვავებული რეზოლუცია:** WHO GHO წლიურია. წლიური მნიშვნელობის თვეებად
  დაყოფით მონაცემი გამოიგონება.
- **გამჭვირვალობა:** მკვლევარმა შეიძლება ვერ შეამჩნიოს, რომ სერია ორი
  წყაროდანაა აწყობილი. ეს სისტემის მთავარ პრინციპს (NFR-01, FR-18)
  ეწინააღმდეგება.
- **Future Work:** შევსება მხოლოდ მომხმარებლის დადასტურებით, `case_source`
  სვეტით თითოეულ სტრიქონზე და მანამდე ნაჩვენები შედარებით (F).
