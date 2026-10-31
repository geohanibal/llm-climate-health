# დავალება B — ანგარიში: Lag სვეტები და Lag Buffer (FR-23)

**ავტორი:** Sergi Koniashvili (LLM-Climate-Health, საბაკალავრო ნაშრომი, ბრემენის უნივერსიტეტი)  
**თარიღი:** 2026-11-01  
**სტატუსი:** შესრულებულია (კოდი, ტესტები და დოკუმენტაცია განახლებულია)

---

## 1. შექმნილი და შეცვლილი ფაილების სია

| ფაილი | ცვლილების ტიპი | აღწერა |
|---|---|---|
| `backend/app/services/lags.py` | **ახალი ფაილი** | იზოლირებული სერვის-მოდული: `calculate_buffer_start_date` და `add_lagged_climate_features`. |
| `backend/tests/test_lags.py` | **ახალი ფაილი** | Unit-ტესტები: დეფოლტური ქცევა, [1, 3] გამოთვლა, Lag-ბუფერის მუშაობა, საწყისი NaN-ები ბუფერის გარეშე, ვალიდაცია (1..6). |
| `backend/app/models.py` | შეცვლილი | `IntegrationRequest`-ს დაემატა `lag_periods: list[int] = Field(default_factory=list)` (ვალიდაციით 1..6); `PeriodRecord`-ს დაემატა `model_config = ConfigDict(extra="allow")`. |
| `backend/app/services/etl.py` | შეცვლილი | `run_integration`-ს დაემატა `lag_periods`; კლიმატის მონაცემები ამოიღება `max(lag)` ბუფერით; Lags დათვლის შემდეგ კლიმატი იჭრება მოთხოვნილ საწყის თარიღამდე; ნაბიჯები აღირიცხება provenance-ში; `PeriodRecord`-ში ივსება lag-მნიშვნელობები. |
| `backend/app/main.py` | შეცვლილი | `integrate` გადასცემს `lag_periods`-ს კეშს და pipeline-ს; `integrate_with_upload` იღებს `lag_periods`-ს ფორმის ველიდან (მძიმით გამოყოფილი რიცხვები). |
| `backend/tests/test_etl.py` | შეცვლილი | დაემატა `test_run_integration_with_lag_periods_and_buffer`. |
| `docs/requirements/anforderungskatalog.tex` (+ `.pdf`) | შეცვლილი | დაემატა **FR-23** (DE/EN, ლიტერატურის წყარო: Suttirat et al. 2026, Lowe et al. 2021); FR-19-ში დაკონკრეტდა Spearman-$\rho$. |
| `docs_ka/anforderungskatalog_ka.tex` (+ `.pdf`) | შეცვლილი | დაემატა **FR-23** ქართულად; FR-19-ში დაკონკრეტდა Spearman-$\rho$. |
| `docs_ka/dokumentacia.tex` (+ `.pdf`) | შეცვლილი | ETL თავში დაემატა ქვეთავი „დროითი დაყოვნება და კლიმატის Lag-ბუფერი“; განხორციელებულ ფუნქციებში დაემატა FR-23. |
| `backend/README.md` | შეცვლილი | ენდპოინტების ცხრილსა და Request Options-ში აღიწერა `lag_periods` და Lag Buffer; განახლდა არქიტექტურული განლაგება (`services/lags.py` და სხვ.). |
| `docs/TESTING_GUIDE.md` | შეცვლილი | განახლდა ტესტების რაოდენობა (145 passed), დაფარვა (lags & buffer) და დაემატა ხელით შემოწმების მე-12 ნაბიჯი. |
| `docs/thesis/evaluation_protocol_CS1.md` | შეცვლილი | ამოიშალა `[if task B done]` (Lags 1, 2, 3 დადასტურებულია). |
| `docs/thesis/RECOMMENDATIONS.md` | შეცვლილი | მონიშნულია A1 და A22 როგორც ✅ 2026-10-31. |

---

## 2. ცვლილებების დეტალური აღწერა

1. **მოდელები და ვალიდაცია (`models.py`):**
   - `IntegrationRequest`-ში `lag_periods` არის `list[int]`, დეფოლტად ცარიელი სია `[]` (არაფერი იცვლება ძველ მოთხოვნებში).
   - `@field_validator("lag_periods")` ამოწმებს, რომ ყოველი ელემენტი იყოს მთელი რიცხვი 1-დან 6-მდე. 0, უარყოფითი ან 7+ იწვევს `ValueError`-ს (422/400). მნიშვნელობები ავტომატურად სორტირდება და დედუბლიკაცია უკეთდება.
   - `PeriodRecord`-ს დაემატა `model_config = ConfigDict(extra="allow")`, რითაც 6 არსებული ატრიბუტი (`period`, `case_count`, `population`, `incidence_rate_per_100k`, `temperature_mean_c`, `precipitation_sum_mm`) დარჩა უცვლელი და მკაცრად ტიპიზებული, ხოლო დინამიური სვეტები (`temperature_lag1`, `precipitation_lag3` და ა.შ.) პირდაპირ სერიალიზდება JSON-ში.

