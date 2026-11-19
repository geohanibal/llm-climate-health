# ანგარიში — დავალება H (FR-28 ნაწილი 1: ტაილანდის პროვინციების დენგეს ყოველთვიური შემთხვევები)

**თარიღი:** 2026-11-19  
**შემსრულებელი:** Gemini 4 Argon (Task H, `docs_ka/motivacia/gemini_tasks_05.md`)  
**სტატუსი:** დასრულებულია (კოდი, მონაცემთა ფაილები, ტესტები, დოკუმენტაცია; git commit/push და `THESIS_KNOWLEDGE_BASE.md`-ის პირდაპირი რედაქტირება არ განხორციელებულა წესი 1-ის შესაბამისად).

---

## 1. შექმნილი და განახლებული ფაილების სია

| ფაილი | ცვლილების აღწერა |
|---|---|
| `backend/scripts/build_dengue_admin1.py` | **ახალი:** რეპროდუცირებადი ოფლაინ ამწყობი სკრიპტი. იღებს OpenDengue V1.3 Spatial extract-ს (`Spatial_extract_V1_3.zip`) და HDX COD-AB Thailand-ის საზღვრების ცხრილს (`tha_admin_boundaries.xlsx`, ფურცელი `tha_admin1`), ფილტრავს ტაილანდის Admin1 თვიურ ჩანაწერებს, აკავშირებს 78 დასახელებას HDX-ის 77 პროვინციასა და P-კოდთან (`TH10`–`TH96`), ამოწმებს დუბლიკატებს `(admin1_pcode, month)` წყვილზე (არასდროს აჯამებს ფარულად) და ქმნის `dengue_monthly_admin1_THA.csv`-ს. |
| `backend/app/data/admin1_name_map_THA.csv` | **ახალი:** ხელით გადამოწმებადი შესაბამისობის ცხრილი (`opendengue_name, hdx_admin1_name, admin1_pcode, note`), 78 სტრიქონი OpenDengue-ს 78 განსხვავებული `adm_1_name`-ისთვის. |
| `backend/app/data/dengue_monthly_admin1_THA.csv` | **ახალი:** ჩაშენებული პროვინციული მონაცემთა ნაკრები (`iso3, admin1_pcode, admin1_name, month, dengue_total, case_definition`), 27 024 სტრიქონი (1993-01 – 2022-12, 77 პროვინცია). |
| `backend/app/services/case_data.py` | **განახლებული:** დაემატა `CHANGED_UNITS = {"THA": {"TH38": "TH43"}}` (Suttirat et al. 2026, გვ. 5) და ჩამტვირთავი ფუნქცია `load_dengue_admin1(iso3, start, end, merge_changed_units=True) -> pd.DataFrame`. |
| `backend/app/config.py` | **განახლებული:** დაემატა `REGIONAL_CASE_DATA_SOURCES["THA"]` წყაროების, ოფიციალური ბმულებისა და შემოწმებული ლიცენზიების (`OpenDengue V1.3: CC BY 4.0`, `HDX COD-AB Thailand: CC BY-IGO, Royal Thai Survey Department / OCHA`) მითითებით. |
| `backend/tests/test_case_data.py` | **განახლებული:** დაემატა 6 ახალი ტესტი (5 ფუნქციური unit/integration ტესტი `load_dengue_admin1`-ისთვის fixture CSV-ით და რეალურ `dengue_monthly_admin1_THA.csv`-ზე + 1 ტესტი `admin1_name_map_THA.csv`-ისა და `config.py`-ის ლიცენზიებისთვის). |
| `docs/requirements/anforderungskatalog.tex` (+ `.pdf`) | **განახლებული:** დაემატა `FR-28` გერმანულ და ინგლისურ ნაწილებში. |
| `docs_ka/anforderungskatalog_ka.tex` (+ `.pdf`) | **განახლებული:** დაემატა `FR-28` ქართულ კატალოგში. |
| `docs_ka/dokumentacia.tex` (+ `.pdf`) | **განახლებული:** დაემატა ქვეთავი `3.6 რეგიონული (Admin1) შემთხვევათა მონაცემები და საზღვრების ჰარმონიზაცია (FR-28, ნაწილი 1)` და ჩანაწერი განხორციელებული ფუნქციების სიაში. |
| `backend/README.md` | **განახლებული:** აღიწერა `build_dengue_admin1.py`, `load_dengue_admin1`, `dengue_monthly_admin1_THA.csv` და `admin1_name_map_THA.csv`. |
| `docs/TESTING_GUIDE.md` | **განახლებული:** განახლდა ტესტების რაოდენობა (192 offline / 193 სრული) და დაფარვის აღწერა. |
| `docs/thesis/RECOMMENDATIONS.md` | **განახლებული:** A8 (ნაწილი 1) და A10 მოინიშნა შესრულებულად (`✅ 2026-11-19`). |

