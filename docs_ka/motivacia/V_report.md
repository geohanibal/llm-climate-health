# Verification Report: Citations and References in Thesis Draft

**Document evaluated:** `docs/thesis/entwurf/entwurf_motivation_anforderungen.tex` (authoritative German draft)  
**Evaluator:** Antigravity (verification mode)  
**Date:** 2026-11-01  
**Primary sources:**
- Lowe et al. (2021), *The Lancet Planetary Health*, 5(4), e209–e219 (`docs_ka/motivacia/papers/lowe_2021_lancetph.pdf`)
- Suttirat et al. (2026), *PLOS Neglected Tropical Diseases*, 20(7), e0014590 (`docs_ka/motivacia/papers/suttirat_2026_plosntd.pdf`)
- Clarke et al. (2024), *Scientific Data*, 11, 296 (`docs_ka/motivacia/papers/clarke_2024_opendengue.pdf`)

---

## 1. Summary Table

| # | .tex line | article | cited page | verdict | found on page |
|---|---|---|---|---|---|
| 1 | 58 | Suttirat et al. (2026) | S. 5--8 | OK | S. 4--8 (Methodenteil), S. 1 (Abstract), S. 12 (Abb. 5) |
| 2 | 61 | Lowe et al. (2021) | S. e211--e212 | OK | S. e211--e212 (PDF S. 3--4) |
| 3 | 68--75 | Suttirat et al. (2026) | S. 4 | OK | S. 4 |
| 4 | 84--85 | Lowe et al. (2021) | S. e211 | OK | S. e211 (PDF S. 3) |
| 5 | 85--87 | Suttirat et al. (2026) | S. 7 | OK | S. 7 |
| 6 | 91 | Lowe et al. (2021) | S. e218 | OK | S. e218 (PDF S. 10) |
| 7 | 94 | Lowe et al. (2021) | S. e218 | OK | S. e218 (PDF S. 10) |
| 8 | 99--102 | Clarke et al. (2024) | S. 2 | OVERCLAIM | S. 2 |
| 9 | 106 | Clarke et al. (2024) | S. 1, 9 | OK | S. 1, 9 |
| 10 | 111 | Suttirat et al. (2026) | S. 5, 8 | WRONG_PAGE | S. 5 (Datenaufbereitung: pandas, dismo); S. 8 nur Optuna (Hyperparameter-Tuning) |
| 11 | 192 | Suttirat et al. (2026) | S. 5 | OK | S. 5 |
| 12 | 193 | Lowe et al. (2021) | S. e211 | OK | S. e211 (PDF S. 3) |
| 13 | 194 | Suttirat et al. (2026) | S. 5 | OK | S. 5 |
| 14 | 195 | Suttirat et al. (2026) | S. 5 | OK | S. 5 |
| 15 | 196 | Lowe et al. (2021) | S. e211 | OK | S. e211 (PDF S. 3) |
| 16 | 197 | Suttirat et al. (2026) | S. 5 | OK | S. 5 |
| 17 | 198 | Lowe et al. (2021) | S. e211 | OK | S. e211 (PDF S. 3) |
| 18 | 199 | Suttirat et al. (2026) | S. 7 | OK | S. 7 |
| 19 | 199 | Lowe et al. (2021) | S. e212 | OK | S. e212 (PDF S. 4) |
| 20 | 200 | Lowe et al. (2021) | S. e211 | OK | S. e211 (PDF S. 3) |
| 21 | 201 | Suttirat et al. (2026) | S. 7 | OK | S. 7 |
| 22 | 201 | Lowe et al. (2021) | S. e211 | OK | S. e211 (PDF S. 3) |
| 23 | 202 | Suttirat et al. (2026) | S. 4--5 | OK | S. 4--5 |
| 24 | 204 | Suttirat et al. (2026) | S. 5 | OK | S. 5 |
| 25 | 205 | Suttirat et al. (2026) | S. 5 | OK | S. 5 |
| 26 | 206 | Suttirat et al. (2026) | S. 5, 8 | OK | S. 5 (pandas, dismo), S. 8 (Optuna/Python) |
| 27 | 206 | Lowe et al. (2021) | S. e211--e212 | OK | S. e211--e212 (PDF S. 3--4; Ref. 30 S. e218) |
| 28 | 222 | Suttirat et al. (2026) | S. 7 | OK | S. 7 |
| 29 | 222 | Lowe et al. (2021) | S. e211 | OK | S. e211 (PDF S. 3) |
| 30 | 224 | Suttirat et al. (2026) | S. 4--5 | OK | S. 4--5 |
| 31 | 226 | Suttirat et al. (2026) | S. 7 | OK | S. 7 |
| 32 | 226 | Lowe et al. (2021) | S. e212 | OK | S. e212 (PDF S. 4) |
| 33 | 228 | Lowe et al. (2021) | S. e211 | OK | S. e211 (PDF S. 3) |
| 34 | 230 | Suttirat et al. (2026) | S. 5 | OK | S. 5 |
| 35 | 230 | Lowe et al. (2021) | S. e211 | OK | S. e211 (PDF S. 3) |
| 36 | 232 | Suttirat et al. (2026) | S. 4--5 | OK | S. 4--5 |
| 37 | 234 | Clarke et al. (2024) | S. 2, 4, 12 | OK | S. 2, 4, 12 |
| 38 | 236 | Clarke et al. (2024) | S. 1, 8 | OK | S. 1, 8 |
| 39 | 238 | Clarke et al. (2024) | S. 2 | OK | S. 2 |
| 40 | 240 | Suttirat et al. (2026) | S. 7 | OK | S. 7 |
| 41 | 240 | Lowe et al. (2021) | S. e212 | OK | S. e212 (PDF S. 4) |
| 42 | 247 | Suttirat et al. (2026) | S. 12 | OK | S. 12 |
| 43 | 248--249 | Lowe et al. (2021) | S. e211 | OK | S. e211 (PDF S. 3) |
| 44 | 256 | Suttirat et al. (2026) | S. 4--5 | OK | S. 4--5 |
| 45 | 257 | Suttirat et al. (2026) | S. 5 | OK | S. 5 |
| 46 | 283 | Suttirat et al. (2026) | S. 5 | OK | S. 5 |
| 47 | 283 | Lowe et al. (2021) | S. e211 | OK | S. e211 (PDF S. 3) |
| 48 | 285 | Suttirat et al. (2026) | S. 5 | OK | S. 5 |
| 49 | 286 | Suttirat et al. (2026) | S. 5 | OK | S. 5 |
| 50 | 289 | Clarke et al. (2024) | S. 5 | OK | S. 5 |
| 51 | 290 | Suttirat et al. (2026) | S. 5 | OK | S. 5 |

---

## 2. Detailed Verification by Citation

### Citation #1
- **Draft line:** 58  
- **Draft text (German):**  
  > „Ein aktuelles Beispiel ist die Studie von Suttirat et al.\ (2026), die monatliche Fallzahlen des Dengue-hämorrhagischen Fiebers (DHF) für 77 Provinzen Thailands über 20 Jahre (2003--2022) mit Klima-, Fernerkundungs- und sozioökonomischen Daten verknüpft und mit XGBoost und SHAP analysiert (S.~5--8).“
