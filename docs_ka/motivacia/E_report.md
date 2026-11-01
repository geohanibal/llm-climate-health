# დავალება E — ანგარიში: ხარვეზების აღმოჩენა და ალტერნატიული წყაროს შეთავაზება (FR-26, A18)

**ავტორი:** Sergi Koniashvili (LLM-Climate-Health, საბაკალავრო ნაშრომი, ბრემენის უნივერსიტეტი)  
**თარიღი:** 2026-11-01  
**სტატუსი:** სრულად შესრულებულია (Backend, Frontend, ტესტები და დოკუმენტაცია განახლებულია, LaTeX დაკომპილირებულია)

---

## 1. შექმნილი და შეცვლილი ფაილების სია

| ფაილი | ცვლილების ტიპი | აღწერა |
|---|---|---|
| `backend/app/models.py` | შეცვლილი | დაემატა `MissingRange` და `DataCoverage` Pydantic მოდელები; `IntegrationResponse`-ს დაემატა `data_coverage: list[DataCoverage] = Field(default_factory=list)`. |
| `backend/app/services/coverage.py` | **ახალი** | მონაცემთა სისრულისა და დროითი ხარვეზების ანალიზის მოდული. ითვლის `total_periods`, `periods_with_value`, `missing_count`, `missing_percent`, `missing_ranges`, `first_available`, `last_available` და დეტერმინისტულ მიზეზებს (`outside_source_coverage`, `gaps_inside_source`, `not_provided_by_source`, `unknown`). გამორიცხავს Task B-ს Lag-ბუფერის თვეებს. |
| `backend/app/services/etl.py` | შეცვლილი | ინტეგრაციის შემდეგ იძახებს `analyze_data_coverage`-ს, ამატებს გამჭვირვალობის ნაბიჯს (`Checked data completeness: ...`) და აბრუნებს 6-ეულს (`coverage_data`-ს ჩათვლით). |
| `backend/app/main.py` | შეცვლილი | `_build_response`, `_run_integration_or_502`, `/api/integrate` და `/api/integrate/upload` განახლდა `data_coverage`-ის გადასაცემად; კეშირებაში ინახება და cache hit-ისას (`cached=True`) სრულად აღდგება `data_coverage`. |
| `backend/tests/test_coverage.py` | **ახალი** | Unit-ტესტები: სრული მონაცემები (0 ხარვეზი), შიდა ხარვეზები (`gaps_inside_source`), წყაროს დაფარვის მიღმა ხარვეზები (`outside_source_coverage`), წყაროს მიერ ცვლადის არმოწოდება (`not_provided_by_source` TMD-ის ტემპერატურაზე) და მრავალდიაპაზონიანი ხარვეზები. |
| `backend/tests/test_etl.py` | შეცვლილი | განახლდა არსებული ტესტები 6 მნიშვნელობის ამოკითხვისთვის; დაემატა mock-ტესტი ტაილანდის დენგეზე 2005–2010 (48 გამოტოვებული თვე). |
| `backend/tests/test_api.py` | შეცვლილი | დაემატა ტესტი `test_integrate_cache_hit_preserves_data_coverage`: განმეორებითი მოთხოვნა კეშიდან ზუსტად იგივე `data_coverage`-ს აბრუნებს. |
| `frontend/lib/models/integration_result.dart` | შეცვლილი | დაემატა `MissingRange` და `DataCoverage` კლასები; `IntegrationResult`-ს დაემატა `dataCoverage` (ნაგულისხმევად ცარიელი სია). |
| `frontend/lib/models/export_metadata.dart` | შეცვლილი | დაემატა `dataCoverage` ველი; `toJson()`-ში ექსპორტირდება `'data_coverage'` სია (A16 პროვენენსის ექსპორტი, CSV სვეტების შეუცვლელად). |
| `frontend/lib/core/localization.dart` | შეცვლილი | დაემატა ლოკალიზაციის გასაღებები (`dataCoverageTitle`, `dataCoverageMissing`, მიზეზები, ღილაკები, შედარებადობის შენიშვნა) სამ ენაზე: ქართულად (ka), ინგლისურად (en) და გერმანულად (de). |
| `frontend/lib/widgets/data_coverage_card.dart` | **ახალი** | UI ბარათი: ჩნდება მხოლოდ მაშინ, როცა მონაცემები აკლია (`missingCount > 0`); აჩვენებს პროგრესის ხაზებს, დეტერმინისტულ მიზეზს, ერთ-კლიკიან ღილაკებს და Clarke et al. (2024) შედარებადობის შენიშვნას. `not_provided_by_source` ნაჩვენებია ნეიტრალურად. |
| `frontend/lib/widgets/results_view.dart` | შეცვლილი | `CaseChartCard`-ის თავზე განთავსდა `DataCoverageCard` შესაბამისი callback-ებით. |
| `frontend/lib/widgets/request_form_card.dart` | შეცვლილი | დაემატა საჯარო მეთოდები `applyDateRange`, `applyClimateSource`, `openCaseSourceSearch` და `openPopulationSourceSearch`. |
| `frontend/lib/pages/home_page.dart` | შეცვლილი | `ResultsView`-ს მიება `_formKey.currentState`-ის მეთოდები (პერიოდის მორგება, წყაროს ძებნა, კლიმატის წყაროს შეცვლა). |
| `frontend/lib/services/report_pdf_service.dart` | შეცვლილი | PDF ანგარიშში დაემატა სექცია და ცხრილი `Data Completeness & Temporal Gaps`, როდესაც მონაცემებში ხარვეზებია. |
| `frontend/test/data_coverage_card_test.dart` | **ახალი** | Widget-ტესტები: სრული მონაცემებისას ბარათი იმალება; ხარვეზებისას ჩნდება გაფრთხილება და ღილაკები; ღილაკზე დაჭერა იძახებს callback-ებს; `not_provided_by_source` ნეიტრალურია. |
| `frontend/test/dataset_export_service_test.dart` | შეცვლილი | დაემატა ტესტი, რომ ექსპორტირებული მეტამონაცემები შეიცავს `data_coverage` ველს. |
| `frontend/test/models_test.dart` | შეცვლილი | დაემატა `DataCoverage` და `MissingRange` round-trip დეკოდირების ტესტი. |
| `docs/requirements/anforderungskatalog.tex` (+ `.pdf`) | შეცვლილი | დაემატა **FR-26** გერმანულ და ინგლისურ ენებზე (წყარო: *Clarke et al. 2024, Suttirat et al. 2026*); დაკომპილირდა `xelatex`-ით (11 გვერდი). |
| `docs_ka/anforderungskatalog_ka.tex` (+ `.pdf`) | შეცვლილი | დაემატა **FR-26** ქართულად; დაკომპილირდა `xelatex`-ით (8 გვერდი). |
| `docs_ka/dokumentacia.tex` (+ `.pdf`) | შეცვლილი | დაემატა ქვეთავი „მონაცემთა სისრულის შემოწმება და ხარვეზების აღმოჩენა (FR-26)“, განახლდა ფუნქციების სია; დაკომპილირდა `xelatex`-ით (12 გვერდი). |
| `backend/README.md` | შეცვლილი | აღიწერა `Data Coverage & Gap Detection (FR-26)` და ახალი მოდული `coverage.py`. |
| `frontend/README.md` | შეცვლილი | აღიწერა `data_coverage_card.dart` და მეტამონაცემების გაფართოება. |
| `docs/TESTING_GUIDE.md` | შეცვლილი | დაემატა ხელით შემოწმების სცენარი №13 (ტაილანდი 2005–2010). |
| `docs/thesis/RECOMMENDATIONS.md` | შეცვლილი | A18 მონიშნულია როგორც ✅ 2026-11-01. |

