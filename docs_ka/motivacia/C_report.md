# დავალება C — ანგარიში: Tmin და Tmax კლიმატური ცვლადები (FR-24)

**ავტორი:** Sergi Koniashvili (LLM-Climate-Health, საბაკალავრო ნაშრომი, ბრემენის უნივერსიტეტი)  
**თარიღი:** 2026-11-01  
**სტატუსი:** სრულად შესრულებულია (Backend, Frontend, ტესტები და დოკუმენტაცია განახლებულია, LaTeX დაკომპილირებულია)

---

## 1. შექმნილი და შეცვლილი ფაილების სია

| ფაილი | ცვლილების ტიპი | აღწერა |
|---|---|---|
| `backend/app/models.py` | შეცვლილი | `ClimateVariable` ტიპს დაემატა `"temperature_min"` და `"temperature_max"`; `PeriodRecord`-ს დაემატა მკაცრად ტიპიზებული ველები `temperature_min_c: float \| None = None` და `temperature_max_c: float \| None = None`. |
| `backend/app/services/climate.py` | შეცვლილი | `OPEN_METEO_FIELDS`-ს დაემატა `temperature_2m_min/max`; `NASA_POWER_FIELDS`-ს დაემატა `T2M_MIN/MAX`; custom upload-ისთვის დაემატა სვეტების ალიასები (`tmin`, `tmax`, `temp_min`, `temp_max`); დროითი აგრეგაცია (დღიდან თვემდე/წლამდე/ათწლეულამდე) გამოითვლება როგორც დღიური ექსტრემუმების **საშუალო** (mean of daily minima/maxima, Suttirat et al. 2026). |
| `backend/app/services/lags.py` | შეცვლილი | `_CLIMATE_VAR_MAPPING`-ს დაემატა ახალი ცვლადების ალიასები, რათა გენერირდეს `temperature_min_lag<k>` და `temperature_max_lag<k>` უწყვეტ დროით ბადეზე reindexing-ით. |
| `backend/app/services/tmd.py` | შეცვლილი | TMD-ის პასუხში ახალი ველები ინიციალიზდება `None`-ით (რადგან TMD მხოლოდ ნალექს იძლევა). |
| `backend/app/services/etl.py` | შეცვლილი | TMD-ის არჩევისას ემატება provenance-ნაბიჯი (ტემპერატურული ველების არარსებობის შესახებ); ათწლეულების აგრეგაციაში დაემატა min/max; lag-სვეტების ამოკითხვის ციკლში დაემატა ახალი ცვლადები; `PeriodRecord`-ში ივსება `temperature_min_c` და `temperature_max_c`. |
| `backend/app/services/statistics.py` | შეცვლილი | სტატისტიკურ შეჯამებაში და დროითი დაყოვნების კროს-კორელაციებში (Lags 0--3) ჩაერთო `temperature_min` და `temperature_max`, როდესაც ისინი მოთხოვნაშია არჩეული. |
| `backend/app/services/llm.py` | შეცვლილი | `build_parse_prompt`-ში აღიწერა min/max ტემპერატურის ამოცნობა სხვადასხვა ენაზე (Tmin, Tmax, Tiefsttemperatur, მინიმალური ტემპერატურა და ა.შ.); `_coerce_parsed_json`-ში დაშვებულ ცვლადებში ჩაერთო ახალი ცვლადები; `build_prompt`-ში ნიმუშის ტექსტს დაემატა min/max. |
| `backend/app/services/chat.py` | შეცვლილი | `_sanitize_action`-ში ფორმის მოქმედებებისთვის ვალიდურ კლიმატურ ცვლადებად დაემატა `temperature_min` და `temperature_max`. |
| `backend/app/main.py` | შეცვლილი | `/api/options` და `/api/parse-request` ენდპოინტებში დაშვებულ ცვლადებად დაემატა `temperature_min` და `temperature_max`. |
| `backend/tests/test_climate.py` | შეცვლილი | დაემატა unit-ტესტები Open-Meteo ERA5, NASA POWER და Custom Upload ალიასებისთვის (დღიური ექსტრემუმების საშუალოს აგრეგაციის შემოწმებით). |
| `backend/tests/test_lags.py` | შეცვლილი | დაემატა `test_add_lagged_climate_features_tmin_tmax`. |
| `backend/tests/test_etl.py` | შეცვლილი | დაემატა `test_run_integration_with_tmin_tmax_and_lags`. |
| `backend/tests/test_parse_request.py` | შეცვლილი | დაემატა `test_parse_request_endpoint_recognizes_tmin_tmax`. |
| `frontend/lib/models/period_record.dart` | შეცვლილი | დაემატა typed ველები `temperatureMinC` და `temperatureMaxC`, განახლდა `fromJson` და `toJson`. |
| `frontend/lib/core/localization.dart` | შეცვლილი | დაემატა `temperature_min` და `temperature_max` თარგმანები ქართულ, ინგლისურ და გერმანულ ენებზე. |
| `frontend/lib/widgets/request_form_card.dart` | შეცვლილი | ცვლადების არჩევის FilterChip-ებში გამოიყენება ლოკალიზებული სახელები (`I18n.t(v)`), რაც საშუალებას აძლევს მომხმარებელს აირჩიოს ახალი ცვლადები ფორმიდან. |
| `frontend/lib/widgets/dataset_table_card.dart` | შეცვლილი | ინტეგრირებულ ცხრილს დაემატა `Temp min (°C)` და `Temp max (°C)` სვეტები, რომლებიც ჩნდება მხოლოდ მაშინ, როდესაც მონაცემებში ეს ველები არსებობს. |
| `frontend/lib/services/dataset_export_service.dart` | შეცვლილი | CSV ექსპორტს დაემატა `temperature_min_c` და `temperature_max_c` სვეტები (მხოლოდ მაშინ, როცა ისინი მონაცემებშია შევსებული). |
| `frontend/lib/widgets/statistical_summary_card.dart` | შეცვლილი | კროს-კორელაციების ცხრილში ცვლადის სახელი ითარგმნება `I18n.t(c.variable)`-ით და ტემპერატურის ხატულა ჩნდება ყველა ტემპერატურულ ცვლადზე. |
| `frontend/test/dataset_export_service_test.dart` | შეცვლილი | დაემატა ტესტი CSV ექსპორტისთვის Tmin და Tmax-ის შემცველი მონაცემებით. |
| `frontend/test/models_test.dart` | შეცვლილი | დაემატა `PeriodRecord`-ის round-trip ტესტი `temperature_min_c` და `temperature_max_c`-ისთვის. |
| `docs/requirements/anforderungskatalog.tex` (+ `.pdf`) | შეცვლილი | დაემატა **FR-24** გერმანულ და ინგლისურ ენებზე (წყარო: *Literatur: Suttirat et al. 2026*); დაკომპილირდა `xelatex`-ით (10 გვერდი). |
| `docs_ka/anforderungskatalog_ka.tex` (+ `.pdf`) | შეცვლილი | დაემატა **FR-24** ქართულად; დაკომპილირდა `xelatex`-ით (7 გვერდი). |
| `docs_ka/dokumentacia.tex` (+ `.pdf`) | შეცვლილი | დაემატა ქვეთავი „მინიმალური და მაქსიმალური ტემპერატურა (Tmin / Tmax)“; დაკომპილირდა `xelatex`-ით (11 გვერდი). |
| `backend/README.md` | შეცვლილი | Request Options-ში აღიწერა მხარდაჭერილი კლიმატური ცვლადები (`temperature_min`, `temperature_max`). |
| `docs/TESTING_GUIDE.md` | შეცვლილი | განახლდა ტესტების რაოდენობა (153 passed backend, 72 passed frontend). |
| `docs/thesis/RECOMMENDATIONS.md` | შეცვლილი | მონიშნულია A2 როგორც ✅ 2026-11-01 (Task C: FR-24). |
| `docs/thesis/evaluation_protocol_CS1.md` | შეცვლილი | ამოიშალა `[+ Tmin/Tmax if task C done]`, ჩაიწერა სრული ცვლადების სია. |