- **Article & cited page:** Suttirat et al. (2026), S. 5--8
- **Verbatim passage from PDF:**  
  - S. 1 (Abstract): *„dengue hemorrhagic fever surveillance data (2003–2022) from 77 provinces, integrated with comprehensive environmental, climatic, and socioeconomic factors.“*  
  - S. 5 (Dengue case data): *„Data used in this study are monthly dengue hemorrhagic fever (DHF) case reports obtained from the Bureau of Epidemiology, Ministry of Public Health of Thailand [39] covering the 20-year period from 2003 to 2022. [...] The data were aggregated monthly, with cases from Buengkarn province incorporated into Nong Khai province after it was administratively separated from Nong Khai in 2011 for consistency.“*  
  - S. 5 (Climate & Socioeconomic): *„Climate data were extracted from the TerraClimate dataset [40] [...] Demographic data, including provincial population statistics and mean household size [...] Mean provincial household income data...“*  
  - S. 5--6 (Remote sensing): *„Remote-sensing features were obtained from the Moderate Resolution Imaging Spectroradiometer (MODIS)...“*  
  - S. 7--8 (Model development & Interpretation): *„Extreme Gradient Boosting (XGBoost) [...] SHapley Additive exPlanations (SHAP) was used to interpret feature contributions.“*
- **Verdict:** OK  
- **Justification:** Der referenzierte Methodenteil (S. 5--8) beschreibt die Zusammenführung der monatlichen DHF-Meldedaten, Klima-, Fernerkundungs- und sozioökonomischen Daten sowie die Analyse mit XGBoost und SHAP vollständig und sachlich zutreffend. Die Nennung von „77 Provinzen“ deckt sich mit dem Abstract (S. 1) und der zeitlichen Aggregation (S. 12), wenngleich auf S. 5 erläutert wird, dass Bueng Kan in Nong Khai rückintegriert wurde (76 Analyseeinheiten).

---

### Citation #2
- **Draft line:** 61  
- **Draft text (German):**  
  > „Lowe et al.\ (2021) untersuchen auf ähnliche Weise den Einfluss hydrometeorologischer Extreme und der Urbanisierung auf das Dengue-Risiko in 558 Mikroregionen Brasiliens (S.~e211--e212).“
- **Article & cited page:** Lowe et al. (2021), S. e211--e212 (PDF S. 3--4)
- **Verbatim passage from PDF:**  
  - S. e211: *„In this study, we aimed to extend this approach by designing a spatio-temporal model for Brazil to investigate the non-linear and delayed effects of hydrometeorological extremes across a large and varied geographical domain.“*  
  - S. e211: *„We obtained monthly notified dengue cases for each of the 558 microregions of Brazil between January, 2001, and December, 2019, from the Notifiable Diseases Information System, which is freely available via the Ministry of Health Information Department (DATASUS).“*  
  - S. e211--e212: *„To account for the hypothesis that the effects of drought on dengue vary by level of urbanisation and access to water supply services, we obtained data on the proportion of residents living in urban areas and with access to the piped water network from the 2010 census, from DATASUS. [...] We tested a linear interaction between the drought severity index DLNM and level of urbanisation.“*
- **Verdict:** OK  
- **Justification:** Alle genannten Elemente (558 Mikroregionen Brasiliens, hydrometeorologische Extreme, Urbanisierung, Modellierungsansatz) werden auf den Seiten e211--e212 genau so dargestellt.

---

### Citation #3 (Direct Quotation)
- **Draft lines:** 68--75  
- **Draft text (German):**  
  > `\enquote{Gridded climatic and remote-sensing data were spatially aggregated to`  
  > `the provincial level; lagged variables and bioclimatic indices were then derived`  
  > `from monthly provincial temperature and precipitation series. Socioeconomic data`  
  > `were obtained directly at the provincial level: the biennially reported household`  
  > `income series was linearly interpolated to fill missing years, and all`  
  > `socioeconomic series were then upsampled to monthly resolution by assigning each`  
  > `year's reported value (typically released at year-end) to every month of that`  
  > `year.} (Suttirat et al., 2026, S.~4)`
- **Article & cited page:** Suttirat et al. (2026), S. 4
- **Verbatim passage from PDF (S. 4):**  
  *„Gridded climatic and remote-sensing data were spatially aggregated to the provincial level; lagged variables and bioclimatic indices were then derived from monthly provincial temperature and precipitation series. Socioeconomic data were obtained directly at the provincial level: the biennially reported household income series was linearly interpolated to fill missing years, and all socioeconomic series were then upsampled to monthly resolution by assigning each year’s reported value (typically released at year-end) to every month of that year.“*
- **Verdict:** OK  
- **Justification:** Das Zitat stimmt Wort für Wort und Satzzeichen für Satzzeichen mit dem Quelltext auf S. 4 überein. Der einzige rein technische Unterschied ist das typographische Apostroph `’` (U+2019) im PDF gegenüber dem geraden ASCII-Apostroph `'` im LaTeX-Quelltext (`year's`), was in LaTeX standardmäßig zu `’` gerendert wird.

---

### Citation #4 (Direct Quotation & Sentence)
- **Draft lines:** 84--85  
- **Draft text (German):**  
  > „Sie beziehen monatliche Fallzahlen aus dem nationalen Meldesystem, berechnen mit jährlichen Bevölkerungsschätzungen die Inzidenz pro 100\,000 Einwohner, aggregieren gerasterte Klimadaten (Tmin, Tmax, PDSI) flächengewichtet auf die Untersuchungseinheiten und laden Klimadaten für ein zusätzliches Jahr vor der ersten Fallbeobachtung, \enquote{to allow for a lag period before the first dengue observation in January, 2001} (S.~e211).“
- **Article & cited page:** Lowe et al. (2021), S. e211 (PDF S. 3)
- **Verbatim passage from PDF (S. e211):**  
  - Direktzitat: *„to allow for a lag period before the first dengue observation in January, 2001“* (exakt wortwörtlich)  
  - Kontext: *„The monthly mean daily minimum temperature (Tmin; °C), maximum temperature (Tmax; °C), and the self-calibrated PDSI were obtained from the Climatic Research Unit gridded Time Series (version 4.04), for the period January, 2000, to December, 2019, at a spatial resolution of 0·5° longitude × 0·5° latitude (data for 2000 were extracted to allow for a lag period before the first dengue observation in January, 2001). The gridded datasets were aggregated to each microregion using the exactextractr package in R (version 4.0.2), by calculating the mean of grid boxes lying within each microregion. Grid boxes that were partially covered by the microregion were weighted by the percentage that lay within the microregion.“*  
  - Fallzahlen/Inzidenz: *„The Brazilian Ministry of Health defines the monthly dengue incidence rate as the number of new dengue cases per 100 000 residents per month. To calculate dengue incidence for each microregion, we obtained yearly population estimates for the 558 microregions between 2001 and 2019...“*
- **Verdict:** OK  
- **Justification:** Das wörtliche Zitat und sämtliche im Satz zusammengefassten Teilschritte stehen exakt und belegbar auf Seite e211.

---

