# დავალება F2 — ანგარიში: წყაროების შედარების გაფართოება (FR-27 გაფართოება, A19)

**ავტორი:** Sergi Koniashvili (LLM-Climate-Health, საბაკალავრო ნაშრომი, ბრემენის უნივერსიტეტი)  
**თარიღი:** 2026-11-01  
**სტატუსი:** სრულად შესრულებულია (Backend, Frontend, ტესტები და დოკუმენტაცია განახლებულია, LaTeX დაკომპილირებულია)

---

## 1. შეჯამება და დავალების მოთხოვნები

დავალება F2-მა გააფართოვა წყაროების ემპირიული შედარების ფუნქციონალი (FR-27 / A19): მომხმარებელს აღარ უწევს ალტერნატიული წყაროსთვის მხოლოდ URL-ის ხელით ჩაწერა. წყარო B-ს ასარჩევად დაინერგა მოქნილი ინტერფეისი და ბექენდ-მხარდაჭერა:

1. **დაავადების შემთხვევების წყარო B:**
   - **WHO GHO ინდიკატორი:** ინდიკატორის მოძიება და შერჩევა არსებული `GET /api/search-case-sources` ენდპოინტის მეშვეობით (გამოყენებულია არსებული `SourceSearchDialog`).
   - **წლიური შედარება და სრული კალენდარული წლების პრინციპი:** WHO GHO მონაცემები ყოველწლიურია, ამიტომ ორივე წყაროს გაშვება ხდება წლიურ დონეზე (`aggregation="yearly"`). აკრძალულია წლიური მონაცემების თვეებად ხელოვნური დეზაგრეგაცია. საბაზისო მონაცემებიდან (მაგ. OpenDengue) შეჯამდება მხოლოდ ის კალენდარული წლები, სადაც მოთხოვნილ ინტერვალში წარმოდგენილია 12-ვე სრული თვე. არასრული წლები (მაგ. საწყისი/საბოლოო არასრული პერიოდი ან შიდა ხარვეზი) გამოირიცხება ხელოვნურად შემცირებული ჯამების თავიდან ასაცილებლად, აისახება `excluded_years` ველში და ეცნობება მომხმარებელს. თუ $n < 6$, ჩნდება გაფრთხილება მცირე რაოდენობის წერტილების შესახებ.
   - **Custom URL:** პირდაპირი ბმული CSV ფაილზე.
   - **ლოკალური CSV ფაილის ატვირთვა:** მულტიპარტ ენდპოინტის საშუალებით.
2. **კლიმატის წყარო B:**
   - Open-Meteo ERA5, NASA POWER MERRA-2, TMD (მხოლოდ მაშინ, როცა API გასაღებები კონფიგურირებულია და რეგიონი ტაილანდია — იმალება სხვა შემთხვევაში `/api/options`-ის `tmd_configured` დროშით), და ლოკალურად ატვირთული კლიმატის CSV ფაილი.
3. **ახალი მულტიპარტ ენდპოინტი `POST /api/compare-sources/upload`:**
   - იღებს ფორმის ველს `request` (JSON სტრიქონი, მოწმდება `SourceComparisonRequest`-ით) და `file: UploadFile` (CSV ფაილი).
   - იყენებს არსებულ ატვირთვის პარსერებს (`get_case_data_from_upload` და `climate_upload_content`).
   - ფაილი მუშავდება მხოლოდ ოპერატიულ მეხსიერებაში და არ ინახება.
   - ლიმიტი: `_MAX_UPLOAD_BYTES` (10 MB, გადაცილებაზე 413). თუ თავად წყარო A იყო ატვირთული ფაილი, ბრუნდება მკაფიო 400 შეცდომა.
4. **დაუცველი პრინციპები F-დან:**
   - `run_integration` გამოიძახება პირდაპირ, `lag_periods=[]`, LLM-ის გარეშე (სწრაფი და დეტერმინისტული, 0 Gemini კვოტა).
   - მთავარი ქეში და ექსპორტი რჩება სრულიად ხელუხლებელი.
   - არანაირი „significant“ იარლიყი, $p$-value ფორმატირებულია `format_p_value`-ით.

---

## 2. შექმნილი და შეცვლილი ფაილების სია

