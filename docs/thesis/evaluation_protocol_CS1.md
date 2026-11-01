# Evaluation Protocol — Case Study 1 (Manual vs. System)

> **ქართულად:** ეს ფაილი ტესტის ოქმია. ჯერ ხელით გააკეთე (ნაწილი A), მერე
> სისტემით (ნაწილი B). ყოველი ნაბიჯის დაწყება და დასრულება ჩაწერე (საათი:წუთი).
> შეცდომები და პრობლემებიც ჩაწერე, ისინიც შედეგია.

Reference study: Suttirat et al. 2026 (P1 in `THESIS_KNOWLEDGE_BASE.md`).

## 0. Scope (same task for both runs)

Fair comparison = **identical target dataset** in both runs. Because the system
works at country level with ERA5, the target is a *simplified* version of P1:

| Property | Target |
|---|---|
| Disease / outcome | Dengue cases, Thailand (OpenDengue `dengue_total` = all cases; P1 used DHF only, so absolute numbers differ) |
| Spatial unit | Country (national) |
| Period | **2009-01 … 2022-12** (bundled OpenDengue Thailand data starts 2009-01; P1 used 2003–2022) |
| Resolution | Monthly |
| Climate | Mean temperature, minimum temperature, maximum temperature, precipitation (ERA5 via Open-Meteo) |
| Derived | Incidence per 100,000; climate lags 1, 2, 3 months |
| Output | One CSV table + short description of every processing step |

Out of scope (documented as limitation): provinces, TerraClimate, bioclim,
MODIS, socioeconomic variables.

## 1. Setup (fill in once)

- Date: ……
- Machine / internet: ……
- Tools for manual run: Python …, pandas …, editor ……
- System version (git commit): ……
- Order of runs: manual first / system first (and why): ……
- Prior knowledge: Sergi knows the data sources already (developer of the system)
  → **learning-effect bias**, mention in thesis.

## 2. Part A — Manual run

| # | Step | Start | End | Minutes | Websites / tools used | Lines of code | Problems / errors |
|---|---|---|---|---|---|---|---|
| A1 | Find dengue case data source | | | | | | |
| A2 | Download + load dengue data | | | | | | |
| A3 | Find + download climate data (ERA5) | | | | | | |
| A4 | Aggregate daily climate → monthly | | | | | | |
| A5 | Find + download population data | | | | | | |
| A6 | Annual population → monthly | | | | | | |
| A7 | Clean (missing values, units, column names) | | | | | | |
| A8 | Join into one table | | | | | | |
| A9 | Compute incidence per 100,000 | | | | | | |
| A10 | Compute lag columns 1–3 | | | | | | |
| A11 | Document what was done | | | | | | |
| | **Total** | | | | | | |

## 3. Part B — System run

Natural-language request used (copy exactly):

```
……
```

| # | Step | Start | End | Minutes | User interactions (clicks / edits) | Problems / errors |
|---|---|---|---|---|---|---|
| B1 | Enter request | | | | | |
| B2 | Review / correct form prefill | | | | | |
| B3 | Run integration | | | | | |
| B4 | Check sources / alternatives | | | | | |
| B5 | Download table + PDF report | | | | | |
| | **Total** | | | | | |

## 4. Correctness check (as important as time)

Compare the two output tables month by month:

| Check | Result |
|---|---|
| Same number of rows / months? | |
| Cases identical? (max abs. difference) | |
| Temperature: correlation r, mean abs. difference | |
| Precipitation: correlation r, mean abs. difference | |
| Incidence identical? | |
| Lags correctly shifted? | |
| Differences explained? | |

Optional: aggregate P1's Zenodo data (province → national) and compare cases
and temperature with the system output (TerraClimate vs. ERA5 → expect high
but not perfect correlation).

## 5. Summary metrics

| Metric | Manual | System |
|---|---|---|
| Total time (min) | | |
| Number of manual steps | | |
| Number of websites / tools | | |
| Lines of code written | | |
| Programming required? | | |
| Errors encountered | | |
| Steps documented automatically? | | |

## 6. Threats to validity (for the thesis)

- Single tester who is also the developer (expert + learning effect).
- Simplified scope vs. P1 (country level, ERA5 instead of TerraClimate).
- Network / API speed influences time.
- Mitigation ideas: second tester (fellow student, ideally non-programmer),
  repeat system run 3× and report median, record screen.