### Citation #5
- **Draft lines:** 85--87  
- **Draft text (German):**  
  > „Auch Suttirat et al.\ erzeugen zeitverzögerte Variablen (Lags von 1--3 Monaten) für alle Klima- und Fernerkundungsvariablen (S.~7).“
- **Article & cited page:** Suttirat et al. (2026), S. 7
- **Verbatim passage from PDF (S. 7):**  
  *„Lagged variables. To capture delayed environmental effects on dengue transmission, we generated 1-, 2-, and 3-month lagged values for all climate and remote sensing variables, expanding our feature set to account for temporal interactions and classify each province-month as high- or low-risk based on the input features.“*
- **Verdict:** OK  
- **Justification:** Die Aussage entspricht exakt dem Abschnitt „Lagged variables“ auf Seite 7.

---

### Citation #6
- **Draft line:** 91  
- **Draft text (German):**  
  > „Lowe et al.\ nutzen ausschließlich offene Daten (S.~e218),...“
- **Article & cited page:** Lowe et al. (2021), S. e218 (PDF S. 10)
- **Verbatim passage from PDF (S. e218):**  
  *„Data sharing: All data used in this study is open access and freely available on the web or from the authors upon request (appendix 2 p 1).“*
- **Verdict:** OK  
- **Justification:** Die Aussage stützt sich unmittelbar auf die Erklärung unter „Data sharing“ auf Seite e218.

---

### Citation #7
- **Draft line:** 94  
- **Draft text (German):**  
  > „...die Zusammenstellung der Datenbank wird in den Autorenbeiträgen als eigene Aufgabe genannt (S.~e218).“
- **Article & cited page:** Lowe et al. (2021), S. e218 (PDF S. 10)
- **Verbatim passage from PDF (S. e218):**  
  *„Contributors: [...] SAL compiled the database and helped with visualisation and drafting of the manuscript.“*
- **Verdict:** OK  
- **Justification:** Im Abschnitt „Contributors“ auf Seite e218 wird die Kompilierung der Datenbank ausdrücklich als spezifischer Beitrag („SAL compiled the database“) aufgeführt.

---

### Citation #8 (Direct Quotation & Attribution)
- **Draft lines:** 99--102  
- **Draft text (German):**  
  > `Für die Gesundheitsdaten halten Clarke et al.\ (2024) bei der Beschreibung des OpenDengue-Datensatzes fest:`  
  > `\begin{quote}`  
  > `\enquote{Dengue case data exists in multiple formats from a wide variety of`  
  > `sources that require various processing methodologies. [\ldots] Locating,`  
  > `extracting, processing and standardising data all takes time but is essential to`  
  > `enable reuse and re-analysis.} (Clarke et al., 2024, S.~2)`  
  > `\end{quote}`
- **Article & cited page:** Clarke et al. (2024), S. 2
- **Verbatim passage from PDF (S. 2):**  
  *„Dengue case data exists in multiple formats from a wide variety of sources that require various processing methodologies17. Detailed source metadata is important to ensure case counts can be traced back to their original reporting source, and to enable assessment of comparability between sources. Locating, extracting, processing and standardising data all takes time but is essential to enable reuse and re-analysis17.“*
- **Verdict:** OVERCLAIM  
- **Justification:** Der Text der beiden Sätze ist zwar auf Seite 2 vorhanden und durch die Auslassung `[\ldots]` korrekt verknüpft. Allerdings tragen beide zitierten Sätze im Original die hochgestellte Quellenangabe `17` (Fairchild et al., 2018: *Epidemiological Data Challenges: Planning for a More Robust Future Through Data Standards*). Der Entwurf stellt diese allgemeine Feststellung als eigene Aussage von Clarke et al. bei der Datensatzbeschreibung dar, obwohl Clarke et al. hier die Vorarbeit von Fairchild et al. zitieren.
- **Suggested correction:** Im Text kenntlich machen, dass Clarke et al. hier eine vorbestehende Feststellung aus der Literatur zitieren, z. B.:  
  *„Für die Gesundheitsdaten verweisen Clarke et al. (2024, S. 2) unter Bezug auf Fairchild et al. (2018) auf die grundlegende Hürde: \enquote{Dengue case data exists in multiple formats from a wide variety of sources that require various processing methodologies. [\ldots] Locating, extracting, processing and standardising data all takes time but is essential to enable reuse and re-analysis.}“*

---

### Citation #9
- **Draft line:** 106  
- **Draft text (German):**  
  > „Die Verknüpfung mit Klimadaten, die Clarke et al.\ als einen Anwendungsfall nennen (S.~1, 9), bleibt jedoch Aufgabe der Forschenden.“
- **Article & cited page:** Clarke et al. (2024), S. 1, 9
- **Verbatim passage from PDF:**  
  - S. 1: *„Gathering data across all dengue endemic regions would enable re-analysis to better understand the drivers of transmission, monitor progress towards disease reduction targets, evaluate the impact of public health interventions and model the possible future burden and spatial limits under different climate scenarios.“*  
  - S. 9 (Usage Notes): *„OpenDengue draws together and standardises data from multiple sources that enable new analyses at global and regional scales. Examples include identifying worst affected areas and years, understanding drivers of transmission such as climate factors and interventions and predicting future trends and outbreak risk.“*
- **Verdict:** OK  
- **Justification:** Auf Seite 1 und Seite 9 („Usage Notes“) wird die Verknüpfung mit Klimadaten bzw. Klimaszenarien ausdrücklich als exemplarisches Anwendungsfeld für Nachanalysen genannt.

---

### Citation #10
- **Draft line:** 111  
- **Draft text (German):**  
  > „Suttirat et al.\ führten die Datenaufbereitung mit Python (pandas) durch und berechneten bioklimatische Indikatoren mit dem R-Paket \texttt{dismo} (S.~5, 8).“
- **Article & cited page:** Suttirat et al. (2026), S. 5, 8
- **Verbatim passage from PDF:**  
  - S. 5: *„The household income series, reported biennially by the Thai authorities, was linearly interpolated using the pandas interpolate method to fill missing years.“*  
  - S. 5: *„Additionally, we derived 19 bioclimatic indicators from monthly temperature and precipitation data using the R package ‘dismo’ [41,42].“*  
  - S. 8: *„hyperparameters were optimized using the Tree-Structured Parzen Estimator (TPE) algorithm implemented in the Python package ‘Optuna’ [46].“*
- **Verdict:** WRONG_PAGE  
- **Justification:** Die Datenaufbereitung mit Python/pandas (Interpolation des Haushaltseinkommens) und die Berechnung der bioklimatischen Variablen mit R/dismo befinden sich beide vollständig auf Seite 5. Auf Seite 8 wird das Python-Paket Optuna ausschließlich für das Hyperparameter-Tuning der Modelle beschrieben, nicht für die Datenaufbereitung.
- **Suggested correction:** Seitenangabe korrigieren auf `(S.~5)` oder präzisieren:  
  *„Suttirat et al. führten die Datenaufbereitung mit Python (pandas) durch und berechneten bioklimatische Indikatoren mit dem R-Paket 	exttt{dismo} (S.~5); für die Hyperparameter-Optimierung nutzten sie das Python-Paket 	exttt{Optuna} (S.~8).“*

---

