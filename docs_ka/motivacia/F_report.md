# დავალება F — ანგარიში: ორი წყაროს შედარება (FR-27, A19)

**ავტორი:** Sergi Koniashvili (LLM-Climate-Health, საბაკალავრო ნაშრომი, ბრემენის უნივერსიტეტი)  
**თარიღი:** 2026-11-01  
**სტატუსი:** სრულად შესრულებულია (Backend, Frontend, ტესტები და დოკუმენტაცია განახლებულია, LaTeX დაკომპილირებულია)

---

## 1. შექმნილი და შეცვლილი ფაილების სია

| ფაილი | ცვლილების ტიპი | აღწერა |
|---|---|---|
| `backend/app/models.py` | შეცვლილი | დაემატა `SourceComparisonRequest`, `SeriesPoint`, `VariableComparison` და `SourceComparisonResponse` Pydantic სქემები. |
| `backend/app/services/source_comparison.py` | **ახალი** | ორი წყაროს შედარების სერვისი: იძახებს `run_integration`-ს `lag_periods=[]`-ით (LLM-ის გარეშე, სწრაფი და დეტერმინისტული), ამოწმებს რეზოლუციების თანხვედრას, ითვლის საერთო პერიოდებზე გადაფარვას ($n$), პირსონის $r$-ს, $p$-მნიშვნელობას (`format_p_value`-ით), საშუალო სხვაობას ($B - A$), MAD-ს, შეფარდებით MAD%-ს და დეტერმინისტულ შეფასებებს (ევრისტიკა: „ძალიან მსგავსი“, „მსგავსი“, „აშკარად განსხვავებული“), სეზონური ციკლისა და ეპიდზედამხედველობის განმარტებით. |
| `backend/app/main.py` | შეცვლილი | დაემატა მარშრუტი `POST /api/compare-sources`. |
| `backend/tests/test_source_comparison.py` | **ახალი** | Unit-ტესტები: იდენტური სერიები ($r=1.0$, $\text{MAD}=0$, `very_similar`), მუდმივი ცდომილება (საშუალო სხვაობა), არათანხვედრი პერიოდების გამორიცხვა, მცირე რაოდენობის წერტილები ($n < 6$, `too_few_points=True`), რეზოლუციის შეუთავსებლობა და კლიმატის სეზონური ციკლის ახსნა. |
| `backend/tests/test_api.py` | შეცვლილი | დაემატა endpoint mock-ტესტები `/api/compare-sources`-ზე (წარმატებული კლიმატის შედარება და ვალიდაციის შემოწმება). |
| `frontend/lib/models/source_comparison.dart` | **ახალი** | Dart მოდელები: `SourceComparisonRequest`, `SeriesPoint`, `VariableComparison`, `SourceComparisonResponse` JSON სერიალიზაციითა და დესერიალიზაციით. |
| `frontend/lib/services/api_client.dart` | შეცვლილი | დაემატა `compareSources(SourceComparisonRequest request)` მეთოდი. |
| `frontend/lib/core/localization.dart` | შეცვლილი | დაემატა ლოკალიზაციის გასაღებები (`compareSources`, `sourceComparisonTitle`, `compareKind`, `alternativeClimateSource`, `compareButton`, `verdictVerySimilar`, `verdictSimilar`, `verdictClearlyDifferent`, `ruleOfThumbNote`, `sharedSeasonalCycleNote`, `caseDefinitionWarning`, `noDatasetChangeNote`, `resolutionMismatchError`) სამ ენაზე (ka, en, de). |
| `frontend/lib/widgets/source_comparison_dialog.dart` | **ახალი** | შედარების ინტერაქტიული მოდალური დიალოგი: წყაროს არჩევა, შედარების ინდიკატორი, `ComparisonSparklinePainter` (ორივე ნორმალიზებული სერიის ვიზუალიზაცია), შეფასების ჩიპი (`Chip`), მეცნიერული განმარტება, გაფართოებადი დეტალური მეტრიკების ცხრილი და მკაფიო გაფრთხილება, რომ ძირითადი მონაცემები არ იცვლება. |
| `frontend/lib/widgets/results_view.dart` | შეცვლილი | გადმოწერის ზოლის (`ReportDownloadBar`) გვერდით დაემატა ღილაკი `Compare sources` (`Icons.compare_arrows`). |
| `frontend/test/source_comparison_dialog_test.dart` | **ახალი** | Widget-ტესტები: დიალოგის ჩატვირთვა, შეფასების ჩიპის, ლეგენდის, მეტრიკებისა და მეცნიერული შენიშვნის ჩვენება. |
| `frontend/test/models_test.dart` | შეცვლილი | დაემატა `SourceComparisonResponse` და `VariableComparison` round-trip ტესტი. |
| `docs/requirements/anforderungskatalog.tex` (+ `.pdf`) | შეცვლილი | დაემატა **FR-27** გერმანულ და ინგლისურ ენებზე (წყარო: *Clarke et al. 2024*); დაკომპილირდა `xelatex`-ით (11 გვერდი). |
| `docs_ka/anforderungskatalog_ka.tex` (+ `.pdf`) | შეცვლილი | დაემატა **FR-27** ქართულად; დაკომპილირდა `xelatex`-ით (8 გვერდი). |
| `docs_ka/dokumentacia.tex` (+ `.pdf`) | შეცვლილი | დაემატა სექცია „ორი მონაცემთა წყაროს ემპირიული შედარება (FR-27, A19)“ ევრისტიკული ზღვრებით, სეზონური ციკლის ახსნითა და A20 პრინციპით; დაკომპილირდა `xelatex`-ით (12 გვერდი). |
| `backend/README.md` | შეცვლილი | აღიწერა `POST /api/compare-sources` და ახალი სერვისი `source_comparison.py`. |
| `frontend/README.md` | შეცვლილი | აღიწერა `source_comparison_dialog.dart` და `source_comparison.dart`. |
| `docs/TESTING_GUIDE.md` | შეცვლილი | განახლდა ტესტების რაოდენობა (174/175 backend, 85 frontend), დაემატა ხელით შემოწმების ნაბიჯი №14 და §7-ში A20 შეზღუდვის დასაბუთება. |
| `docs/thesis/RECOMMENDATIONS.md` | შეცვლილი | A19 მონიშნულია როგორც ✅ 2026-11-01 (Task F: FR-27). |

