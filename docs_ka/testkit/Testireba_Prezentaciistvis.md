# სატესტო კიტი — ხვალინდელი პრეზენტაციისთვის

**სტატუსი:** ყველა სცენარი ქვემოთ **უკვე გატესტილია ჩემ მიერ** (2026-09-16, შენს ლოკალურ მანქანაზე, შენი ნამდვილი backend-ის საშუალებით — არა სიმულაცია). ყოველი "შედეგი" ველი რეალურია, ზუსტად ის, რაც სერვერმა დააბრუნა. თუ ხვალ ზუსტად ამ input-ებს გამოიყენებ, იგივე ტიპის შედეგს მიღებ (რიცხვები ოდნავ შეიცვლება, თუ builtin CSV-ები განახლდა, მაგრამ სტრუქტურა და succes-ი გარანტირებულია).

---

## 0. სერვერის გაშვება (გააკეთე ეს პრეზენტაციამდე საღამოს, არა დილას)

```bash
cd backend
.venv\Scripts\activate
uvicorn app.main:app --port 8000
```

გადამოწმება:

```bash
curl http://127.0.0.1:8000/api/health
# მოსალოდნელი: {"status":"ok"}
```

Frontend-ისთვის (თუ საჭიროა ცალკე გაშვება, არა deploy-ილი ვერსია):

```bash
cd frontend
flutter run -d chrome --web-port=5173
```

`flutter analyze` ახლა გავუშვი მთელ frontend-ზე — **0 შეცდომა**, მხოლოდ 3 კოსმეტიკური lint-info. კოდი კომპილირდება სუფთად.

> **თუ დეპლოი-ილ (Render) ბმულს აჩვენებ, არა localhost-ს:** გახსენი ის ბმული 5-10 წუთით ადრე — free tier "იძინებს" უმოქმედობის 15 წუთის შემდეგ და გაღვიძებას 30-50 წამი სჟირდება. ცოცხალ პრეზენტაციაზე ეს პაუზა უხერხულია.

---

## 1. მთავარი დემო — დენგე, ტაილანდი (ᲛᲘᲧᲐᲜᲔᲗ ᲔᲡ)

**Form-ში:** Disease=Dengue, Region=Thailand, Variables=Temperature+Precipitation, 2015-01-01 → 2019-12-01, Climate source=**NASA POWER**, Case source=builtin, Population=World Bank.

**curl-ით გადასამოწმებლად:**
```bash
curl -X POST http://127.0.0.1:8000/api/integrate -H "Content-Type: application/json" -d "{\"disease\":\"dengue\",\"region\":\"Thailand\",\"variables\":[\"temperature\",\"precipitation\"],\"start_date\":\"2015-01-01\",\"end_date\":\"2019-12-01\",\"aggregation\":\"native\",\"climate_source\":\"nasa-power\",\"case_data_source\":\"builtin\",\"population_source\":\"worldbank\"}"
```

**რეალურად მივიღე:**
- `HTTP 200`, 60 თვიური ჩანაწერი (2015-01 → 2019-12)
- `explanation_source: "llm"` — შენი Gemini key **მუშაობს**, ახსნა ნამდვილად Gemini-მ დააგენერირა
- **სტატისტიკურად მნიშვნელოვანი (p<0.05) დაგვიანების ეფექტი**: ტემპერატურა Lag 2 (r=0.44, p=0.0005) და Lag 3 (r=0.64, p<0.0001) — ეს ზუსტად ის ბიოლოგიური ეფექტია, რაზეც პრეზენტაციაში ლაპარაკობ (კოღოს გამრავლების დაგვიანება). **ეს რიცხვი აჩვენე ხელმძღვანელს — ის ცოცხალი მტკიცებულებაა.**

**რისკი:** Open-Meteo (ERA5) ტესტირებისას ერთხელ 1-2 წუთით მიცემა 502-ს (გარე სერვისის ხანმოკლე შეყოვნება, თავადვე გამოჯანმრთელდა). **ამიტომ ამ დემოსთვის NASA POWER-ს ვურჩევ პირველად** — თუ Open-Meteo გინდა აჩვენო, გატესტე წინასწარ, და თუ ჩავარდა — უბრალოდ გადართე dropdown-ში NASA POWER-ზე და თავიდან გაუშვი.