### Citation #11
- **Draft line:** 192 (Tabelle 1)  
- **Draft text (German):**  
  > `Fallzahlen beziehen & monatliche DHF-Fälle, Bureau of Epidemiology (S.~5)`
- **Article & cited page:** Suttirat et al. (2026), S. 5
- **Verbatim passage from PDF (S. 5):**  
  *„Dengue case data. Data used in this study are monthly dengue hemorrhagic fever (DHF) case reports obtained from the Bureau of Epidemiology, Ministry of Public Health of Thailand [39] covering the 20-year period from 2003 to 2022.“*
- **Verdict:** OK  
- **Justification:** Quelle und Aggregationsebene stimmen exakt mit Seite 5 überein.

---

### Citation #12
- **Draft line:** 193 (Tabelle 1)  
- **Draft text (German):**  
  > `monatliche Meldefälle, SINAN/DATASUS (S.~e211)`
- **Article & cited page:** Lowe et al. (2021), S. e211 (PDF S. 3)
- **Verbatim passage from PDF (S. e211):**  
  *„We obtained monthly notified dengue cases for each of the 558 microregions of Brazil between January, 2001, and December, 2019, from the Notifiable Diseases Information System, which is freely available via the Ministry of Health Information Department (DATASUS).“*
- **Verdict:** OK  
- **Justification:** Die Entnahme monatlicher Meldefälle über SINAN/DATASUS ist auf Seite e211 belegt.

---

### Citation #13
- **Draft line:** 194 (Tabelle 1)  
- **Draft text (German):**  
  > `Verwaltungseinheiten harmonisieren & Bueng Kan in Nong Khai zusammengeführt (S.~5)`
- **Article & cited page:** Suttirat et al. (2026), S. 5
- **Verbatim passage from PDF (S. 5):**  
  *„The data were aggregated monthly, with cases from Buengkarn province incorporated into Nong Khai province after it was administratively separated from Nong Khai in 2011 for consistency.“*
- **Verdict:** OK  
- **Justification:** Die Zusammenführung von Buengkarn (Bueng Kan) und Nong Khai zur Wahrung der zeitlichen Konsistenz steht wörtlich auf Seite 5.

---

### Citation #14
- **Draft line:** 195 (Tabelle 1)  
- **Draft text (German):**  
  > `Klimavariablen beziehen & TerraClimate: u.\,a.\ Niederschlag, Tmin, Tmax (S.~5)`
- **Article & cited page:** Suttirat et al. (2026), S. 5
- **Verbatim passage from PDF (S. 5):**  
  *„Climate variables. Climate data were extracted from the TerraClimate dataset [40], which provides high-resolution (1/24°, ~4 km) monthly gridded data covering the 2003–2022 period... We obtained six primary variables: precipitation, minimum temperature, maximum temperature, soil moisture, vapor pressure, and wind speed.“*
- **Verdict:** OK  
- **Justification:** TerraClimate als Quelle sowie Niederschlag, Tmin und Tmax stehen auf Seite 5.

---

### Citation #15
- **Draft line:** 196 (Tabelle 1)  
- **Draft text (German):**  
  > `CRU TS 4.04: Tmin, Tmax, PDSI (S.~e211)`
- **Article & cited page:** Lowe et al. (2021), S. e211 (PDF S. 3)
- **Verbatim passage from PDF (S. e211):**  
  *„The monthly mean daily minimum temperature (Tmin; °C), maximum temperature (Tmax; °C), and the self-calibrated PDSI were obtained from the Climatic Research Unit gridded Time Series (version 4.04), for the period January, 2000, to December, 2019, at a spatial resolution of 0·5° longitude × 0·5° latitude...“*
- **Verdict:** OK  
- **Justification:** Quelle CRU TS 4.04 und die drei Variablen stehen auf Seite e211.

---

### Citation #16
- **Draft line:** 197 (Tabelle 1)  
- **Draft text (German):**  
  > `Räumliche Aggregation & Raster auf Provinzebene gemittelt, Methode nicht angegeben (S.~5)`
- **Article & cited page:** Suttirat et al. (2026), S. 5
- **Verbatim passage from PDF (S. 5):**  
  *„These gridded data were spatially averaged to the provincial level to match our epidemiological units.“*
- **Verdict:** OK  
- **Justification:** Die Autoren schreiben lediglich „spatially averaged to the provincial level“, ohne Details wie Flächengewichtung zu nennen; der Zusatz „Methode nicht angegeben“ ist daher vollkommen korrekt.

---

### Citation #17
- **Draft line:** 198 (Tabelle 1)  
- **Draft text (German):**  
  > `flächengewichtetes Mittel mit \texttt{exactextractr} (S.~e211)`
- **Article & cited page:** Lowe et al. (2021), S. e211 (PDF S. 3)
- **Verbatim passage from PDF (S. e211):**  
  *„The gridded datasets were aggregated to each microregion using the exactextractr package in R (version 4.0.2), by calculating the mean of grid boxes lying within each microregion. Grid boxes that were partially covered by the microregion were weighted by the percentage that lay within the microregion.“*
- **Verdict:** OK  
- **Justification:** Die flächengewichtete Mittelung mit dem Paket exactextractr wird auf Seite e211 explizit ausgeführt.

---

### Citation #18
- **Draft line:** 199 (Tabelle 1)  
- **Draft text (German):**  
  > `Zeitverzögerte Variablen & Lags 1--3 Monate (S.~7)`
- **Article & cited page:** Suttirat et al. (2026), S. 7
- **Verbatim passage from PDF (S. 7):**  
  *„Lagged variables. To capture delayed environmental effects on dengue transmission, we generated 1-, 2-, and 3-month lagged values for all climate and remote sensing variables...“*
- **Verdict:** OK  
- **Justification:** Die Lags 1--3 Monate stehen auf Seite 7.

---

### Citation #19
- **Draft line:** 199 (Tabelle 1)  
- **Draft text (German):**  
  > `Lags 0--6 Monate (DLNM, S.~e212)`
- **Article & cited page:** Lowe et al. (2021), S. e212 (PDF S. 4)
- **Verbatim passage from PDF (S. e212):**  
  *„DLNMs were used to explore possible non-linear and delayed associations between dengue incidence, temperature (Tmin and Tmax), and the PDSI from 0 to 6 months.“*
- **Verdict:** OK  
- **Justification:** DLNM und der Verzögerungszeitraum 0--6 Monate sind auf Seite e212 dokumentiert.

---

### Citation #20
- **Draft line:** 200 (Tabelle 1)  
- **Draft text (German):**  
  > `Puffer für Lags & -- & Klimadaten ein Jahr vor Beginn der Fallreihe (S.~e211)`
- **Article & cited page:** Lowe et al. (2021), S. e211 (PDF S. 3)
- **Verbatim passage from PDF (S. e211):**  
  *„(data for 2000 were extracted to allow for a lag period before the first dengue observation in January, 2001).“*
- **Verdict:** OK  
- **Justification:** Die Entnahme des Vorjahres 2000 als Puffer für die Fallreihe ab 2001 ist auf Seite e211 belegt.

---

### Citation #21
- **Draft line:** 201 (Tabelle 1)  
- **Draft text (German):**  
  > `Inzidenz pro 100\,000 & ja (S.~7)`