| ფაილი | ცვლილების ტიპი | აღწერა |
|---|---|---|
| `backend/app/models.py` | შეცვლილი | `SourceComparisonRequest`-ში `alternative_climate_source` და `alternative_case_data_source` იღებენ `"custom_upload"` მნიშვნელობას; `SourceComparisonResponse`-ს დაემატა `compared_at_yearly_resolution: bool` და `excluded_years: list[str]`. |
| `backend/app/services/source_comparison.py` | შეცვლილი | რეალიზებულია WHO GHO-ს სრული წლების შემოწმებისა და ფილტრაციის ლოგიკა (`excluded_years`), წლიური შედარება, და `upload_file_b_bytes` გადაცემა `run_integration`-ში. |
| `backend/app/main.py` | შეცვლილი | `/api/options` აბრუნებს `tmd_configured: bool`; დაემატა მულტიპარტ ენდპოინტი `POST /api/compare-sources/upload` (მაქს. 10 MB, წყარო A-ს შემოწმება). |
| `backend/tests/test_source_comparison.py` | შეცვლილი | დაემატა ტესტები: WHO GHO სრული წლების გამოთვლა (2010-03..2012-12 ტოვებს 2011-2012-ს, 2010 გამოირიცხება), ატვირთული CSV წყარო B-სთვის კლიმატსა და შემთხვევებზე. |
| `backend/tests/test_api.py` | შეცვლილი | დაემატა `import json`, დაემატა ტესტები `/api/compare-sources/upload`-ზე: წარმატებული ატვირთვა, ატვირთული წყარო A-ს უარყოფა (400), და 10 MB-ზე დიდი ფაილის უარყოფა (413). |
| `frontend/lib/models/platform_options.dart` | შეცვლილი | დაემატა `tmdConfigured: bool` (default: false). |
| `frontend/lib/models/source_comparison.dart` | შეცვლილი | დაემატა `comparedAtYearlyResolution` და `excludedYears`. |
| `frontend/lib/services/api_client.dart` | შეცვლილი | დაემატა `compareSourcesWithUpload` `http.MultipartRequest`-ის გამოყენებით. |
| `frontend/lib/core/localization.dart` | შეცვლილი | დაემატა თარგმანები ka, en, de ენებზე: წყარო B-ს ტიპები, WHO GHO ძებნა, ფაილის არჩევა/ატვირთვა, წლიური რეზოლუციის ბანერი, გამორიცხული წლები და მცირე რაოდენობის გაფრთხილება. |
| `frontend/lib/widgets/source_comparison_dialog.dart` | შეცვლილი | დაემატა წყარო B-ს სელექტორები (WHO GHO ძებნა `SourceSearchDialog`-ით, Custom URL, FilePicker ატვირთვა), TMD ხილვადობის შემოწმება (`options.tmdConfigured` და რეგიონი ტაილანდი), წლიური რეზოლუციისა და გამორიცხული წლების ბანერები. |
| `frontend/lib/widgets/results_view.dart` | შეცვლილი | `PlatformOptions options` გადაეცემა `SourceComparisonDialog`-ს. |
| `frontend/lib/pages/home_page.dart` | შეცვლილი | `_options` გადაეცემა `ResultsView`-ს. |
| `frontend/test/models_test.dart` | შეცვლილი | შემოწმდა მოდელების დესერიალიზაცია ახალი ველებით. |
| `frontend/test/source_comparison_dialog_test.dart` | შეცვლილი | დაემატა ვიჯეტ-ტესტები: წყარო B-ს სელექტორების გადართვა შემთხვევებზე, წლიური რეზოლუციის ბანერისა და გამორიცხული წლების გამოჩენა, დეტალური მეტრიკების ჩაშლა. |
| `docs/requirements/anforderungskatalog.tex` (+ `.pdf`) | შეცვლილი | გაფართოვდა **FR-27** (DE და EN): WHO GHO სრული წლები, CSV ატვირთვა, TMD კონფიგურაციის შემოწმება. დაკომპილირდა `xelatex`-ით (13 გვერდი). |
| `docs_ka/anforderungskatalog_ka.tex` (+ `.pdf`) | შეცვლილი | გაფართოვდა **FR-27** (KA): დაემატა WHO GHO წლიური შედარება, მულტიპარტ ატვირთვა `POST /api/compare-sources/upload`. დაკომპილირდა `xelatex`-ით (9 გვერდი). |
| `docs_ka/dokumentacia.tex` (+ `.pdf`) | შეცვლილი | განახლდა FR-27 ქვეთავი: წყარო B-ს მოქნილი კონფიგურაცია, WHO GHO წლიური შედარება სრული წლების შემოწმებით (`excluded_years`), მულტიპარტ ატვირთვის ენდპოინტი. დაკომპილირდა `xelatex`-ით (13 გვერდი). |
| `backend/README.md` | შეცვლილი | დაემატა `POST /api/compare-sources/upload` ენდპოინტი და წყარო B-ს გაფართოებული შესაძლებლობების აღწერა. |
| `docs/TESTING_GUIDE.md` | შეცვლილი | განახლდა ტესტების რაოდენობა (183/184 backend, 88 frontend), ენდპოინტების სია და შედარების ნაბიჯი №14. |
| `docs/thesis/RECOMMENDATIONS.md` | შეცვლილი | A19 განახლდა: მონიშნულია როგორც ✅ 2026-11-01 (Task F & F2: FR-27). |

---

## 3. მომხმარებლის ინტერფეისის ესკიზი (ASCII Sketch)

### შემთხვევათა შედარება WHO GHO ინდიკატორთან (წლიური რეზოლუცია, გამორიცხული არასრული წლებით)