---

## 2. ამწყობი სკრიპტის (`build_dengue_admin1.py`) შემაჯამებელი გამონატანი

```text
========================================================================
THAILAND ADMIN1 MONTHLY DENGUE BUILD SUMMARY
========================================================================
HDX COD-AB Thailand Admin1 provinces: 77
OpenDengue raw Thailand Admin1 monthly rows: 27024
Distinct OpenDengue adm_1_name values: 78
  - Automatically matched (case/space/hyphen-insensitive): 70
  - Resolved via hand-checked mapping table: 8 -> ['BUNGKAN', 'KAMPAENG PHET', 'PHACHINBURI', 'PHRA NAKHON SI AYUDHYA', 'PRACHUAP KHILIKHAN', 'SAMUT PRAKARN', 'SAMUT SONGKHAM', 'TRAD']
  - Unmatched names requiring review: 0 -> []
Duplicate (admin1_pcode, month) rows detected: 0

Output file: C:\Users\49172\Desktop\BacheloArbeit\LLM-Climate-Health\backend\app\data\dengue_monthly_admin1_THA.csv
Total rows written: 27024
Distinct mapped HDX Admin1 P-codes: 77
Period covered: 1993-01 to 2022-12

Provinces per year:
  1993: 72 provinces
  1994: 72 provinces
  1995: 72 provinces
  1996: 72 provinces
  1997: 72 provinces
  1998: 72 provinces
  1999: 72 provinces
  2000: 72 provinces
  2001: 72 provinces
  2002: 72 provinces
  2003: 76 provinces
  2004: 76 provinces
  2005: 76 provinces
  2006: 76 provinces
  2007: 76 provinces
  2008: 76 provinces
  2009: 76 provinces
  2010: 76 provinces
  2011: 77 provinces
  2012: 77 provinces
  2013: 77 provinces
  2014: 77 provinces
  2015: 77 provinces
  2016: 77 provinces
  2017: 77 provinces
  2018: 77 provinces
  2019: 77 provinces
  2020: 77 provinces
  2021: 77 provinces
  2022: 77 provinces

case_definition counts per year:
case_definition  Suspected and confirmed  Total
_year                                          
1993                                   0    864
1994                                   0    864
1995                                   0    864
1996                                   0    864
1997                                   0    864
1998                                   0    864
1999                                   0    864
2000                                   0    864
2001                                   0    864
2002                                   0    864
2003                                 912      0
2004                                 912      0
2005                                 912      0
2006                                 912      0
2007                                 912      0
2008                                 912      0
2009                                 912      0
2010                                 912      0
2011                                 924      0
2012                                 924      0
2013                                 924      0
2014                                 924      0
2015                                 924      0
2016                                 924      0
2017                                 924      0
2018                                 924      0
2019                                 924      0
2020                                 924      0
2021                                 924      0
2022                                 924      0
========================================================================
```

---

## 3. განსხვავებული / 78-ე დასახელების ანალიზი და გადაწყვეტა