- **Article & cited page:** Suttirat et al. (2026), S. 7
- **Verbatim passage from PDF (S. 7):**  
  *„We calculated monthly DHF incidence rates per 100,000 population for each province.“*
- **Verdict:** OK  
- **Justification:** Die Berechnung der Inzidenz pro 100.000 Einwohner steht auf Seite 7.

---

### Citation #22
- **Draft line:** 201 (Tabelle 1)  
- **Draft text (German):**  
  > `ja, mit jährlicher Bevölkerung (S.~e211)`
- **Article & cited page:** Lowe et al. (2021), S. e211 (PDF S. 3)
- **Verbatim passage from PDF (S. e211):**  
  *„The Brazilian Ministry of Health defines the monthly dengue incidence rate as the number of new dengue cases per 100 000 residents per month. To calculate dengue incidence for each microregion, we obtained yearly population estimates for the 558 microregions between 2001 and 2019, from the Brazilian Institute of Geography and Statistics via DATASUS.“*
- **Verdict:** OK  
- **Justification:** Die Inzidenzberechnung pro 100.000 mit jährlichen Bevölkerungsschätzungen steht auf Seite e211.

---

### Citation #23
- **Draft line:** 202 (Tabelle 1)  
- **Draft text (German):**  
  > `Jahreswerte $\rightarrow$ Monate & Jahreswert jedem Monat zugeordnet (S.~4--5)`
- **Article & cited page:** Suttirat et al. (2026), S. 4--5
- **Verbatim passage from PDF:**  
  - S. 4: *„by assigning each year’s reported value (typically released at year-end) to every month of that year.“*  
  - S. 5: *„All socioeconomic series were then upsampled from annual to monthly resolution by assigning each year’s reported value to every month of that year, on the assumption that annual socioeconomic conditions provide a stable baseline for intra-annual analysis.“*
- **Verdict:** OK  
- **Justification:** Das Verfahren des Zuweisens des Jahreswerts an jeden Monat wird auf S. 4 und S. 5 beschrieben.

---

### Citation #24
- **Draft line:** 204 (Tabelle 1)  
- **Draft text (German):**  
  > `Fehlende Jahre auffüllen & Haushaltseinkommen linear interpoliert (S.~5)`
- **Article & cited page:** Suttirat et al. (2026), S. 5
- **Verbatim passage from PDF (S. 5):**  
  *„The household income series, reported biennially by the Thai authorities, was linearly interpolated using the pandas interpolate method to fill missing years.“*
- **Verdict:** OK  
- **Justification:** Die lineare Interpolation der zweijährlichen Einkommensdaten steht auf Seite 5 (auch auf S. 4 kurz zusammengefasst).

---

### Citation #25
- **Draft line:** 205 (Tabelle 1)  
- **Draft text (German):**  
  > `Abgeleitete Indizes & 19 bioklimatische Indikatoren (\texttt{dismo}, S.~5)`
- **Article & cited page:** Suttirat et al. (2026), S. 5
- **Verbatim passage from PDF (S. 5):**  
  *„Additionally, we derived 19 bioclimatic indicators from monthly temperature and precipitation data using the R package ‘dismo’ [41,42].“*
- **Verdict:** OK  
- **Justification:** Die Ableitung der 19 bioklimatischen Indikatoren mit dem R-Paket dismo ist auf Seite 5 belegt.

---

### Citation #26
- **Draft line:** 206 (Tabelle 1)  
- **Draft text (German):**  
  > `Werkzeuge & Python/pandas, R (S.~5, 8)`
- **Article & cited page:** Suttirat et al. (2026), S. 5, 8
- **Verbatim passage from PDF:**  
  - S. 5: *„pandas interpolate method“* und *„R package ‘dismo’“*  
  - S. 8: *„Python package ‘Optuna’“*
- **Verdict:** OK  
- **Justification:** Auf Seite 5 wird pandas und R (dismo) erwähnt, auf Seite 8 Python (Optuna). Zusammengenommen belegen die Seiten 5 und 8 die verwendeten Werkzeuge.

---

### Citation #27
- **Draft line:** 206 (Tabelle 1)  
- **Draft text (German):**  
  > `R, \texttt{exactextractr}, R-INLA (S.~e211--e212)`
- **Article & cited page:** Lowe et al. (2021), S. e211--e212 (PDF S. 3--4)
- **Verbatim passage from PDF:**  
  - S. e211: *„exactextractr package in R (version 4.0.2)“*  
  - S. e212: *„integrated nested Laplace approximations in R version 4.0.2 (appendix 2 p 2).29,30“* (Referenz 30 auf S. e218: *„Lindgren F, Rue H. Bayesian spatial modelling with R-INLA.“*)
- **Verdict:** OK  
- **Justification:** R, exactextractr und INLA werden auf den Seiten e211--e212 genannt. Das Akronym „R-INLA“ ist über Referenz 30 belegt.

---

### Citation #28
- **Draft line:** 222 (Tabelle 2)  
- **Draft text (German):**  
  > `Inzidenz pro 100\,000 als Zielgröße & Suttirat S.~7; Lowe S.~e211`
- **Article & cited page:** Suttirat et al. (2026), S. 7
- **Verbatim passage from PDF (S. 7):**  
  *„We calculated monthly DHF incidence rates per 100,000 population for each province. Using the national median incidence from the training period (2.78 per 100,000) as our classification threshold...“*
- **Verdict:** OK  
- **Justification:** Inzidenz pro 100.000 als Ziel-/Schwellengröße steht auf Seite 7.

---

### Citation #29
- **Draft line:** 222 (Tabelle 2)  
- **Draft text (German):**  
  > `Inzidenz pro 100\,000 als Zielgröße & Suttirat S.~7; Lowe S.~e211`
- **Article & cited page:** Lowe et al. (2021), S. e211 (PDF S. 3)
- **Verbatim passage from PDF (S. e211):**  
  *„The Brazilian Ministry of Health defines the monthly dengue incidence rate as the number of new dengue cases per 100 000 residents per month. To calculate dengue incidence for each microregion, we obtained yearly population estimates...“*
- **Verdict:** OK  
- **Justification:** Inzidenz pro 100.000 steht auf Seite e211.

---

### Citation #30
- **Draft line:** 224 (Tabelle 2)  
- **Draft text (German):**  
  > `Jährliche Bevölkerung, monatliche Fallzahlen & Suttirat S.~4--5 (Jahreswert jedem Monat zugeordnet); Lowe: Verfahren nicht beschrieben`
- **Article & cited page:** Suttirat et al. (2026), S. 4--5
- **Verbatim passage from PDF (S. 4--5):**  
  - S. 4: *„all socioeconomic series were then upsampled to monthly resolution by assigning each year’s reported value (typically released at year-end) to every month of that year.“*  
  - S. 5: *„Demographic data, including provincial population statistics and mean household size [...] All socioeconomic series were then upsampled from annual to monthly resolution by assigning each year’s reported value to every month of that year...“*
- **Verdict:** OK  
- **Justification:** Das Verfahren der monatlichen Zuweisung jährlicher demographischer/sozioökonomischer Werte steht auf den Seiten 4--5.