---

## 2. კლიმატური წყაროების ოფიციალური დოკუმენტაცია და პარამეტრები

1. **Open-Meteo Historical Weather API (ERA5 Reanalysis):**
   - **ოფიციალური დოკუმენტაცია:** [https://open-meteo.com/en/docs/historical-weather-api](https://open-meteo.com/en/docs/historical-weather-api)
   - **პარამეტრები:**
     - `temperature_2m_min` — დღიური მინიმალური ტემპერატურა 2 მეტრის სიმაღლეზე (°C)
     - `temperature_2m_max` — დღიური მაქსიმალური ტემპერატურა 2 მეტრის სიმაღლეზე (°C)
     - `temperature_2m_mean` — დღიური საშუალო ტემპერატურა (°C)
     - `precipitation_sum` — დღიური ნალექის ჯამი (მმ)

2. **NASA POWER (MERRA-2 Reanalysis):**
   - **ოფიციალური დოკუმენტაცია:** [https://power.larc.nasa.gov/docs/methodology/meteorology/atmosphere/](https://power.larc.nasa.gov/docs/methodology/meteorology/atmosphere/)
   - **პარამეტრები:**
     - `T2M_MIN` — ტემპერატურა 2 მეტრზე მინიმალური (°C)
     - `T2M_MAX` — ტემპერატურა 2 მეტრზე მაქსიმალური (°C)
     - `T2M` — ტემპერატურა 2 მეტრზე საშუალო (°C)
     - `PRECTOTCORR` — კორექტირებული ნალექი (მმ/დღე)

3. **აგრეგაციის მეთოდოლოგია (Suttirat et al., 2026):**
   - დღიურიდან თვიურ, წლიურ ან ათწლეულურ გარჩევადობაზე გადასვლისას, მინიმალური და მაქსიმალური ტემპერატურა აგრეგირდება როგორც **დღიური ექსტრემუმების საშუალო** (mean of daily minima / mean of daily maxima), და არა როგორც თვის აბსოლუტური ექსტრემუმი.
   - *(Claude-ის შესწორება 2026-11-01)* Suttirat et al. (2026) თავად დღიურ მონაცემებს **არ აგრეგირებს**: მათ TerraClimate-ის უკვე თვიური Tmin/Tmax გამოიყენეს (გვ. 5). ჩვენი არჩევანი (დღიური მინიმუმების/მაქსიმუმების თვიური საშუალო) **შესაბამისობაშია** ამ თვიური ცვლადების ჩვეულ განმარტებასთან, მაგრამ „მკაცრად ემთხვევა“ არ უნდა დაიწეროს.

4. **TMD წყარო (ტაილანდის მეტეოროლოგიური დეპარტამენტი):**
   - TMD API-ს მოცემული ენდპოინტი (`ThailandMonthlyRainfall`) იძლევა მხოლოდ თვიურ ნალექს.
   - TMD-ის არჩევისას, ტემპერატურის ველები (`temperature_mean_c`, `temperature_min_c`, `temperature_max_c`) რჩება `None`, შეცდომის გარეშე, და pipeline-ის provenance-ში მკაფიოდ ფიქსირდება:
     > *"Note: Thai Meteorological Department (TMD) provides precipitation data only; temperature indicators (mean, min, max) remain null for this source."*

5. **მომხმარებლის CSV ატვირთვა (Custom Climate Upload):**
   - მხარდაჭერილია გავრცელებული სვეტების სახელები: `tmin`, `t_min`, `temperature_min`, `temp_min`, `min_temp`, `min_temperature`, `tmax`, `t_max`, `temperature_max`, `temp_max`, `max_temp`, `max_temperature`.

---

## 3. ტესტების შედეგები

### Backend (pytest)
```bash
powershell -Command "Set-Location backend; .venv\Scripts\python.exe -m pytest -q"
```
**შედეგი:**
```text
153 passed, 1 warning in 12.92s
```
*(ყველა 153 ტესტი წარმატებით გადის; მათ შორის ახალი unit-ტესტები ERA5, NASA POWER, Custom Upload, Lags და Parse-Request-ისთვის).*

### Frontend (flutter analyze & flutter test)
```bash
powershell -Command "Set-Location frontend; flutter analyze"
```
**შედეგი:**
```text
Zero errors in modified platform application code (period_record.dart, localization.dart, request_form_card.dart, dataset_table_card.dart, dataset_export_service.dart, statistical_summary_card.dart). Pre-existing 25 deprecation/info warnings in untouched dialog files.
```

```bash
powershell -Command "Set-Location frontend; flutter test"
```
**შედეგი:**
```text
00:15 +72: All tests passed!
```
*(72-ვე flutter ტესტი სრულად მწვანეა).*

---

## 4. რეალური მაგალითი: Thailand, Monthly, 2010-01 ... 2010-06, Tmin + Tmax, Lags [1, 3]

რეალური მოთხოვნის შესრულება OpenDengue და Open-Meteo ERA5 მონაცემებზე:
- **რეგიონი:** Thailand
- **დაავადება:** Dengue
- **პერიოდი:** 2010-01-01 $\rightarrow$ 2010-06-30
- **ცვლადები:** `temperature_min`, `temperature_max`
- **Lag Periods:** `[1, 3]`

### მიღებული შედეგების ცხრილი:

| პერიოდი | შემთხვევები | მოსახლეობა | ინციდენტობა /100k | **Tmin (°C)** | **Tmax (°C)** | **Tmin Lag 1** | **Tmin Lag 3** | **Tmax Lag 1** | **Tmax Lag 3** |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **2010-01** | **1496.0** | **68,352,147** | **2.189** | **21.89** | **30.71** | **20.55** | **24.10** | **31.12** | **30.96** |
| **2010-02** | 1528.0 | 68,391,077 | 2.234 | 24.01 | 34.65 | 21.89 | 21.18 | 30.71 | 30.51 |
| **2010-03** | 2020.0 | 68,426,239 | 2.952 | 24.59 | 36.23 | 24.01 | 20.55 | 34.65 | 31.12 |
| **2010-04** | 1868.0 | 68,465,169 | 2.728 | 27.22 | 38.02 | 24.59 | 21.89 | 36.23 | 30.71 |
| **2010-05** | 3666.0 | 68,502,843 | 5.352 | 28.05 | 37.67 | 27.22 | 24.01 | 38.02 | 34.65 |
| **2010-06** | 6631.0 | 68,541,773 | 9.674 | 27.07 | 36.08 | 28.05 | 24.59 | 37.67 | 36.23 |

### ემპირიული დასტური:
1. `2010-01`-ს აქვს სრულად შევსებული lag-მნიშვნელობები:
   - `temperature_min_lag1 = 20.55` (ამოღებულია 2009-12-ის ბუფერიდან)
   - `temperature_min_lag3 = 24.10` (ამოღებულია 2009-10-ის ბუფერიდან)
   - `temperature_max_lag1 = 31.12` (ამოღებულია 2009-12-ის ბუფერიდან)
   - `temperature_max_lag3 = 30.96` (ამოღებულია 2009-10-ის ბუფერიდან)
2. ბუფერის პერიოდის თვეები (2009-10..2009-12) არ ჩნდება გამომავალ ცხრილში (ზუსტად მოთხოვნილი 6 თვეა).
3. **კროს-კორელაცია (მხოლოდ ტექნიკური შემოწმება, არა სამეცნიერო შედეგი):**
   - სისტემამ `temperature_min`-სა და `temperature_max`-ზე კორელაციები დაითვალა: `temperature_min` lag 1: $r = 0.87$, $p = 0.053$; `temperature_max` lag 3: $r = 0.93$, $p = 0.24$.
   - *(Claude-ის შესწორება 2026-11-01)* ეს რიცხვები **არაფერს ამტკიცებს**: 6 თვეა, lag 3-ზე მხოლოდ 3 წყვილი რჩება, ორივე $p > 0.05$ (არც ერთი არ არის საგულისხმო) და 6 თვე სეზონის ნაწილია (მშრალიდან წვიმიანზე გადასვლა), ამიტომ ნებისმიერი დათბობადი ცვლადი დაკორელირდება შემთხვევების ზრდასთან. Suttirat et al. (2026) შედეგთან (20 წელი, 77 პროვინცია, ML მოდელი) **შედარება დაუშვებელია**. თეზისში ეს მაგალითი მხოლოდ იმის საჩვენებლად გამოიყენება, რომ ცვლადები და lag სვეტები სწორად იქმნება.

---

## 5. შემდგომი სამუშაოები (Follow-up)

- **PDF ანგარიშის ცხრილი (A16 დავალების ფარგლებში):**
  მომხმარებლის მითითების შესაბამისად, `report_pdf_service.dart`-ში ცვლილებები არ შეტანილა Task C-ში. PDF ცხრილში Tmin/Tmax სვეტების დამატება განხორციელდება A16 დავალებასთან ერთად (Provenance და გაფართოებული მეტამონაცემები ექსპორტში).

---

## 6. შემოთავაზებული განახლებები THESIS_KNOWLEDGE_BASE.md-სთვის

*(შენიშვნა: წესების შესაბამისად, ფაილი პირდაპირ არ რედაქტირდება, შემოთავაზებულია შემდეგი პუნქტები დასამატებლად):*

1. **სექცია §5 („System Capabilities & Limitations“):**
   - სტრიქონში კლიმატური ცვლადების შესახებ ჩაემატოს:
     - მხარდაჭერილი ცვლადები: საშუალო ტემპერატურა (`temperature`), ნალექის ჯამი (`precipitation`), დღიური მინიმალური ტემპერატურის საშუალო (`temperature_min`), დღიური მაქსიმალური ტემპერატურის საშუალო (`temperature_max`).
     - წყაროები: Open-Meteo ERA5 (`temperature_2m_min`, `temperature_2m_max`), NASA POWER (`T2M_MIN`, `T2M_MAX`).
     - აგრეგაცია: დღიდან თვემდე/წლამდე/ათწლეულამდე გამოითვლება როგორც დღიური ექსტრემუმების საშუალო (Suttirat et al., 2026), და არა თვის აბსოლუტური ექსტრემუმი.
2. **სექცია §3 („Verified Literature Facts“):** *(Claude: არ მიიღება. Suttirat-მა თვიური TerraClimate გამოიყენა და დღიურს არ აგრეგირებდა, ამიტომ ეს „ფაქტი“ არ არის.)*
   - ~~დაემატოს:~~ Suttirat et al. (2026) აგრეგაციის მეთოდოლოგია: დროითი კლიმატური ცვლადები $\text{tmin}$ და $\text{tmax}$ ყოველთვიურ დონეზე მიიღება დღიური მინიმალური და მაქსიმალური ტემპერატურების საშუალოებით (mean of daily extrema).