---

## 2. მომხმარებლის ინტერფეისის ესკიზი (ASCII Sketch)

როდესაც მომხმარებელი შედეგების ხედში გადმოწერის ზოლის გვერდით აჭერს ღილაკს **Compare sources** (`Icons.compare_arrows`), იხსნება მოდალური ფანჯარა:

```text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ 🔄 Compare Data Sources                                                                 │
│                                                                                        │
│ Compare kind: (•) Climate sources    ( ) Disease case sources                          │
│ Current source:  Open-Meteo Historical Archive (ECMWF ERA5 reanalysis)                 │
│ Compare with:    [ NASA POWER (Prediction of Worldwide Energy Resources)          ▼ ]  │
│                                                                                        │
│                                            [ Cancel ]  [ Compare Sources ]             │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ Comparison: Open-Meteo Historical Archive vs. NASA POWER (month, n = 132)              │
│                                                                                        │
│ [ Temperature (mean) ]                                                                 │
│   Verdict: [ ✓ Very similar ]                                                          │
│   "Open-Meteo Historical Archive and NASA POWER move with r = 0.94 (p<0.001);          │
│    NASA POWER is on average 0.21 °C lower."                                            │
│   ──────────────────────────────────────────────────────────────────────────────────   │
│   [Sparkline Chart]                                                                    │
│     ─── Open-Meteo ERA5 (Teal)                                                         │
│     ┈┈┈ NASA POWER (Orange)                                                            │
│     /\    /\    /\    /\    /\    /\    /\    /\    /\    /\    /\                     │
│    /  \  /  \  /  \  /  \  /  \  /  \  /  \  /  \  /  \  /  \  /  \                    │
│   /    \/    \/    \/    \/    \/    \/    \/    \/    \/    \/    \                   │
│   ──────────────────────────────────────────────────────────────────────────────────   │
│   ▸ Detailed Metrics (r = 0.9434, Mean Diff = -0.21 °C, MAD = 0.85 °C, Rel MAD = 3.0%) │
│                                                                                        │
│ [ Precipitation (sum) ]                                                                │
│   Verdict: [ ≈ Similar ]                                                               │
│   "Open-Meteo Historical Archive and NASA POWER move with r = 0.93 (p<0.001);          │
│    NASA POWER is on average 2.69 mm higher."                                           │
│   ▸ Detailed Metrics (r = 0.9330, Mean Diff = +2.69 mm, MAD = 23.28 mm, Rel MAD = 23.4%) │
│                                                                                        │
│ ℹ Rule of thumb, not a statistical test. A high r partly reflects the shared           │
│   seasonal cycle; the mean difference shows the systematic offset.                     │
│ 🔒 Note: This comparison does not change your integrated dataset.                      │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. რეალური ტესტირება: ტაილანდი, დენგე, 2010–2020 (132 თვე)
### ERA5 (Open-Meteo) vs. MERRA-2 (NASA POWER)

გაშვებულია შედარება რეალურ API-ებზე:
- **რეგიონი:** `Thailand`
- **პერიოდი:** `2010-01-01` -- `2020-12-31` (11 წელი = 132 თვე)
- **რეზოლუცია:** `month`
- **წყარო A:** Open-Meteo Historical Archive (ECMWF ERA5 reanalysis)
- **წყარო B:** NASA POWER (MERRA-2)

### მიღებული ემპირიული მეტრიკები:

| ცვლადი | $n$ | Pearson $r$ | $p$-მნიშვნელობა | საშუალო სხვაობა ($B - A$) | MAD | შეფარდებითი MAD% | შეფასება (Verdict) |
|---|---|---|---|---|---|---|---|
| **ტემპერატურა (საშუალო)** | 132 | **0.9434** | $p < 0.001$ | **-0.21 °C** | **0.85 °C** | **3.0%** | **Very similar** |
| **ნალექი (ჯამი)** | 132 | **0.9330** | $p < 0.001$ | **+2.69 მმ** | **23.28 მმ** | **23.4%** | **Similar** |

### მეცნიერული დაკვირვება:
1. **ტემპერატურა:** ორივე წყარო თითქმის იდენტურ დინამიკას აჩვენებს ($r = 0.94$). NASA POWER-ის საშუალო ტემპერატურა ტაილანდისთვის საშუალოდ მხოლოდ 0.21 °C-ით დაბალია ERA5-ზე, ხოლო საშუალო აბსოლუტური სხვაობა (MAD) 0.85 °C-ია (შეფარდებით 3.0%). ევრისტიკით ორივე პირობა ($r \ge 0.90$ და $\text{rel MAD} \le 10\%$) დაკმაყოფილებულია $\rightarrow$ `very_similar`.
2. **ნალექი:** ნალექის სეზონური პიკები და ვარდნები ორივე წყაროში მკაფიოდ სინქრონულია ($r = 0.93$). თუმცა, კონვექციური ნალექების სივრცითი მოდელირების გამო, ექსტრემალურ თვეებში აბსოლუტური სხვაობები შედარებით დიდია ($\text{MAD} = 23.28\text{ მმ}$, შეფარდებითი $\text{MAD} = 23.4\%$). ევრისტიკით დაკმაყოფილებულია მეორე ზღვარი ($r \ge 0.70$ და $\text{rel MAD} \le 25\%$) $\rightarrow$ `similar`.
3. **სეზონური ციკლის ეფექტი:** როგორც მოთხოვნილი იყო, სისტემა მომხმარებელს მკაფიოდ უხსნის: *„A high r partly reflects the shared seasonal cycle; the mean difference shows the systematic offset.“*

---

## 4. შემთხვევების მონაცემთა შედარების არეალი (Cases Comparison Scope)

- **მხარდაჭერილი არხი:** `custom_url` — მომხმარებელს შეუძლია მიუთითოს ალტერნატიული CSV ფაილის URL (მაგალითად HDX-დან ან ადგილობრივი კვლევითი რეპოზიტორიიდან).
- **შეზღუდვა:**
  1. ატვირთული ფაილი (`custom_upload`) შედარების JSON API-ში არ გადაეცემა, რადგან შედარების მოთხოვნა სტანდარტული JSON ობიექტია და არა multipart form.
  2. WHO GHO იძლევა მხოლოდ წლიურ მონაცემებს დენგეზე (ან საერთოდ არ გააჩნია დენგეს თვიური ინდიკატორი ტაილანდისთვის). თუ მომხმარებელი შეეცდება თვიური მონაცემების შედარებას წლიურ WHO GHO-სთან, backend-ი აბრუნებს მკაფიო შეცდომას: `resolution_mismatch = true` („Sources have incompatible temporal resolutions: month vs year. Direct comparison requires the same resolution.“) რიცხვების გამოგონების გარეშე.
- **ეპიდზედამხედველობის გაფრთხილება:** შემთხვევების შედარებისას სისტემა ყოველთვის აჩვენებს გაფრთხილებას:
  > *„Different reporting systems and case definitions (e.g. all cases vs confirmed only) cause systematic differences in level. Focus on trend agreement (r) rather than absolute counts.“*

---

## 5. ავტომატური შევსების გამორიცხვა (A20 პრინციპი)

როგორც `RECOMMENDATIONS.md`-ის A20 პუნქტშია განსაზღვრული:
1. სისტემა **არასდროს** არ ავსებს ერთი წყაროს ხარვეზებს მეორე წყაროს მონაცემებით ავტომატურად.
2. შედარების სერვისი (`compare_sources`) არ ცვლის მომხმარებლის მიერ უკვე ინტეგრირებულ მონაცემთა ცხრილს, კეშს ან ექსპორტის ფაილებს. შედარება არის წმინდად საორიენტაციო, ემპირიული ინსტრუმენტი მკვლევრისთვის.

---

## 6. ტესტირების შედეგები

### Backend (pytest):
```bash
cd backend
.venv\Scripts\python.exe -m pytest -q
```
**შედეგი:** **175 passed in 21.70s** (174 offline, 1 live Open-Meteo call).

### Frontend (flutter test & flutter analyze):
```bash
cd frontend
flutter test
flutter analyze
```
**შედეგი:** **85 passed in 28s**, `No issues found!`.

### LaTeX დოკუმენტაციის კომპილაცია (XeLaTeX):
- `docs/requirements/anforderungskatalog.tex` $\rightarrow$ **anforderungskatalog.pdf** (11 გვერდი, Exit code 0).
- `docs_ka/anforderungskatalog_ka.tex` $\rightarrow$ **anforderungskatalog_ka.pdf** (8 გვერდი, Exit code 0).
- `docs_ka/dokumentacia.tex` $\rightarrow$ **dokumentacia.pdf** (12 გვერდი, Exit code 0).

---

## 7. წინადადებები `THESIS_KNOWLEDGE_BASE.md`-სთვის (Proposed Updates)

> *შენიშვნა: წესების დაცვით, `THESIS_KNOWLEDGE_BASE.md` უშუალოდ არ ჩასწორებულა; ქვემოთ წარმოდგენილია შეთავაზებული ცვლილებები:*

### შეთავაზება §5-ისთვის (Implemented Features):
```markdown
- **Source comparison (FR-27 / A19):** Empirical comparison of two climate sources (ERA5 vs NASA POWER) or case sources over the overlapping period. Reports Pearson r, formatted p-value, mean difference, Mean Absolute Difference (MAD), relative MAD%, sparkline visualization, and deterministic heuristic verdicts ("very similar", "similar", "clearly different"). Includes scientific disclaimer on seasonal cycle and surveillance definition differences. Purely analytical: does not mutate the main dataset, cache, or export.
```

### შეთავაზება §10-ისთვის (Decision Log):
```markdown
- **Decision (2026-11-01, Task F / A19):** Alternative source comparison uses heuristic rule-of-thumb thresholds (r >= 0.90 & rel MAD <= 10% -> "very similar"; r >= 0.70 & rel MAD <= 25% -> "similar"), labeled clearly as "Rule of thumb, not a statistical test". In accordance with Clarke et al. 2024, climate comparisons explain that high r partly reflects the shared annual seasonal cycle. Automatic gap filling across sources (A20) is deliberately excluded to prevent mixing incompatible case definitions or temporal resolutions.
```

---

## 8. შემდეგი ნაბიჯები (Follow-ups)

1. **PDF ექსპორტში შედარების ანგარიშის ბლოკის დამატება:** მომხმარებლის მოთხოვნით, თუ შედარება ჩატარდა, PDF ანგარიშში შეიძლება დაემატოს შედარების ცხრილი (Follow-up to A16).
2. **დამატებითი კლიმატის წყაროების მხარდაჭერა:** ტაილანდის რეგიონისთვის TMD-ის (Thai Meteorological Department) შედარება ERA5-თან, როდესაც სრული ისტორიული API წვდომა დარეგისტრირდება.