---

### Citation #31
- **Draft line:** 226 (Tabelle 2)  
- **Draft text (German):**  
  > `Zeitverzögerte Klimavariablen & Suttirat S.~7 (1--3); Lowe S.~e212 (0--6)`
- **Article & cited page:** Suttirat et al. (2026), S. 7
- **Verbatim passage from PDF (S. 7):**  
  *„Lagged variables. To capture delayed environmental effects on dengue transmission, we generated 1-, 2-, and 3-month lagged values for all climate and remote sensing variables...“*
- **Verdict:** OK  
- **Justification:** Lags von 1--3 Monaten stehen auf Seite 7.

---

### Citation #32
- **Draft line:** 226 (Tabelle 2)  
- **Draft text (German):**  
  > `Zeitverzögerte Klimavariablen & Suttirat S.~7 (1--3); Lowe S.~e212 (0--6)`
- **Article & cited page:** Lowe et al. (2021), S. e212 (PDF S. 4)
- **Verbatim passage from PDF (S. e212):**  
  *„DLNMs were used to explore possible non-linear and delayed associations between dengue incidence, temperature (Tmin and Tmax), and the PDSI from 0 to 6 months.“*
- **Verdict:** OK  
- **Justification:** Lags von 0--6 Monaten mittels DLNM stehen auf Seite e212.

---

### Citation #33
- **Draft line:** 228 (Tabelle 2)  
- **Draft text (German):**  
  > `Klimadaten vor Beginn der Fallreihe & Lowe S.~e211`
- **Article & cited page:** Lowe et al. (2021), S. e211 (PDF S. 3)
- **Verbatim passage from PDF (S. e211):**  
  *„(data for 2000 were extracted to allow for a lag period before the first dengue observation in January, 2001).“*
- **Verdict:** OK  
- **Justification:** Der Vorlauf an Klimadaten vor dem ersten Fallbeobachtungsmonat ist auf Seite e211 belegt.

---

### Citation #34
- **Draft line:** 230 (Tabelle 2)  
- **Draft text (German):**  
  > `Tmin/Tmax statt nur Mitteltemperatur & Suttirat S.~5; Lowe S.~e211`
- **Article & cited page:** Suttirat et al. (2026), S. 5
- **Verbatim passage from PDF (S. 5):**  
  *„We obtained six primary variables: precipitation, minimum temperature, maximum temperature, soil moisture, vapor pressure, and wind speed.“*
- **Verdict:** OK  
- **Justification:** Die Verwendung von Tmin und Tmax steht auf Seite 5.

---

### Citation #35
- **Draft line:** 230 (Tabelle 2)  
- **Draft text (German):**  
  > `Tmin/Tmax statt nur Mitteltemperatur & Suttirat S.~5; Lowe S.~e211`
- **Article & cited page:** Lowe et al. (2021), S. e211 (PDF S. 3)
- **Verbatim passage from PDF (S. e211):**  
  *„The monthly mean daily minimum temperature (Tmin; °C), maximum temperature (Tmax; °C)... were obtained from the Climatic Research Unit...“*
- **Verdict:** OK  
- **Justification:** Tmin und Tmax aus CRU TS stehen auf Seite e211.

---

### Citation #36
- **Draft line:** 232 (Tabelle 2)  
- **Draft text (German):**  
  > `Unterschiedliche zeitliche Auflösungen & Suttirat S.~4--5`
- **Article & cited page:** Suttirat et al. (2026), S. 4--5
- **Verbatim passage from PDF (S. 4--5):**  
  *„Socioeconomic data were obtained directly at the provincial level: the biennially reported household income series was linearly interpolated to fill missing years, and all socioeconomic series were then upsampled to monthly resolution...“*
- **Verdict:** OK  
- **Justification:** Die Koexistenz monatlicher, zweijährlicher und jährlicher Datenreihen und ihre Vereinheitlichung werden auf den Seiten 4--5 ausgeführt.

---

### Citation #37
- **Draft line:** 234 (Tabelle 2)  
- **Draft text (German):**  
  > `Herkunft muss nachvollziehbar sein; Version angeben & Clarke S.~2, 4, 12`
- **Article & cited page:** Clarke et al. (2024), S. 2, 4, 12
- **Verbatim passage from PDF:**  
  - S. 2: *„Detailed source metadata is important to ensure case counts can be traced back to their original reporting source, and to enable assessment of comparability between sources.“*  
  - S. 4: *„A standardised naming protocol was established to prevent duplicate source file names. A customised Universally Unique Identifier (UUID) for each source file was generated [...] Both the main OpenDengue data and the source data are accompanied by separate detailed “.json” format metadata files in the Figshare repository.“*  
  - S. 12: *„Dataset version control. [...] It is recommended for users to specify which version of the dataset was used [...] Where possible, we encourage users to also cite the original sources of the data which can be identified from the source data file using the record UUID.“*
- **Verdict:** OK  
- **Justification:** Metadaten, Quellenrückverfolgbarkeit und Versionierungsrichtlinien sind auf den Seiten 2, 4 und 12 explizit dargelegt.

---

### Citation #38
- **Draft line:** 236 (Tabelle 2)  
- **Draft text (German):**  
  > `Räumliche Abdeckung variiert zwischen Ländern (subnational nur für 40 von 102 Ländern) & Clarke S.~1, 8`
- **Article & cited page:** Clarke et al. (2024), S. 1, 8
- **Verbatim passage from PDF:**  
  - S. 1: *„information on over 56 million dengue cases from 102 countries between 1924 and 2023 [...] and subnational data is available for 40 countries.“*  
  - S. 8: *„cases distributed over 102 countries for the time period 1924–2023. We combine data from 843 different sources with 99.8% of the data records being at weekly or monthly temporal resolution and sub-national data is available for 40 countries.“*
- **Verdict:** OK  
- **Justification:** Die Zahlenangaben (subnationale Daten für 40 von 102 Ländern) stehen wörtlich auf Seite 1 und Seite 8.

---

### Citation #39
- **Draft line:** 238 (Tabelle 2)  
- **Draft text (German):**  
  > `Vergleichbarkeit zwischen Quellen beurteilen & Clarke S.~2`
- **Article & cited page:** Clarke et al. (2024), S. 2
- **Verbatim passage from PDF (S. 2):**  
  *„Detailed source metadata is important to ensure case counts can be traced back to their original reporting source, and to enable assessment of comparability between sources.“*
- **Verdict:** OK  
- **Justification:** Die Notwendigkeit zur Beurteilung der Vergleichbarkeit zwischen Quellen steht auf Seite 2.

---

### Citation #40
- **Draft line:** 240 (Tabelle 2)  
- **Draft text (German):**  
  > `Zusammenhänge explorativ prüfen & Lags: Suttirat S.~7; Lowe S.~e212`
- **Article & cited page:** Suttirat et al. (2026), S. 7
- **Verbatim passage from PDF (S. 7):**  
  *„Lagged variables. To capture delayed environmental effects on dengue transmission, we generated 1-, 2-, and 3-month lagged values for all climate and remote sensing variables, expanding our feature set to account for temporal interactions...“*