OpenDengue V1.3 Spatial extract-ში ტაილანდისთვის გვხვდება **78 განსხვავებული `adm_1_name`**, მაშინ როცა ტაილანდს ოფიციალურად **77 პროვინცია** აქვს (HDX COD-AB Thailand `tha_admin1`).

- **70 დასახელება** დაემთხვა ავტომატურად (რეგისტრის, ინტერვალებისა და დეფისების იგნორირებით). მათგან 61 არის ზუსტი დამთხვევა (case-insensitive), ხოლო 9 განსხვავდება მხოლოდ სიტყვებს შორის ინტერვალით (`BURIRAM` $\rightarrow$ `Buri Ram`, `CHAINAT` $\rightarrow$ `Chai Nat`, `CHONBURI` $\rightarrow$ `Chon Buri`, `LOPBURI` $\rightarrow$ `Lop Buri`, `NONG BUA LAMPHU` $\rightarrow$ `Nong Bua Lam Phu`, `PHANGNGA` $\rightarrow$ `Phang Nga` [შენიშვნა: HDX-შიც `Phangnga` წერია უინტერვალოდ], `SI SAKET` $\rightarrow$ `Si Sa Ket`, `SINGBURI` $\rightarrow$ `Sing Buri`, `SUPHANBURI` $\rightarrow$ `Suphan Buri`).
- **8 დასახელება** საჭიროებდა ხელით გაწერას `admin1_name_map_THA.csv`-ში ტრანსლიტერაციული სხვაობის გამო. რვავე დასახელება 100%-ით გადამოწმდა OpenDengue-ს საკუთარი სვეტებით (`RNE_iso_code` და `FAO_GAUL_code`), ამიტომ ვარაუდი არსად დაგვჭირვებია:

| # | OpenDengue `adm_1_name` | OpenDengue `RNE_iso_code` | OpenDengue `FAO_GAUL_code` | HDX `adm1_name` | HDX `adm1_pcode` | წლები (სტრიქონები) | განმარტება |
|---|---|---|---|---|---|---|---|
| 1 | `BUNGKAN` | `TH-38` | `26787` | `Bueng Kan` | `TH38` | 2011–2022 (144) | ბึงกาฬ-ის ალტერნატიული რომანიზაცია; 2011 წელს გამოეყო Nong Khai-ს (`TH43`). |
| 2 | `KAMPAENG PHET` | `TH-62` | `2864` | `Kamphaeng Phet` | `TH62` | 1993–2022 (360) | `p` vs `ph` რომანიზაცია (กำแพงเพชร). |
| 3 | `PHACHINBURI` | `TH-25` | `2888` | `Prachin Buri` | `TH25` | 2003–2022 (240) | **78-ე დამატებითი სახელი:** 1993–2002 წლებში (120 სტრიქონი) იგივე პროვინცია ჩაწერილია როგორც `PRACHIN BURI`, ხოლო 2003–2022 წლებში (240 სტრიქონი) — როგორც `PHACHINBURI`. ორივეს აქვს ერთი და იგივე `FAO_GAUL_code=2888` და `RNE_iso_code=TH-25`, დროში არ იკვეთება (ჯამში 360 თვე, 0 დუბლიკატი). |
| 4 | `PHRA NAKHON SI AYUDHYA` | `TH-14` | `2896` | `Phra Nakhon Si Ayutthaya` | `TH14` | 1993–2022 (360) | `Ayudhya` vs `Ayutthaya` რომანიზაცია (พระนครศรีอยุธยา). |
| 5 | `PRACHUAP KHILIKHAN` | `TH-77` | `2899` | `Prachuap Khiri Khan` | `TH77` | 1993–2022 (360) | `Khilikhan` vs `Khiri Khan` რომანიზაცია (ประจวบคีรีขันธ์). |
| 6 | `SAMUT PRAKARN` | `TH-11` | `2906` | `Samut Prakan` | `TH11` | 1993–2022 (360) | `Prakarn` vs `Prakan` რომანიზაცია (สมุทรปราการ). |
| 7 | `SAMUT SONGKHAM` | `TH-75` | `2908` | `Samut Songkhram` | `TH75` | 1993–2022 (360) | `Songkham` vs `Songkhram` რომანიზაცია (สมุทรสงคราม). |
| 8 | `TRAD` | `TH-23` | `2919` | `Trat` | `TH23` | 1993–2022 (360) | `Trad` vs `Trat` რომანიზაცია (ตราด). |

