# გადაცემა Gemini-ს (2026-11-19): როგორ გააგრძელო Claude-ის გარეშე

## შენთვის, სერგი: როგორ იმუშაო
1. ჯერ **დაასრულე დავალება J** (`gemini_tasks_07.md`), თუ ჯერ მიმდინარეობს.
2. Gemini-ს ახალ ჩატში ჩასვი ქვემოთ მოცემული **ბრძანება**.
3. ყოველი დავალების შემდეგ **შენ** ამოწმებ: `git diff`, ტესტები (`backend/.venv/Scripts/python.exe -m pytest -q`)
   და ანგარიში (`docs_ka/motivacia/<X>_report.md`). მხოლოდ ამის შემდეგ **შენ** აკეთებ commit-ს.
4. **push** მხოლოდ Docker-ის ლოკალური ტესტის შემდეგ (`git archive HEAD | docker build -t llmch:test -`).
5. Claude-ის ლიმიტის განახლებისას უთხარი: „წაიკითხე GEMINI_HANDOFF.md და შეამოწმე, რა გააკეთა Gemini-მ“.

## სად რა არის
| რა | სად |
|---|---|
| ყველაფრის „მეხსიერება“ (წაიკითხე პირველი!) | `docs/thesis/THESIS_KNOWLEDGE_BASE.md` (Current status, §9, §10) |
| შეხვედრა Thomas-თან (დღეს) | `docs/thesis/supervisor_meetings/2026-11-19_shexvedra_thomas.md`, `…_presentation.pptx`, `…_presentation_script.md` |
| რეგიონული მონაცემების გეგმა | `docs/thesis/supervisor_meetings/2026-11-19_regionuli_monacemebi_gegma.md` |
| რეგისტრაცია და ფორმატი | `docs/thesis/registracia_da_formati.md`, ფორმები `docs/thesis/formulare/` |
| მონახაზი (მთავარი = გერმანული) | `docs/thesis/entwurf/entwurf_motivation_anforderungen.tex` |
| Gemini-ის ძველი დავალებები / ანგარიშები | `docs_ka/motivacia/gemini_tasks_0*.md`, `*_report.md` |

## შემდეგი დავალებები (თანმიმდევრობით)
1. **J** (მიმდინარე): lag-იანი შემთხვევები, მოძრავი საშუალო, ეროვნული ფაილის აღდგენა.
2. **K, Thomas-ის პასუხის შემდეგ: რეგიონული კლიმატი, ვარიანტი C** (თითო პროვინციაზე 1 წერტილი, Open-Meteo, ქეშით).
   წერტილი: პროვინციის პოლიგონის შიგნით მდებარე წერტილი (`representative_point`, HDX GeoJSON). **არა** ვარიანტი A
   (ტესტი: 10 წერტილი × 20 წელი = 1 044 API call, `X-RateLimit-Cost`; იხ. რეგიონული გეგმა §3b).
3. **L: რეგიონული მოსახლეობა** (WorldPop, CC BY 4.0, 2015-დან; zonal sum HDX პოლიგონებით) + ინციდენტობა.
4. **M: API და ფორმა:** `/api/integrate` პროვინციებით; ფორმაში „ყველა პროვინცია / ერთი პროვინცია“ (ka/en/de).
5. **შენი სავარჯიშო, A3:** ნაბიჯების ხანგრძლივობა `etl.py`-ში (CS1-ისთვის).

---

## ბრძანება Gemini-სთვის (დააკოპირე მთლიანად)

```
You are continuing work on a bachelor thesis repository (LLM-driven ETL platform
that joins disease case data, climate data and population data; Python FastAPI
backend in backend/, Flutter web frontend in frontend/). Until now Claude
reviewed your work; for the next days Sergi (the student) reviews it himself,
so your work must be easy to check.

READ FIRST, in this order:
1. docs/thesis/THESIS_KNOWLEDGE_BASE.md  (section "Current status", §0 rules,
   §9 open TODO, §10 decision log - the newest entries are 2026-11-19)
2. docs_ka/motivacia/GEMINI_HANDOFF.md  (task order K, L, M)
3. docs/thesis/supervisor_meetings/2026-11-19_regionuli_monacemebi_gegma.md
4. docs/thesis/CHANGE_DOCUMENTATION_GUIDE.md  (you MUST follow it)
5. docs_ka/motivacia/H_report.md, I_report.md, J_report.md (if present) and the
   code they describe (backend/scripts/build_dengue_admin1.py,
   backend/app/services/case_data.py, config.py)

HARD RULES (these were enforced in every review so far):
- Never invent data, names, codes, page numbers, licences or historical facts.
  Every fact needs a source you actually read (URL + date) or the data itself.
  If you are unsure, write "not verified" instead of guessing.
- Do NOT commit, do NOT push. Sergi commits after checking.
- Do NOT edit docs/thesis/THESIS_KNOWLEDGE_BASE.md directly. Put a proposed
  KB entry at the end of your report; Sergi copies it.
- Gaps are never filled silently (rule A20). Ambiguous source records are
  excluded and documented, never matched by name alone (see the Vientiane case
  in I_report.md).
- Existing behaviour must not change unless the task says so; all tests must
  pass: backend/.venv/Scripts/python.exe -m pytest -q  (report the numbers).
  If pytest hangs, stop and tell Sergi.
- The thesis language is GERMAN. Sergi wants explanations in Georgian and wants
  to understand every change: in each report explain in simple Georgian WHAT
  you changed, WHY, and HOW Sergi can check it himself (exact commands).
- Before you start a task, tell Sergi in 3-5 lines what you will do and wait
  for "start".

WORKFLOW PER TASK:
1. Short plan (Georgian) -> wait for "start".
2. Implement + tests + documentation (CHANGE_DOCUMENTATION_GUIDE.md).
3. Report docs_ka/motivacia/<LETTER>_report.md: files changed, what/why,
   verification steps for Sergi (commands + expected output), test numbers,
   open questions, proposed KB entry.
4. Stop and wait.

NEXT TASK: ask Sergi whether task J is finished and reviewed. Then propose the
plan for task K (regional climate, option C) as described in GEMINI_HANDOFF.md,
but only after Sergi confirms Thomas agreed to option C (otherwise ask what
Thomas decided).
```