- **Verdict:** OK  
- **Justification:** Die Erzeugung der zeitverzögerten Variablen zur Erfassung verzögerter Umwelteinflüsse steht auf Seite 7.

---

### Citation #41
- **Draft line:** 240 (Tabelle 2)  
- **Draft text (German):**  
  > `Zusammenhänge explorativ prüfen & Lags: Suttirat S.~7; Lowe S.~e212`
- **Article & cited page:** Lowe et al. (2021), S. e212 (PDF S. 4)
- **Verbatim passage from PDF (S. e212):**  
  *„DLNMs were used to explore possible non-linear and delayed associations between dengue incidence, temperature (Tmin and Tmax), and the PDSI from 0 to 6 months.“*
- **Verdict:** OK  
- **Justification:** Die Exploration verzögerter Zusammenhänge über DLNMs (0--6 Monate) steht auf Seite e212.

---

### Citation #42
- **Draft line:** 247  
- **Draft text (German):**  
  > „Korrelationen erfassen keine nichtlinearen Schwelleneffekte, wie sie Suttirat et al.\ fanden (etwa 21\,°C für Tmin mit Lag~1 und 32\,°C für Tmax mit Lag~3, S.~12);...“
- **Article & cited page:** Suttirat et al. (2026), S. 12
- **Verbatim passage from PDF (S. 12):**  
  *„The relationship between 1-month lagged minimum temperature (tmin-1) and dengue risk exhibited a distinct threshold effect: temperatures below approximately 21°C were negatively associated with transmission... Similarly, tmax-3 demonstrated a nonlinear response with a critical threshold at approximately 32°C, beyond which dengue risk increased markedly.“*
- **Verdict:** OK  
- **Justification:** Die Schwellenwerte von ca. 21 °C für tmin-1 und 32 °C für tmax-3 sind auf Seite 12 explizit genannt.

---

### Citation #43 (Direct Quotation)
- **Draft lines:** 248--249  
- **Draft text (German):**  
  > „...Lowe et al.\ betonen, dass der Einfluss des Klimas \enquote{complex, non-linear, and often delayed} ist (S.~e211).“
- **Article & cited page:** Lowe et al. (2021), S. e211 (PDF S. 3)
- **Verbatim passage from PDF (S. e211):**  
  *„The effect of climate variability and climate change on dengue transmission is complex, non-linear, and often delayed by several weeks to months, which limits the inferences that can be made from traditional linear modelling methods.“*
- **Verdict:** OK  
- **Justification:** Die Wendung ist wortwörtlich auf Seite e211 vorhanden und inhaltlich exakt wiedergegeben.

---

### Citation #44
- **Draft line:** 256  
- **Draft text (German):**  
  > „Suttirat et al.\ ordnen jährliche sozioökonomische Werte jedem Monat des Jahres zu (S.~4--5)...“
- **Article & cited page:** Suttirat et al. (2026), S. 4--5
- **Verbatim passage from PDF:**  
  - S. 4: *„by assigning each year’s reported value (typically released at year-end) to every month of that year.“*  
  - S. 5: *„All socioeconomic series were then upsampled from annual to monthly resolution by assigning each year’s reported value to every month of that year...“*
- **Verdict:** OK  
- **Justification:** Das Upsampling durch monatliche Zuweisung wird auf S. 4--5 beschrieben.

---

### Citation #45
- **Draft line:** 257  
- **Draft text (German):**  
  > „...und füllen fehlende Jahre des Haushaltseinkommens durch lineare Interpolation (S.~5);...“
- **Article & cited page:** Suttirat et al. (2026), S. 5
- **Verbatim passage from PDF (S. 5):**  
  *„The household income series, reported biennially by the Thai authorities, was linearly interpolated using the pandas interpolate method to fill missing years.“*
- **Verdict:** OK  
- **Justification:** Die lineare Interpolation des Haushaltseinkommens steht auf Seite 5.

---

### Citation #46
- **Draft line:** 283  
- **Draft text (German):**  
  > `\item subnationale Einheiten und räumliche Aggregation von Rasterdaten (Suttirat S.~5; Lowe S.~e211) -- das System nutzt einen repräsentativen Punkt pro Land;`
- **Article & cited page:** Suttirat et al. (2026), S. 5
- **Verbatim passage from PDF (S. 5):**  
  *„These gridded data were spatially averaged to the provincial level to match our epidemiological units.“*
- **Verdict:** OK  
- **Justification:** Die Aggregation von Rasterdaten auf subnationale Einheiten (Provinzen) steht auf Seite 5.

---

### Citation #47
- **Draft line:** 283  
- **Draft text (German):**  
  > `\item subnationale Einheiten und räumliche Aggregation von Rasterdaten (Suttirat S.~5; Lowe S.~e211) -- das System nutzt einen repräsentativen Punkt pro Land;`
- **Article & cited page:** Lowe et al. (2021), S. e211 (PDF S. 3)
- **Verbatim passage from PDF (S. e211):**  
  *„The gridded datasets were aggregated to each microregion using the exactextractr package in R (version 4.0.2), by calculating the mean of grid boxes lying within each microregion.“*
- **Verdict:** OK  
- **Justification:** Die Aggregation von Rasterdaten auf Mikroregionen steht auf Seite e211.

---

### Citation #48
- **Draft line:** 285  
- **Draft text (German):**  
  > `\item Harmonisierung sich ändernder Verwaltungseinheiten (Suttirat S.~5);`
- **Article & cited page:** Suttirat et al. (2026), S. 5
- **Verbatim passage from PDF (S. 5):**  
  *„cases from Buengkarn province incorporated into Nong Khai province after it was administratively separated from Nong Khai in 2011 for consistency.“*
- **Verdict:** OK  
- **Justification:** Die Harmonisierung der 2011 neu gegründeten Provinz Buengkarn steht auf Seite 5.

---

### Citation #49
- **Draft line:** 286  
- **Draft text (German):**  
  > `\item bioklimatische Indikatoren und Fernerkundungsdaten (Suttirat S.~5);`
- **Article & cited page:** Suttirat et al. (2026), S. 5
- **Verbatim passage from PDF (S. 5):**  
  *„Additionally, we derived 19 bioclimatic indicators from monthly temperature and precipitation data using the R package ‘dismo’ [41,42]. [...] Remote-sensing features were obtained from the Moderate Resolution Imaging Spectroradiometer (MODIS)...“*
- **Verdict:** OK  
- **Justification:** Beide Datenarten werden auf Seite 5 eingeführt (Tabelle zu Fernerkundung reicht bis S. 6).

---

### Citation #50
- **Draft line:** 289  
- **Draft text (German):**  
  > `OpenDengue zählt alle gemeldeten Fälle (Clarke S.~5),...`
- **Article & cited page:** Clarke et al. (2024), S. 5
- **Verbatim passage from PDF (S. 5):**  
  *„The OpenDengue version 1.2 dataset contains reported total case counts with each row including all reported clinical manifestations (dengue fever, severe dengue, dengue shock syndrome, dengue deaths) and methods of confirmation (suspected, probable, clinically confirmed, laboratory confirmed) in the variable “dengue_total”.“*
- **Verdict:** OK  
- **Justification:** OpenDengue fasst in `dengue_total` alle Manifestationen und Bestätigungsgrade zusammen; dies ist auf Seite 5 dokumentiert.