**რატომ არის 1993–2002 წლებში 72 პროვინცია, ხოლო 2003–2010 წლებში 76?**
- ოთხი პროვინცია — `Amnat Charoen` (`TH37`), `Mukdahan` (`TH49`), `Nong Bua Lam Phu` (`TH39`) და `Sa Kaeo` (`TH27`) — OpenDengue-ს Admin1 თვიურ სერიაში ჩნდება **2003 წლიდან** (თითოეულს აქვს 240 სტრიქონი, 2003–2022).
- მე-5 პროვინცია — `Bueng Kan` (`TH38`) — ჩნდება **2011 წლიდან** (144 სტრიქონი, 2011–2022).
- როდესაც `load_dengue_admin1(..., merge_changed_units=True)` აერთიანებს `TH38`-ს `TH43`-ში (Nong Khai), **2003–2022 წლების მთელ 20-წლიან პერიოდში ვიღებთ ზუსტად მუდმივ 76 პროვინციას** ($76 \times 240 = 18\,240$ პროვინცია-თვე), რაც სტრიქონის სიზუსტით ემთხვევა Suttirat et al. (2026, გვ. 4)-ში მითითებულ რიცხვს (*„Across the 18,240 province-months of the 2003–2022 study period“*).

---

## 4. `case_definition` წლების მიხედვით

ეს ცხრილი პასუხობს `2026-11-19_regionuli_monacemebi_gegma.md`-ში დასმულ კითხვას, თუ რომელ წლებში რომელი განსაზღვრებაა გამოყენებული:

| წლები | პროვინციების რაოდენობა (raw) | `Total` (სტრიქონები) | `Suspected and confirmed` (სტრიქონები) | სულ წელიწადში |
|---|---|---|---|---|
| **1993–2002** (10 წელი) | 72 | 864 / წელი (ჯამში **8 640**) | 0 | 864 |
| **2003–2010** (8 წელი) | 76 | 0 | 912 / წელი (ჯამში **7 296**) | 912 |
| **2011–2022** (12 წელი) | 77 | 0 | 924 / წელი (ჯამში **11 088**) | 924 |
| **ჯამი (1993–2022)** | **77 უნიკალური P-code** | **8 640** | **18 384** | **27 024** |

**დასკვნა:** განსაზღვრების ცვლილება ხდება მხოლოდ ერთხელ — 2002 და 2003 წლების საზღვარზე (`Total` $\rightarrow$ `Suspected and confirmed`). Suttirat et al. (2026)-ის კვლევის პერიოდში (**2003–2022**) სტანდარტიზებული განსაზღვრება 100%-ით ერთგვაროვანია (`Suspected and confirmed`).

---

## 5. ტესტირების შედეგები

გაშვებული ბრძანება:
```bash
backend\.venv\Scripts\pytest.exe backend\tests -m "not network" -q
```
შედეგი:
- **`192 passed, 1 deselected, 1 warning in 22.60s`** (ყველა 192 ოფლაინ ტესტი გადის წარმატებით; `test_case_data.py`-ში 19/19 ტესტი გადის 0.65 წამში).

---

## 6. შემოთავაზებული განახლება `docs/thesis/THESIS_KNOWLEDGE_BASE.md`-ისთვის

*(წესი 1-ის თანახმად, `THESIS_KNOWLEDGE_BASE.md` უშუალოდ არ შეცვლილა; ქვემოთ მოცემულია ზუსტი ტექსტი Claude-ის/სერგის მიერ ჩასამატებლად)*:

