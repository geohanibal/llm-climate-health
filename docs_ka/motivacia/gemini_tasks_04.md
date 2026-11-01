# Gemini დავალება — რაუნდი 4 (წყაროების გვერდების გადამოწმება)

როგორ გამოიყენო:
- Gemini CLI გახსენი პროექტის საქაღალდეში და ქვემოთ მოცემული ტექსტი ჩასვი.
- ეს დავალება **მხოლოდ კითხულობს**: Gemini არცერთ `.tex` ფაილს არ ცვლის.
  შედეგი იქნება ერთი ანგარიში: `docs_ka/motivacia/V_report.md`.
- დასრულების შემდეგ Claude-ს უთხარი „შეამოწმე დავალება V“. Gemini-მაც შეიძლება
  შეცდომა დაუშვას, ამიტომ მის ვერდიქტებს ციტატებით გადავამოწმებთ.

---

## დავალება V — ციტატებისა და გვერდის ნომრების გადამოწმება

```
You are helping with a bachelor thesis. Your task is to VERIFY citations in
a German thesis draft against the original article PDFs. This is a
READ-ONLY task.

FILES
- Draft (German, the authoritative version):
    docs/thesis/entwurf/entwurf_motivation_anforderungen.tex
- Original articles (English, version of record):
    docs_ka/motivacia/papers/lowe_2021_lancetph.pdf      (Lowe et al. 2021)
    docs_ka/motivacia/papers/suttirat_2026_plosntd.pdf   (Suttirat et al. 2026)
    docs_ka/motivacia/papers/clarke_2024_opendengue.pdf  (Clarke et al. 2024)
- Do NOT use the *_targmani.* files (Georgian translations) as evidence.

STRICT RULES
1. Do NOT modify any file except the report you create:
       docs_ka/motivacia/V_report.md
   Do NOT edit .tex files, do NOT edit docs/thesis/THESIS_KNOWLEDGE_BASE.md,
   do NOT commit, do NOT push.
2. Never invent or "reconstruct" source text. Every verdict must be backed
   by a VERBATIM quote copied from the extracted PDF text. If you cannot
   find the passage, say so (verdict NOT_FOUND) - do not guess.
3. Extract text with a tool, e.g.
       pdftotext -layout <file.pdf> -      (one page: -f N -l N)
   or Python pypdf. Note: PDFs have two columns, hyphenated line breaks
   ("mea- sure") and special characters (0·5°, en dash). Search for short
   rare word stems, not long phrases.

PAGE NUMBERING (important)
- The draft cites JOURNAL page numbers, written as "S.~X" (Seite).
- Lowe (Lancet Planetary Health): journal pages e209-e219 are printed in
  the page footer. PDF page = e-number - 208 (e211 -> PDF page 3).
  Verify this mapping from the footers before relying on it.
- Suttirat (PLOS NTD): the footer shows "N / 24"; journal page = PDF page.
- Clarke (Scientific Data): check the footer; if the journal uses an
  article number instead of page numbers, report how pages are labelled.
- References to "appendix" pages are a SEPARATE supplementary file that
  is not available here: mark those as CANNOT_CHECK.

WHAT TO CHECK
A) Every citation with a page number in the draft, i.e. every "(S.~...)",
   "S.~...", "S.~X--Y", also inside tables (longtable) and footnotes.
   For each one, determine which article it refers to from the context
   (author named in the sentence, the table column, or the item).
B) Every direct quotation (\enquote{...}) that comes from an article:
   compare it WORD BY WORD with the PDF, including punctuation.
C) The reference list at the end of the draft: authors (order and
   spelling of the first authors), year, title, journal, volume(issue),
   page range or article number, DOI - compare with the first page of
   each PDF.

For each citation in A and B, answer three questions:
  1. Is the passage on the cited page? (if it is on another page, which)
  2. Does the passage say the SAME thing as the draft?
  3. Does the draft claim MORE than the source says (overclaiming), or
     present something the authors cite from another work (look for a
     superscript reference number at the end of the sentence) as the
     authors' own finding?

VERDICTS (use exactly these)
  OK            - right page, same meaning
  WRONG_PAGE    - passage exists but on another page (give correct page)
  OVERCLAIM     - right page, but the draft says more than the source
  MISMATCH      - the source says something different
  QUOTE_DIFFERS - direct quotation not verbatim (show both versions)
  NOT_FOUND     - passage could not be found in the PDF
  CANNOT_CHECK  - refers to material not available (e.g. appendix)

REPORT FORMAT (docs_ka/motivacia/V_report.md)
1. Summary table, one row per citation:
   | # | .tex line | article | cited page | verdict | found on page |
2. Then one section per citation:
   - .tex line number and the draft sentence (German, copied exactly)
   - the verbatim English passage from the PDF, with its page
   - verdict and a one- or two-sentence justification
   - for anything other than OK: a SUGGESTED correction (text only - do
     not apply it)
3. Reference list check (C): one row per entry, OK or what differs.
4. At the end: a list of citations you were unsure about and why.

Work through the WHOLE draft; do not stop after the first few citations.
When finished, print the summary table and the counts per verdict.
```
