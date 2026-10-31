# Gemini-ის ბრძანებები — მოტივაცია, მოთხოვნები, Case Studies

ეს ბრძანებები ინგლისურადაა, რადგან Gemini ასე უფრო ზუსტად პოულობს აკადემიურ
ლიტერატურას. თითო ბრძანება ცალ-ცალკე ჩააკოპირე, თანმიმდევრობით (1 → 6).
ყოველი შედეგი შეამოწმე Google Scholar-ში: **Gemini-ს შეუძლია არარსებული
სტატიის მოგონება.** DOI ყოველთვის გახსენი და ნახე, რომ სტატია ნამდვილად არსებობს.

---

## ბრძანება 1 — ნიმუშის პუბლიკაციების მოძიება

```
I am writing a bachelor thesis in computer science. I built a software system
that, given a natural-language description (disease, region, time span, climate
variables), automatically finds suitable data sources (disease case counts,
ERA5 / NASA POWER climate reanalysis, population data), cleans them, aggregates
them temporally (daily/weekly/monthly) and joins them into one analysis-ready
table, with provenance documentation. It is NOT a prediction model; it prepares
input data for data-based epidemiological models.

Find 8-10 real, peer-reviewed publications (2015-2025) in which researchers
built a data-based model linking climate variables to a health outcome
(preferably dengue, malaria, cholera, or temperature-related mortality), and in
which a large part of the work was collecting and integrating climate data with
health surveillance data.

For each paper give:
1. Full citation + DOI (only papers you are certain exist; say "uncertain" otherwise)
2. Disease, region, time span, temporal resolution (daily/weekly/monthly)
3. Exact health data source (e.g. national surveillance, OpenDengue, WHO)
4. Exact climate data source and variables (e.g. ERA5 temperature, CHIRPS rainfall)
5. Other covariates (population, urbanisation, ENSO index ...)
6. Preprocessing steps described in the methods (spatial aggregation, temporal
   aggregation, lags, missing-value handling, unit conversion)
7. Model type (e.g. DLNM, GAM, Bayesian hierarchical, machine learning)
8. Any sentence where the authors mention difficulties with data availability,
   harmonisation, or data preparation effort (quote it with page/section)
Output as a Markdown table plus a short note per paper.
```

## ბრძანება 2 — მსგავსი სისტემები (Related Work)

```
List existing software systems, platforms or data services that help
researchers obtain and integrate climate data with health data for modeling.
Examples to check (verify they exist and describe them accurately): Copernicus
Climate Data Store, Google Earth Engine, IRI ENACTS, DHIS2 Climate & Health /
CHAP modeling platform, Malaria Atlas Project, OpenDengue, WHO GHO, ClimaHealth.
Add others you are sure exist.

For each: purpose, target users, what data it covers, whether it joins climate
and health data automatically, whether it needs programming skills, whether it
supports natural-language requests, and its main limitation.
Finish with a comparison table with the columns:
System | Finds sources automatically | Climate+health join | No coding needed |
Natural-language input | Provenance/documentation | Limitation.
```

## ბრძანება 3 — მეცნიერის საჭიროებების გამოყვანა (Anforderungen)

ჩასვი ბრძანება 1-ის შედეგი ტექსტის ბოლოს.

```
Below are summaries of data-based climate-health modeling papers. Act as a
requirements engineer. From the data work described in these papers, derive the
needs of a researcher who wants to build such a model. Then derive concrete
software requirements for a data-integration system.

Format:
- Need N1..Nn: "The researcher needs ..." — with the papers it comes from
- Requirement FR1..FRn / NFR1..NFRn: "The system shall ..." — traced to needs
- Traceability matrix: rows = requirements, columns = papers, X where justified

Only derive requirements that are actually supported by the papers.

[PASTE RESULT OF PROMPT 1 HERE]
```

## ბრძანება 4 — ჩემი არსებული მოთხოვნების შედარება

ჩასვი შენი `anforderungskatalog.tex`-დან FR/NFR სია და ბრძანება 3-ის შედეგი.

```
Here are (A) the requirements I originally wrote for my system and (B)
requirements derived from the literature. Compare them:
1. Which of my requirements (A) are justified by the literature (B)? Cite which.
2. Which of mine are NOT justified by any paper (candidates to drop or to
   justify differently, e.g. usability for non-programmers)?
3. Which literature requirements (B) are missing in my list (gaps)?
Output a table: Requirement | In A | In B | Source paper(s) | Recommendation.

(A) [PASTE MY FR/NFR LIST]
(B) [PASTE RESULT OF PROMPT 3]
```

## ბრძანება 5 — Case Study-ის დაგეგმვა

```
I want to show that my system helps researchers by reproducing the data
preparation of a published study. Plan a case study for this paper:
[CITATION]

The procedure is: Paper -> which data did the authors use -> I describe this
data need to my system in natural language -> the system produces an
integrated dataset -> I compare it with the paper's dataset -> (optionally) I
rerun a simple version of their analysis (e.g. lagged correlation between
rainfall/temperature and cases) and check whether the main finding
qualitatively matches.

Give me:
1. The natural-language request I should type into my system
2. A checklist of the paper's data properties to compare (sources, variables,
   region, period, resolution, lags, aggregation)
3. Measurable evaluation criteria (e.g. coverage of required variables, number
   of manual steps in the paper vs. in my system, time needed, correlation of
   my climate series with the paper's reported values)
4. Possible differences/limitations I should honestly report
```

## ბრძანება 6 — Einleitung / Motivation გერმანულად

```
Write a draft (about 1.5 pages, academic German, Bachelorarbeit Informatik) of
the motivation section of the introduction. Structure:
1. Climate-sensitive diseases (dengue etc.) and why data-based models are used
2. Problem: researchers spend much effort finding, cleaning and joining climate
   and health data — support this ONLY with the papers below, cite them
3. Existing tools do not close this gap (from related work below)
4. Goal of this thesis: a system that ... (my system description)
5. How the thesis shows that it helps: requirements derived from publications,
   case studies reproducing the data preparation of 2-3 studies
Mark every claim that needs a citation with [CITE: ...]. Do not invent sources.

Papers: [PASTE]
Related work: [PASTE]
System: [PASTE README SUMMARY]
```