1. **§5 (System capabilities vs. P1 data-preparation steps), სტრიქონი 2:**
   - *Manual step in P1:* `2 | Harmonise changing admin units (Bueng Kan → Nong Khai)`
   - *System today:* `Supported in regional loader load_dengue_admin1(merge_changed_units=True) via explicit CHANGED_UNITS = {"THA": {"TH38": "TH43"}} (Task H, FR-28 Part 1); UI/ETL wiring pending`
   - *Code:* `case_data.py`, `scripts/build_dengue_admin1.py`
   - *Status:* `~ (case loader implemented 2026-11-19)`
2. **§5.1 (Requirements derived from literature):**
   - `FR-28 (was FR-new-1) | Subnational (Admin1) spatial units and boundary harmonisation | P1 (p. 5), P4 (p. e211), P3 (p. 1, 8), supervisor decision D1 (2026-11-02) | Part 1 implemented 2026-11-19 (Task H: Thailand 77 provinces monthly dengue cases 1993–2022, HDX COD-AB P-codes TH10–TH96, Bueng Kan TH38 -> Nong Khai TH43 merge)`
3. **§10 (Decision log):**
   - `| 2026-11-19 | Task H (FR-28 Part 1): Offline build script backend/scripts/build_dengue_admin1.py extracts Thailand Admin1 monthly rows from OpenDengue V1.3 Spatial_extract_V1_3.zip (27,024 rows, 1993–2022) and maps all 78 distinct adm_1_name values to the 77 official HDX COD-AB Thailand Admin1 provinces (TH10–TH96) via backend/app/data/admin1_name_map_THA.csv (70 automatic normalized matches, 8 hand-verified romanisation variants confirmed by OpenDengue RNE_iso_code and FAO_GAUL_code; extra 78th name is PHACHINBURI 2003–2022 vs PRACHIN BURI 1993–2002 for TH25, non-overlapping, 0 duplicates). case_definition is "Total" in 1993–2002 (8,640 rows, 72 provinces) and uniformly "Suspected and confirmed" in 2003–2022 (18,384 rows, 76/77 provinces). Loader load_dengue_admin1(iso3, start, end, merge_changed_units=True) merges Bueng Kan (TH38) into Nong Khai (TH43) when merge_changed_units=True (yielding a constant 76 provinces = 18,240 province-months across 2003–2022, matching Suttirat et al. 2026, p. 4). Report: docs_ka/motivacia/H_report.md. |`

---

## 7. ღია კითხვები Claude-ისა და სერგისთვის

1. **1993–2002 წლების 4 გამოტოვებული პროვინცია (`TH27` Sa Kaeo, `TH37` Amnat Charoen, `TH39` Nong Bua Lam Phu, `TH49` Mukdahan):**  
   OpenDengue V1.3-ში ეს 4 პროვინცია მხოლოდ 2003 წლიდან იწყება (1993–2002 წლებში 72 პროვინციაა). რადგან Suttirat et al. (2026)-ის პერიოდი 2003–2022 წლებია, ამ პერიოდში `merge_changed_units=True` იძლევა სრულ და მუდმივ 76 პროვინციას. თუ მომხმარებელი მოითხოვს 1993–2022 წლებს, უნდა დარჩეს ეს 4 პროვინცია 1993–2002-ში ცარიელი (როგორც ახლაა A20 წესით), თუ საჭიროა UI-ში გაფრთხილება 2002/2003 წლების საზღვარზე (სადაც `case_definition`-იც იცვლება `Total` $\rightarrow$ `Suspected and confirmed`)?
2. **HDX-ში `TH82`-ის დასახელება (`Phangnga` vs `Phang Nga`):**  
   HDX-ის `tha_admin1` ცხრილში `TH82`-ის ინგლისურ სახელად წერია `Phangnga` (ერთ სიტყვად, ზუსტად ისევე, როგორც OpenDengue-ში `PHANGNGA`). უნდა დავტოვოთ HDX-ის ოფიციალური ჩანაწერი `Phangnga` უცვლელად? (ამჟამად დატოვებულია უცვლელად, როგორც HDX-ის პირველად წყაროშია).