2. **Lag-ბუფერის ლოგიკა (`services/lags.py`):**
   - `calculate_buffer_start_date(start_date, lag_periods, resolution)`: გამოთვლის `start_date`-ზე `max(lag_periods)` პერიოდით ადრინდელ თარიღს.
     - `month`: გამოაკლდება `max(lag)` თვე (მაგ. 2010-01-01 და lag 3 $\rightarrow$ 2009-10-01).
     - `day`: გამოაკლდება `max(lag)` დღე.
     - `year`: გამოაკლდება `max(lag)` წელი.
     - `decade`: მხარდაჭერილია კონსისტენტურად — გამოაკლდება `max(lag) * 10` წელი.
   - `add_lagged_climate_features(df, lag_periods)`: კლიმატის სორტირებულ სერიაზე აკეთებს `shift(lag)`-ს. ტემპერატურის ცვლადებს არქმევს `temperature_lag<k>`, ნალექს — `precipitation_lag<k>`.

3. **ETL მილსადენი (`services/etl.py`):**
   - კლიმატის მონაცემები ამოიღება `climate_start = calculate_buffer_start_date(...)`-დან.
   - ეპიდემიოლოგიური მონაცემები (`case_df`) და მოსახლეობა (`pop_df`) ამოიღება **მხოლოდ** მოთხოვნილ პერიოდზე (`[start, end]`).
   - Lags-ის დამატების შემდეგ, `climate_df` იჭრება `period >= start_period`-მდე, რათა ბუფერის პერიოდის (მაგ. 2009-10..2009-12) რიგები არ გამოჩნდეს გამომავალ ცხრილში.
   - Provenance-ში იწერება მკაფიო ნაბიჯები ბუფერისა და დამატებული lags-ების შესახებ.

4. **Upload ენდპოინტი (`/api/integrate/upload`):**
   - იღებს `lag_periods: str = Form("")` (მაგ. `"1,3"`), აპარსავს მთელ რიცხვებად და ატარებს იმავე ვალიდაციასა და მილსადენს.
   - თუ კლიმატის წყაროს არ გააჩნია მონაცემები `start_date`-მდე (მაგ. მომხმარებლის ატვირთული CSV), საწყისი რიგები რჩება `NaN` შეცდომის გარეშე.

---

## 3. ტესტების შედეგები

გაშვებულია სრული backend ტესტების ნაკრები:
```bash
powershell -Command "Set-Location backend; .venv\Scripts\python.exe -m pytest -q"
```

**შედეგი:**
```text
145 passed, 1 warning in 13.31s
```
*(145-ვე ტესტი წარმატებით გადის. არსებული სტატისტიკური და LLM ტესტები სრულად მწვანეა).*

---

## 4. რეალური მაგალითი: Thailand, Monthly, 2010-01 ... 2010-06, Lags [1, 3]

მოთხოვნის გაშვება რეალურ Open-Meteo ERA5 და OpenDengue მონაცემებზე:
- **რეგიონი:** Thailand
- **დაავადება:** Dengue
- **პერიოდი:** 2010-01-01 $\rightarrow$ 2010-06-01
- **Lags:** `[1, 3]`

### მიღებული შედეგი (პირველი რიგი 2010-01):

| Period | Case Count | Temp Mean (°C) | **Temperature Lag 1** | **Temperature Lag 3** | Precip Sum (mm) | **Precipitation Lag 1** | **Precipitation Lag 3** |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **2010-01** | **1496.0** | **26.32** | **25.95** | **26.98** | **0.5** | **0.5** | **193.6** |
| 2010-02 | 1528.0 | 29.38 | 26.32 | 25.80 | 34.5 | 0.5 | 23.9 |
| 2010-03 | 2020.0 | 30.55 | 29.38 | 25.95 | 3.3 | 34.5 | 0.5 |
| 2010-04 | 1868.0 | 32.28 | 30.55 | 26.32 | 3.7 | 3.3 | 34.5 |
| 2010-05 | 3666.0 | 32.30 | 32.28 | 29.38 | 42.0 | 3.7 | 3.3 |
| 2010-06 | 6631.0 | 33.80 | 32.30 | 30.55 | 49.5 | 42.0 | 3.7 |

**დასტური:**
- `2010-01`-ს გააჩნია ვალიდური, არა-NaN მნიშვნელობები: `temperature_lag1 = 25.95` (2009-12-ის ტემპერატურა) და `temperature_lag3 = 26.98` (2009-10-ის ტემპერატურა).
- ბუფერის თვეები (2009-10..2009-12) გამომავალ მონაცემებში საერთოდ არ არის (სულ ზუსტად 6 რიგია).
- Pipeline Provenance-ში დაფიქსირდა:
  > *„Applied a 3-period lag buffer for climate data (fetching from 2009-10-01 instead of 2010-01-01) to compute lagged variables without losing initial observations (Lowe et al. 2021).“*  
  > *„Added lagged climate features: lags 1, 3.“*