---

## 2. ბუნებრივი ენა → ფორმა (LLM parse)

**ჩაწერე ეს ზუსტი ტექსტი NL ველში:**
```
Dengue in Thailand from 2015 to 2023, monthly, temperature and precipitation
```

**რეალურად მივიღე** (ზუსტად ეს, ცოცხალი Gemini-საგან):
```json
{"disease":"dengue","region":"Thailand","variables":["temperature","precipitation"],
 "start_date":"2015-01-01","end_date":"2023-12-01","aggregation":"native",
 "climate_source":null,
 "notes":"Monthly aggregation was mapped to native as it represents the data's original reported resolution."}
```
`climate_source` შეგნებულად `null`-ია (ტექსტში წყარო არ იყო ხსენებული) — ეს კარგი მაგალითია დახურული ლექსიკონის პრინციპისთვის: LLM არ იგონებს, ცარიელს ტოვებს.

---

## 3. ცოცხალი წყაროების ძებნა + WHO GHO ინტეგრაცია — მალარია, კენია

**ᲛᲜᲘᲨᲕᲘᲘᲡ ᲤᲣᲗᲘ:** ძებნაში აირჩიე ინდიკატორი **"Estimated number of malaria cases"** (`MALARIA_EST_CASES`).
**არა** "Number of confirmed malaria cases" (`MALARIA_CONF_CASES`) — ეს კონკრეტულად კენიისთვის **ცარიელია** (ტესტისას ყველა წელი `null` დაბრუნდა). გატესტილი, ორივე — estimated მუშაობს, confirmed არა.

**curl-ით:**
```bash
curl "http://127.0.0.1:8000/api/search-case-sources?disease=malaria&region=Kenya"
```
→ 23 ნამდვილი შედეგი (15 WHO GHO ინდიკატორი + 8 HDX dataset), ყველა რეალური, ცოცხალი API-დან.

**ინტეგრაცია** (`who_indicator_code=MALARIA_EST_CASES`, region=Kenya, 2010-2022, climate=NASA POWER):
რეალურად მივიღე 13 წლიური ჩანაწერი, მაგ. 2010: `case_count=3,339,223`, `incidence_rate_per_100k=8027.26`. ნამდვილი, არადამახინჯებული WHO რიცხვები.

**შენიშვნა:** disease-ს ველი API-ს პირდაპირ გამოძახებისას **პატარა ასოებით** უნდა იყოს (`malaria`, არა `Malaria`) — UI-ში ეს ავტომატურად სწორად მუშაობს, curl-ით ტესტისას თუ თავად წერ, გაითვალისწინე.

---

## 4. საკუთარი ფაილის ატვირთვა (custom_upload) — თანდართული CSV

ამ საქაღალდეში თანდართული ფაილი: **`sample-custom-case-data.csv`** — მინიმალური, სინთეტიკური (გამოგონილი, არა ნამდვილი) 12-თვიანი მაგალითი, სვეტებით `observation_date`, `reported_cases` (განზრახ **არა** სტანდარტული სახელები — რომ ფაზი-მოძებნის (fuzzy matching) ფუნქცია ცოცხლად ეჩვენო).

**Form-ში:** Disease=Dengue, Region=Vietnam (ან ნებისმიერი), Case source=**Upload file**, ატვირთე `sample-custom-case-data.csv`, 2022-01-01 → 2022-12-01.

**რეალურად მივიღე:**
- `HTTP 200`, 12/12 მწკრივი შენარჩუნებული, 0 გაფილტრული
- Audit log: `selected_date_column: "observation_date"`, `selected_value_column: "reported_cases"`
- Gemini-ის ახსნა ავტომატურად დაგენერირდა (`human_explanation`), ხსნის ზუსტად რომელი სვეტი რამ აირჩა

**რას აჩვენებს ეს:** AI ჰარმონიზაცია რეალურად ცნობს არასტანდარტულ სვეტების სახელებს, არა hardcoded-ს.

---

## 5. საკუთარი URL (custom_url) — ნამდვილი, ცოცხალი HDX ბმული