---

## 2. მომხმარებლის ინტერფეისის ესკიზი (ASCII Sketch)

როდესაც მომხმარებელი ითხოვს პერიოდს, სადაც მონაცემები არასრულია (მაგ. დენგე ტაილანდში 2005–2010, 72 თვე), გრაფიკის ზემოთ ჩნდება შემდეგი ბარათი:

```text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ ⚠  Data Completeness & Gaps                                                            │
│                                                                                        │
│ Cases: missing for 48 of 72 periods (2005-01 – 2008-12) (33.3 % complete)              │
│ [████████████░░░░░░░░░░░░░░░░░░░░░░░░] 33.3 %                                          │
│ Reason: the selected source only covers 2009-01 – 2025-03.                             │
│ Part of the requested range lies outside the source's coverage.                        │
│                                                                                        │
│ [🔍 Search other case-data sources]   [🎛 Adjust period to available data (2009-01 – 2010-12)] │
│                                                                                        │
│ * Note: when comparing data across different sources, consider differing               │
│   methodologies and definitions (Clarke et al. 2024).                                  │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

**მნიშვნელოვანი თვისებები:**
- **სიცხადე და ხელმისაწვდომობა:** ფერი (წითელი >50% ხარვეზზე, ქარვისფერი >0% ხარვეზზე, ნეიტრალური ნაცრისფერი/ლურჯი `not_provided_by_source`-ზე) მარტო არ გამოიყენება; თან ახლავს მკაფიო ხატულა (`Icons.error_outline`, `Icons.warning_amber_rounded`, `Icons.info_outline`) და პროცენტული მაჩვენებელი.
- **არავითარი გამოგონილი მონაცემი (A20):** სისტემა ხარვეზებს **არასდროს** არ ავსებს ხელოვნური რიცხვებით.
- **ერთ-კლიკიანი ქმედებები:**
  1. „Search other case-data sources“ ხსნის `SourceSearchDialog`-ს, სადაც მომხმარებელს შეუძლია WHO GHO-ს ან HDX-ის ალტერნატიული წყარო მოძებნოს.
  2. „Adjust period to available data“ მხოლოდ წინასწარ ავსებს ფორმის დაწყება/დასრულების თარიღებს (`2009-01` და `2010-12`) და ავტომატურ საბმიტს **არ** უშვებს (მომხმარებელი თავად ადასტურებს).
  3. მოსახლეობის ხარვეზისას ჩნდება „Search population sources“ (`PopulationSearchDialog`).
  4. კლიმატის ხარვეზისას ჩნდება ალტერნატიული წყარო (ERA5 $\leftrightarrow$ NASA POWER).

---

## 3. რეალური ტესტირება: ტაილანდი, დენგე, 2005-01 .. 2010-12 (OpenDengue)

გაშვებულია პირდაპირი მოთხოვნა რეალურ მონაცემებზე:
- **დაავადება:** `dengue`
- **რეგიონი:** `Thailand`
- **პერიოდი:** `2005-01-01` -- `2010-12-31` (72 თვე)
- **კლიმატის ცვლადები:** `temperature`, `precipitation`
- **აგრეგაცია:** `native` (თვიური)

### მიღებული შედეგები:
1. **სულ ჩანაწერები:** 72 თვე (`len(records) == 72`)
2. **`case_count` დაფარვა:**
   - სულ პერიოდი: 72
   - მნიშვნელობით: 24 (2009-01-დან 2010-12-მდე)
   - აკლია: 48 თვე (66.7%)
   - გამოტოვებული ინტერვალი: `[{"start": "2005-01", "end": "2008-12"}]`
   - პირველი ხელმისაწვდომი: `2009-01`, ბოლო: `2010-12`
   - სავარაუდო მიზეზი: `outside_source_coverage`
   - წყაროს ცნობილი დაფარვა: `{"start": "2009-01", "end": "2025-03"}`
3. **`incidence_rate_per_100k` დაფარვა:**
   - აკლია: 48 თვე (66.7%), მიზეზი: `outside_source_coverage`
4. **`population` დაფარვა:**
   - სულ: 72, მნიშვნელობით: 72, აკლია: 0 (100.0% სრული)
5. **`temperature_mean_c` დაფარვა:**
   - სულ: 72, მნიშვნელობით: 72, აკლია: 0 (100.0% სრული)
6. **`precipitation_sum_mm` დაფარვა:**
   - სულ: 72, მნიშვნელობით: 72, აკლია: 0 (100.0% სრული)
7. **Provenance-ნაბიჯი (Steps):**
   > *"Checked data completeness: case_count missing for 48 of 72 periods (2005-01 – 2008-12); incidence_rate_per_100k missing for 48 of 72 periods (2005-01 – 2008-12)."*

---

## 4. ტესტების შედეგები

### Backend (pytest)
```bash
powershell -Command "Set-Location backend; .venv\Scripts\python.exe -m pytest -q"
```
**შედეგი:**
```text
165 passed, 1 warning in 25.50s
```
*(ყველა 165 ტესტი მწვანეა; მათ შორის ახალი unit-ტესტები `test_coverage.py`-ში, `test_etl.py`-ში და `test_api.py`-ში კეშირების შემოწმებით).*

### Frontend (flutter analyze & flutter test)
```bash
powershell -Command "Set-Location frontend; & 'C:\Users\49172\flutter\flutter\bin\flutter.bat' analyze"
```
**შედეგი:**
```text
No errors found. (23 pre-existing deprecation/info warnings in untouched dialog files).
```

```bash
powershell -Command "Set-Location frontend; & 'C:\Users\49172\flutter\flutter\bin\flutter.bat' test"
```
**შედეგი:**
```text
00:36 +80: All tests passed!
```
*(ყველა 80 frontend ტესტი წარმატებით გადის; მათ შორის `data_coverage_card_test.dart`, `dataset_export_service_test.dart` და `models_test.dart`).*

---

## 5. LaTeX დოკუმენტაციის კომპილაცია

ყველა სამი ფაილი დაკომპილირდა `xelatex`-ით შეცდომების გარეშე:
1. `docs/requirements/anforderungskatalog.tex` $\rightarrow$ `anforderungskatalog.pdf` (11 გვერდი, FR-26 დამატებულია გერმანულ და ინგლისურ ცხრილებში).
2. `docs_ka/anforderungskatalog_ka.tex` $\rightarrow$ `anforderungskatalog_ka.pdf` (8 გვერდი, FR-26 დამატებულია ქართულ ცხრილში).
3. `docs_ka/dokumentacia.tex` $\rightarrow$ `dokumentacia.pdf` (12 გვერდი, დამატებულია ქვეთავი „მონაცემთა სისრულის შემოწმება და ხარვეზების აღმოჩენა (FR-26)“).

---

## 6. წინადადება `THESIS_KNOWLEDGE_BASE.md`-ის განახლებისთვის (შეთავაზება)

`GEMINI.md`-ის წესების მკაცრი დაცვით, `THESIS_KNOWLEDGE_BASE.md` პირდაპირ არ შეცვლილა. წარმოდგენილია შემდეგი წინადადება განსახილველად:

### §5 (SYSTEM_CAPABILITIES) განყოფილებაში დასამატებელი პუნქტი:
> **VERIFIED 2026-11-01:** System automatically performs column-wise data completeness and temporal gap detection on integrated datasets (FR-26, A18). Computes completeness percentages, consecutive missing ranges, and assigns deterministic reasons (`outside_source_coverage`, `gaps_inside_source`, `not_provided_by_source`, `unknown`). The UI presents interactive actions to search alternative sources or pre-fill available dates without automatic gap-filling (A20). Excludes lag-buffer periods from coverage analysis.

### §10 (DECISION_LOG) განყოფილებაში დასამატებელი ჩანაწერი:
> - **2026-11-01 (Task E / A18):** Implemented temporal gap detection (`services/coverage.py`, `DataCoverageCard`). In accordance with A20 and Clarke et al. (2024), gaps are never filled with synthetic or copied data. When data is missing, users are offered deterministic explanations and direct search actions for alternative verified sources (WHO GHO, HDX) or period adjustment.