```text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ 🔄 Compare Data Sources (FR-27)                                                    [X] │
│ Compare kind: [ Climate sources ] [ • Disease/Case Sources ]                           │
│                                                                                        │
│ Source B type: (•) WHO GHO Indicator   ( ) URL   ( ) Upload CSV file                   │
│ [ 🔍 Search & pick WHO indicator ] Selected: Dengue - reported cases                   │
│ ℹ WHO GHO data is annual. Both sources will be compared at yearly resolution.           │
│                                            [ Cancel ]  [ Compare Sources ]             │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ 📅 Compared at yearly resolution: Both sources were aggregated to annual totals.       │
│    Excluded incomplete years (missing months in baseline): 2010                        │
│                                                                                        │
│ Dengue Cases (annual)                                            [ Similar ]           │
│ "OpenDengue and WHO GHO move with r = 0.88 (p = 0.02); WHO GHO is on average 142       │
│  cases lower."                                                                         │
│ ────────────────────────────────────────────────────────────────────────────────────── │
│ [Sparkline Chart: 2011-2012 annual trends]                                             │
│   ─── OpenDengue (Teal)      ┈┈┈ WHO GHO (Orange)                                      │
│ ────────────────────────────────────────────────────────────────────────────────────── │
│ ⚠️ Few data points available (n = 2 years). Interpret correlation with caution.        │
│                                                                                        │
│ ▸ Detailed metrics (n = 2)                                                             │
│   ┌──────────────────────────────────────────────┬─────────────────────────────────┐   │
│   │ Number of overlapping points (n)             │ 2                               │   │
│   │ Pearson correlation (r)                      │ 0.8812                          │   │
│   │ p-value                                      │ p = 0.020                       │   │
│   │ Mean difference (B - A)                      │ -142.00                         │   │
│   │ Mean absolute difference (MAD)               │ 142.00                          │   │
│   │ Relative MAD (%)                             │ 8.4%                            │   │
│   └──────────────────────────────────────────────┴─────────────────────────────────┘   │
│ ℹ Rule of thumb, not a statistical test. Surveillance definitions may differ.          │
│ 🔒 Note: This comparison does not change your integrated dataset or cache.             │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. ტესტირების შედეგები

### 4.1 Backend Pytest (სრული Suite)
გაშვებულია სრული ტესტების პაკეტი:
```bash
python -m pytest -q
```
**შედეგი:**
```text
184 passed, 1 warning in 16.56s
```
ყველა 184 ტესტი წარმატებით გადის. მათ შორის ახალი დავალების F2 ტესტები:
- `test_compare_sources_who_gho_complete_years_only`: შემოწმდა ინტერვალი `2010-03..2012-12` (2010 წელს მხოლოდ 10 თვეა, ამიტომ 2010 გამოირიცხება და მხოლოდ 2011 და 2012 შედარდება, $n = 2$).
- `test_compare_sources_case_upload_source_b`: შემოწმდა შემთხვევათა ლოკალური CSV ატვირთვა წყარო B-დ.
- `test_compare_sources_climate_upload_source_b`: შემოწმდა კლიმატის ლოკალური CSV ატვირთვა წყარო B-დ.
- `test_compare_sources_upload_endpoint_success`: შემოწმდა `POST /api/compare-sources/upload` წარმატებული შესრულება.
- `test_compare_sources_upload_rejects_upload_as_source_a`: წყარო A-ს ატვირთვისას ბრუნდება HTTP 400.
- `test_compare_sources_upload_rejects_oversized_file`: 10 MB-ზე მეტ ფაილზე ბრუნდება HTTP 413.

### 4.2 Frontend Flutter Tests
გაშვებულია ვიჯეტ- და იუნიტ-ტესტები:
```bash
flutter test
```
**შედეგი:**
```text
00:17 +88: All tests passed!
```
ყველა 88 ტესტი წარმატებით გადის. `flutter analyze` არ აჩვენებს არცერთ შეცდომას აპლიკაციის კოდში.

---

## 5. ცოდნის ბაზის შემოთავაზებული განახლება (`docs/thesis/THESIS_KNOWLEDGE_BASE.md`)

> **წესი:** §0-ის თანახმად, ცოდნის ბაზა პირდაპირ არ იცვლება; ცვლილებები შემოთავაზებულია განსახილველად.

### შემოთავაზება §2-ისთვის (Verified System Capabilities):
```markdown
- **Source Comparison (FR-27 / A19 / Task F & F2):**
  The platform provides deterministic empirical comparison between two data sources over their overlapping period via `POST /api/compare-sources` (JSON) and `POST /api/compare-sources/upload` (multipart CSV upload, max 10 MB).
  Source B options:
  - Climate: Open-Meteo ERA5, NASA POWER MERRA-2, TMD (only shown when configured in platform options for Thailand), or uploaded climate CSV.
  - Disease cases: WHO GHO indicators (discovered via `/api/search-case-sources`), custom CSV URL, or uploaded disease cases CSV.
  When comparing against WHO GHO, both sources are evaluated at yearly resolution. In accordance with data integrity principles, OpenDengue monthly baseline records are aggregated only for complete calendar years (all 12 months present in the requested window); incomplete years are excluded, recorded in `excluded_years`, and presented to the user. No disaggregation from annual to monthly data is performed. Comparisons run directly via `run_integration` with `lag_periods=[]`, bypassing LLM generation for zero Gemini quota consumption, leaving primary dataset, cache, and export unaffected.
```