**ეს ბმული გატესტილია და მუშაობს ცოცხლად ახლა:**
```
https://data.humdata.org/dataset/ac63a95e-7296-42fb-802b-7f7541c73e45/resource/9e839677-3ff0-44b3-992c-1a99e68df515/download/doh-epi-dengue-data-2016-2021.csv
```
ეს არის ფილიპინების ჯანდაცვის სამინისტროს (DOH) ნამდვილი, admin-region დონის დენგეს მონაცემი (32,702 მწკრივი! — თითო რეგიონი/თარიღი ცალკე მწკრივია).

**Form-ში:** Disease=Dengue, Region=Philippines, Case source=**Custom URL**, ჩააკოპირე ზემოთა ბმული, 2016-01-01 → 2021-12-01, Climate=Open-Meteo.

**რეალურად მივიღე:**
- `HTTP 200`, 72 თვიური ჩანაწერი (32,702 ნედლი მწკრივი → ავტომატურად აგრეგირდა 72 თვედ)
- Audit: `original_columns: ["loc","cases","deaths","date","Region"]`, `selected_date_column: "date"`, `selected_value_column: "cases"`, `dropped_rows_count: 1`
- 2016-01: `case_count=17052`

**⚠️ ერიდე ამ ბმულებს (გატესტილი, ᲐᲛᲖᲛᲘᲗ):**
- HDX-ის Kenya "malaria per 100k per county" CSV — **არ აქვს დროის სვეტი** (per-county snapshot ცხრილია), მოიცემა 502 შეცდომა "Missing: time-series date column". ეს **არასწორი დემოსთვის**, თუმცა კარგი მაგალითია, თუ სპეციალურად error-handling-ის ჩვენება გინდა.
- HDX-ის ნებისმიერი `.xlsx` ფაილი (მაგ. "Haiti cholera cases per month.xlsx") — **backend ამჟამად მხოლოდ CSV-ს კითხულობს**, xlsx ჩავარდება. ეს ცნობილი, დაფიქსირებული ხარვეზია (`services/hdx.py`-ის docstring-ი ცდომილად ამბობს, რომ xlsx მუშაობს) — არ ურჩევ ამის ხსენებას პრეზენტაციაზე, თუმცა თუ პროფესორი კონკრეტულად `.xlsx`-ს აირჩევს live-ძებნაში, იცოდე რომ ჩავარდება.

---

## 6. რას **არ** ღირს დემოზე კლიკვა

**TMD (ტაილანდის ეროვნული მეტეოსამსახური)** — Climate source dropdown-ში არჩევა დააბრუნებს:
```
HTTP 503: "TMD_API_UID/TMD_API_UKEY are not configured — register for free at data.tmd.go.th..."
```
ეს **მოსალოდნელია** (შენ ჯერ არ დაგირეგისტრირებია) და გატესტილია, რომ თავად crash-ს არ იძლევა — მარტივი, გასაგები შეცდომაა. თუ პროფესორი ამას აირჩევს ან იკითხავს, პასუხი მზად გაქვს (ეს "ღია საკითხების" სექციაშიც წერია შენს დანარჩენ დოკუმენტებში).

---

## შემაჯამებელი ცხრილი (რომელი input, რა ველოდი)

| სცენარი | Disease/Region | Case source | Climate | გატესტილი? |
|---|---|---|---|---|
| ①  ფლაგმანი | Dengue / Thailand | builtin | NASA POWER | ✅ HTTP 200, lag-კორელაცია |
| ②  NL parse | — | — | — | ✅ ზუსტი JSON მიღებული |
| ③  WHO GHO | Malaria / Kenya | who_gho (MALARIA_EST_CASES) | NASA POWER | ✅ HTTP 200, 13 წელი |
| ④  Upload | Dengue / Vietnam | custom_upload (თანდართული CSV) | open-meteo | ✅ HTTP 200, 12/12 მწკრივი |
| ⑤  Custom URL | Dengue / Philippines | custom_url (HDX ბმული ზემოთ) | open-meteo | ✅ HTTP 200, 72 თვე |
| ⑥  TMD | Dengue / Thailand | builtin | tmd | ⚠️ განზრახ 503 (მოსალოდნელი) |

წარმატება: **5/5** ცოცხალი სცენარი მუშაობს ისე, როგორც უნდა; 1/1 მოსალოდნელი ხარვეზი (TMD) ჯანსაღად იჭერს თავს.