---

## 5. Frontend-ის შემდგომი სამუშაო (Follow-up)

ამ დავალების პირობის თანახმად frontend-ის კოდი **არ შეცვლილა**.
შემდგომ ნაბიჯად (Follow-up) რჩება:
1. `frontend/lib/models/period_record.dart`-ში დინამიური lag-სვეტების JSON დეკოდირება.
2. ცხრილის კომპონენტში (`frontend/lib/widgets/data_table_card.dart`) lag-სვეტების ასახვა.
3. CSV და JSON ექსპორტის სერვისში (`dataset_export_service.dart`) lag-სვეტების ჩართვა.

---

## 6. შემოთავაზებული განახლებები `THESIS_KNOWLEDGE_BASE.md`-სთვის

*(წესის თანახმად, ქვემოთ მოცემულია მხოლოდ შეთავაზება, KB ფაილი უშუალოდ არ ჩასწორებულა):*

1. **§5 Capability Matrix:**
   - სტრიქონი „lag columns in output table“: `✗` $\rightarrow$ `✓ (FR-23, Task B, 1–6 periods with lag buffer)`
2. **§5.1 Proposed Requirements:**
   - დაემატოს: `FR-23 | Das System muss optional zeitverzögerte Klimavariablen (Lag 1–6) als eigene Spalten im integrierten Datensatz bereitstellen und per Lag-Puffer ohne Zeilenverlust berechnen. | Literatur: Suttirat et al. 2026, Lowe et al. 2021 | Umgesetzt`
3. **§9 Open Implementation Tasks:**
   - მონიშნოს დავალება B დასრულებულად.
4. **§10 Architectural Decision Log:**
   - ჩანაწერი: *„2026-10-31 (Task B): Lagged climate features are pre-computed on climate series using a temporal buffer of length max(lag_periods) before cutting back to requested start_date. This avoids initial NaN row drops and maintains statistical sample size (Lowe et al. 2021).“*

---

## 7. Review fix (2026-11-01)

### გამოვლენილი ხარვეზი
`lags.add_lagged_climate_features` იყენებდა რიგებზე დაფუძნებულ `.shift()`-ს. თუ კლიმატურ სერიაში გარკვეული პერიოდი გამოტოვებული იყო (მაგ. 2019-12 აკლდა), 2020-01-ის Lag 1 ჩუმად იღებდა 2019-11-ის მნიშვნელობას, ნაცვლად იმისა, რომ მიეღო `NaN`.

### გამოსწორება (`backend/app/services/lags.py`)
1. Shifting-მდე კლიმატის DataFrame დროებით რეინდექსირდება მოცემული რეზოლუციის სრულ, უწყვეტ პერიოდების სერიაზე (`_build_complete_period_range`) უადრეს და უგვიანეს დაკვირვებას შორის (თვე: ყოველი თვე, დღე: ყოველი დღე, წელი: ყოველი წელი, ათწლეული: ყოველი ათწლეული).
2. Lag-სვეტების დაგენერირება ხდება ამ უწყვეტ ბადეზე, რის გამოც გამოტოვებული პერიოდის შემდეგ არსებული დაკვირვება იღებს `NaN`-ს.
3. Shifting-ის შემდეგ ის რიგები, რომლებიც მხოლოდ რეინდექსირების გამო დაემატა, ავტომატურად იშლება (`result = reindexed.loc[reindexed.index.isin(original_periods)].reset_index()`).

### დამატებული ტესტები (`backend/tests/test_lags.py`)
- `test_add_lagged_climate_features_missing_monthly_period_yields_nan`: პერიოდები `["2019-10", "2019-11", "2020-01"]`, lag `[1]` $\rightarrow$ 2020-01-ის `temperature_lag1` არის `NaN` (ხოლო 2019-11-ის lag1 არის 2019-10-ის მნიშვნელობა).
- `test_add_lagged_climate_features_missing_daily_period_yields_nan`: დღიური რეზოლუცია გამოტოვებული დღით `2020-05-03` $\rightarrow$ 2020-05-04-ის `temperature_lag1` არის `NaN`.

### ტესტების საბოლოო შედეგი
```bash
powershell -Command "Set-Location backend; .venv\Scripts\python.exe -m pytest -q"
# 147 passed, 1 warning in 13.45s
```
*(147-ვე ტესტი წარმატებით გადის).*

### განახლებული თარიღები
`docs/thesis/RECOMMENDATIONS.md`-ში A1 და A22 დავალებების დასრულების თარიღი განახლდა: `✅ 2026-11-01`.