---

### Citation #51
- **Draft line:** 290  
- **Draft text (German):**  
  > `...Suttirat et al.\ nur DHF (S.~5) --, sodass eine verdeckte Mischung die Vergleichbarkeit beeinträchtigen würde.`
- **Article & cited page:** Suttirat et al. (2026), S. 5
- **Verbatim passage from PDF (S. 5):**  
  *„Dengue case data. Data used in this study are monthly dengue hemorrhagic fever (DHF) case reports obtained from the Bureau of Epidemiology, Ministry of Public Health of Thailand [39]...“*
- **Verdict:** OK  
- **Justification:** Suttirat et al. beschränken sich ausdrücklich auf DHF-Fallberichte (Seite 5).

---

## 3. Reference List Check (Section C)

| # | Reference entry in draft | Status | Comparison with PDF Page 1 |
|---|---|---|---|
| C1 | **Clarke et al. (2024)**<br>`Clarke, J., Lim, A., Gupte, P., Pigott, D.\,M., van Panhuis, W.\,G., \& Brady, O.\,J. (2024). A global dataset of publicly available dengue case count data. Scientific Data, 11, 296.`<br>`DOI: https://doi.org/10.1038/s41597-024-03120-7` | **OK** | Alle 6 Autoren, Reihenfolge und Initialen stimmen mit PDF S. 1 überein (`J. Clarke, A. Lim, P. Gupte, D. M. Pigott, W. G. van Panhuis & O. J. Brady`). Titel, Jahr (2024), Zeitschrift (*Scientific Data*), Band (11), Artikelnummer (296) und DOI stimmen exakt überein. |
| C2 | **Lowe et al. (2021)**<br>`Lowe, R., Lee, S.\,A., O'Reilly, K.\,M., Brady, O.\,J., Bastos, L., Carrasco-Escobar, G., et al.\ (2021). Combined effects of hydrometeorological hazards and urbanisation on dengue risk in Brazil: a spatiotemporal modelling study. The Lancet Planetary Health, 5(4), e209--e219.`<br>`DOI: https://doi.org/10.1016/S2542-5196(20)30292-8` | **OK** | Die ersten 6 Autoren stimmen in Reihenfolge und Initialen exakt überein (`Rachel Lowe, Sophie A Lee, Kathleen M O’Reilly, Oliver J Brady, Leonardo Bastos, Gabriel Carrasco-Escobar`), gefolgt von `et al.` (insgesamt 13 Autoren). Titel, Jahr (2021), Zeitschrift (*The Lancet Planetary Health*), Band/Ausgabe (5(4)), Seitenspanne (e209--e219) und DOI stimmen exakt überein. |
| C3 | **Suttirat et al. (2026)**<br>`Suttirat, P., Chadsuthi, S., Aekthong, S., Rocklöv, J., Bicout, D.\,J., Haddawy, P., Su Yin, M., Lawpoolsri, S., \& Modchang, C. (2026). Machine learning reveals temperature as a key predictor of dengue risk across Thailand's provinces: A 20-year analysis. PLoS Neglected Tropical Diseases, 20(7), e0014590.`<br>`DOI: https://doi.org/10.1371/journal.pntd.0014590` | **OK** | Alle 9 Autoren stimmen überein (`Pikkanet Suttirat, Sudarat Chadsuthi, Supassorn Aekthong, Joacim Rocklöv, Dominique J. Bicout, Peter Haddawy, Myat Su Yin, Saranath Lawpoolsri, Charin Modchang`). Bei Autor 7 ist `Su Yin, M.` die bibliographische Ansetzung für den burmesischen Namen *Myat Su Yin*. Titel, Jahr (2026), Zeitschrift (*PLoS Neglected Tropical Diseases*), Band/Ausgabe (20(7)), Artikel-ID (e0014590) und DOI stimmen exakt überein. |

---

## 4. Citations with Uncertainties or Special Considerations

1. **Citation #10 (Zeile 111 – Suttirat S. 5, 8 vs. Datenaufbereitung):**  
   *Problem:* Der Text nennt S. 5 und 8 als Beleg für die Datenaufbereitung mit Python/pandas und R/dismo. Auf S. 5 stehen die Interpolation mit `pandas` und die Bioklima-Indikatoren mit `dismo`. S. 8 beschreibt jedoch die Optimierung der Hyperparameter von XGBoost etc. mit dem Python-Paket `Optuna`. Da Optuna nicht zur Datenaufbereitung gehört, ist S. 8 hier streng genommen fehl am Platz (bzw. S. 8 belegt lediglich das Vorhandensein von Python im Workflow).  
   *Empfehlung:* Zitation auf `(S.~5)` kürzen oder präzisieren: `...Datenaufbereitung mit Python (pandas) und R (dismo) (S.~5); Modelloptimierung mit Python/Optuna (S.~8)`.

2. **Citation #8 (Zeilen 99--102 – Zitat Clarke et al. S. 2 & Fairchild et al.):**  
   *Problem:* Das Zitat ist zwar auf Seite 2 vorhanden, aber beide Sätze tragen im Original die Referenznummer 17 (Fairchild et al., 2018). Im Entwurf wird das Zitat mit „halten Clarke et al. (2024) bei der Beschreibung des OpenDengue-Datensatzes fest“ eingeführt. Das kann als Zuschreibung eines fremden Befunds als eigener Befund der Autoren verstanden werden (Overclaiming im Sinne von Frage 3 der Prüfrichtlinien).  
   *Empfehlung:* Im Begleittext darauf hinweisen, dass Clarke et al. hier die allgemeine epidemiologische Datenproblematik unter Bezugnahme auf Fairchild et al. (2018) resümieren.

3. **Citation #1 (Zeile 58 – Suttirat 77 Provinzen vs. 76 Analyseeinheiten):**  
   *Problem:* Die Zahl „77 Provinzen“ steht im Abstract (S. 1) und in Abb. 5 (S. 12). Im Methodenteil (S. 5) wird jedoch explizit erklärt, dass Bueng Kan und Nong Khai zusammengefasst wurden, wodurch effektiv 76 Raumeinheiten analysiert wurden (18.240 Monate / 240 Monate = 76).  
   *Empfehlung:* Da der Entwurf selbst in Tabelle 1 (Zeile 194) und Abschnitt 2.5 (Zeile 285) auf diese Zusammenführung eingeht, ist der Sachverhalt in der Arbeit bereits stimmig verankert; eine kurze Präzisierung in Zeile 58 („77 Provinzen Thailands [harmonisiert zu 76 Einheiten]“) wäre denkbar, aber nicht zwingend.

4. **Citation #6 (Zeile 91 – Lowe et al. ausschließlich offene Daten):**  
   *Problem:* Die Formulierung „nutzen ausschließlich offene Daten (S.~e218)“ stützt sich auf die Formulierung „All data used in this study is open access and freely available on the web or from the authors upon request (appendix 2 p 1)“. Die Einschränkung „or from the authors upon request“ schwächt den Begriff „ausschließlich offene Daten“ im engeren Open-Data-Sinn minimal ab, ist aber im wissenschaftlichen Kontext als Beleg ausreichend.
