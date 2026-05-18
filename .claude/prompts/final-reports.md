# Final Reports — Claude Code Generation Prompt

Paste this into Claude Code at the start of the report-writing phase (after May 19, once `v1.5` is tagged). Claude Code will generate every final report in both Markdown and Overleaf LaTeX format.

Save this file to `.claude/prompts/final-reports.md` for reuse.

---

## What you'll produce

11 files total in `/reports/`:

| # | Document | Length | Audience |
|---|---|---|---|
| 1 | Sprint 4 Demo & Retrospective | ~3 pages | Internal record |
| 2 | Sprint 5 Demo & Retrospective | ~3 pages | Internal record |
| 3 | **CSC231 Final Project Report** | 10–15 pages | Agile SE course (due **May 26**) |
| 4 | **CSC234 Final UI/UX Report** | 10–15 pages | User-Centric course (due **May 28**) |
| 5 | **Enterprise Audit & Orchestration Report** | 5–8 pages | Final submission (due **May 30**) |
| – | `references.bib` (shared) | – | BibTeX for all .tex files |

Each report 1–5 generates as both `.md` and `.tex`, so:

```
/reports/
├── sprint-4-demo.md       +  sprint-4-demo.tex
├── sprint-5-demo.md       +  sprint-5-demo.tex
├── csc231-final.md        +  csc231-final.tex
├── csc234-final.md        +  csc234-final.tex
├── audit-orchestration.md +  audit-orchestration.tex
└── references.bib         (shared by all .tex files)
```

---

## Project context (so this prompt works even with thin repo context)

- **Team:** Group 2, KMUTT, Sem 2/2568 — Kraiwich Jaiton, Teerin Kittichaicharoen, Theerawat Patthawee (Lead), Jedsarit Fanpimiy, Napat Chang-ekwong
- **Courses:** CSC231 Agile Software Engineering · CSC234 User-Centric Mobile App Development
- **Product:** MoodBloom — cross-platform Flutter mood-tracker for Android + Web
- **Stack:** Flutter / Dart / Riverpod / GoRouter / Freezed / Drift / Firebase (Auth, Firestore, Storage, Functions, FCM, Remote Config, Crashlytics) / Gemini gemini-2.5-flash / fl_chart / GitHub Actions
- **Sprints:** S1 (agile plan, Apr 21) → S2 walking skeleton (Apr 28) → S3 v0.3-beta (May 5) → S4 v1.0 (May 12) → S5 v1.5 (May 19)
- **Pivot story:** After Sprint 3, professor feedback drove the Sprint 4–5 ecosystem redesign: plants NEVER die, formal Mood Score formula, EWMA garden health, 5 pattern-detection algorithms, three-tier intervention, token economy, weekly harvest, bipolar disclaimer, personalized quote library (Tier 3 = curated only)
- **Multi-agent workflow:** Claude Code with 4 subagents (architect, flutter-engineer, qa-engineer, security-reviewer) and Plan Mode discipline at every sprint kickoff
- **Test surface:** 41 acceptance test cases (spec section 7), 9 marked MUST (TC-15, 18, 24, 33, 35, 36, 38, 40, 41)

---

## Input sources to read first (in this order)

Before writing anything, use the `Read` tool on each of these. Take notes; the reports synthesize from them.

1. `CLAUDE.md` — conventions, 12 features, copy rules, data model
2. `.claude/specs/sprint-4-5-spec.md` — formulas, all 41 test cases, 37 citations (section 8 — use these as the bibliography)
3. `.claude/prompts/sprint-{2,3,4,5}-kickoff.md` — sprint plans, what was delivered, retrospectives
4. `docs/architecture/conceptual.png`, `implementation.png`, `*.md` — Mermaid sources + diagrams
5. `docs/adr/*.md` — ADRs (architecture decisions): ADR-0001 (Clean Architecture), ADR-0003 (Gemini contract), ADR-0004 (Drift schema), ADR-0005 (sync conflict resolution), ADR-0006 (ecosystem model), ADR-0007 (Tier 3 determinism)
6. `docs/pm/` — WBS (37 leaves), Backlog (37 items, 75.5 PD), PDM (30 activities, ends day 20), GANTT
7. `docs/ux/` — Personas (Lin + Som), Journey Maps (Lin's harvest, Som's Tier 1→2→3 escalation)
8. `docs/qa/` — S5 outputs: android-matrix, web-matrix, a11y-sweep, perf-profile
9. `docs/retros/` — sprint retrospectives if they exist
10. `docs/security/` — Security Posture Reports
11. Git history: `git log --oneline --all --graph` for chronology and `git tag -n` for release notes
12. Test files in `apps/mobile/test/` and `integration_test/` — for evidence and pass/fail counts

If any path is missing, note it in your plan but proceed with what's available — don't block on missing artifacts.

---

## Report-by-report structure

### Report 1 — Sprint 4 Demo & Retrospective

Audience: internal team record (also referenced by CSC231 chapter 8).

Sections:
1. **What we shipped (v1.0).** Bullet list mapping to backlog IDs: Mood Score (3.6), Garden Health EWMA (4.2), Daily Atmosphere (4.3), Day/Night theme (4.4), Pattern Engine (5.3), Weekly Harvest (6.1), Token system (6.2), Dark mode (7.2), widget+golden tests (8.2). Note: Pattern Engine fires triggers internally; no notifications surface yet — that's S5.
2. **Demo flow on May 12.** The scenario as walked through on stage.
3. **Test results.** TC-1 to TC-5 (Tokens), TC-11 to TC-30 (Harvest, Atmosphere, EWMA, Pattern). Pass/fail counts. Any deferred test cases.
4. **What went well.** 3 bullets. Concrete.
5. **What was hard.** 3 bullets. Concrete with what you'd do differently.
6. **What the human team caught that the agents missed.** Specific examples. This is the most-valuable section for the audit report.
7. **Going into Sprint 5.** 2–3 lines.

### Report 2 — Sprint 5 Demo & Retrospective

Same structure as Sprint 4 but for v1.5. Special focus:
- **TC-40 result** (Tier 3 determinism — Gemini-mock asserted never called)
- **TC-41 result** (Quote Safety Filter rejection rate on 50+ adversarial inputs)
- **Bipolar disclaimer compliance** (TC-36–39)
- **Cross-platform parity** (Android vs Chrome)
- **A11y sweep findings** (WCAG 2.2 AA pass/fail)
- **Performance profile** (cold start, frame rate, memory)

### Report 3 — CSC231 Final Project Report (Agile SE focus)

Required sections (course-aligned):

- **Cover page.** Project title, members + IDs, course code, semester, advisor.
- **Executive Summary** (1 page). One-sentence problem, one-paragraph solution, one-paragraph what was delivered, one-paragraph methodology, one-paragraph outcome.
- **Chapter 1: Introduction.** Background, problem statement (Thailand mental health context), scope, objectives, deliverables.
- **Chapter 2: Software Engineering Approach.** Agile/Scrum with 5 sprints (S1–S5); multi-agent orchestration via Claude Code; Plan Mode discipline; sprint cadence; 4-agent team charter (architect, flutter-engineer, qa-engineer, security-reviewer).
- **Chapter 3: Requirements Engineering.** Functional requirements (the 12 pivot features); non-functional requirements mapped to ISO/IEC 25010 (functional suitability, performance efficiency, compatibility, usability, reliability, security, maintainability, portability). Show traceability matrix: feature → requirement → test case.
- **Chapter 4: Project Planning.** Embed/reference WBS (37 leaves, 8 buckets), Backlog (37 items with PERT estimates, Wideband Delphi method, 75.5 PD vs 80 PD capacity = 94% utilization), PDM (30 activities, critical path A→B→C→G→I→L→R→W→X→Y→AC→AD→AE, ends day 20 of 20), GANTT.
- **Chapter 5: Software Architecture.** Clean Architecture three-layer rule (presentation/domain/data); domain-layer-zero-imports enforced via Claude Code hook; tech stack rationale; **new Sprint 4–5 Domain Engines** (MoodScore, EWMA, Atmosphere, Pattern Engine, Tiered Dispatcher, Quote Library + Safety Filter, Disclaimer Service, Token Service, Harvest Scheduler) — include both architecture diagrams. Explain why Tier 3 has direct path to QuoteLibrary, never through Gemini.
- **Chapter 6: Quality Assurance.** Test strategy (unit / widget / golden / integration / a11y / perf / security); 41 test cases summarized; pass rates from S4 + S5; coverage numbers (target ≥80% domain layer); cross-platform results (Android + Chrome).
- **Chapter 7: Risk Management.** Risk register from `docs/security/` and the PDM risk section. For each risk: probability, impact, mitigation, was-mitigation-needed?
- **Chapter 8: Sprint Retrospectives.** Brief recap of each sprint (S2, S3, S4, S5) — what was delivered, what slipped, what the team learned. Pull from `docs/retros/` and the demo retrospectives (Reports 1 + 2).
- **Chapter 9: Conclusion & Lessons Learned.** What worked about multi-agent dev; what didn't; lessons for future student teams using AI-assisted enterprise workflows.
- **References.** All 37 entries from spec section 8, APA-formatted in markdown, BibTeX in LaTeX.
- **Appendix A: ADRs.** List of all architecture decision records with one-sentence summaries.
- **Appendix B: Plan Mode transcripts.** 1–2 illustrative excerpts (anonymize / abbreviate if long).
- **Appendix C: Test case manifest.** Full list of 41 TCs with pass/fail.

### Report 4 — CSC234 Final UI/UX Report (User-Centric focus)

Required sections:

- **Cover page.** Same metadata as CSC231 but course = CSC234.
- **Executive Summary** (1 page). UI/UX problem framing, design philosophy in one paragraph, what was delivered, evaluation outcome.
- **Chapter 1: User Research.** Lin + Som personas in full (bio, goals, pain points, quotes). Methodology: how we built them, what real-world inputs grounded them.
- **Chapter 2: User Journey Mapping.** Lin's "Evening Logging + Weekly Harvest" journey (5 phases). Som's "Tiered Intervention Escalation Tier 1→2→3" journey (5 phases). Each with emotion arc, pain points, ISO 25010 quality risk, fix.
- **Chapter 3: Design Philosophy — The Ecosystem Model.** Critical chapter. The pivot from "wilting plants" (Sprint 1–3) to "plants never die" (Sprint 4–5). Ground in the four therapeutic frameworks with full citations:
  - Self-compassion (Neff 2003, 2023)
  - DBT validation (Linehan 1993)
  - ACT "emotions as weather" (Hayes 1999; Harris 2008)
  - Narrative externalization (White & Epston 1990)
  Include the Mood Score, EWMA, and Atmosphere formulas with worked examples (from spec sections 2.1–2.3).
- **Chapter 4: Design System.** Tokens (color palette, typography, spacing), shadcn-equivalent components catalog, Material 3 deltas.
- **Chapter 5: Information Architecture & Navigation.** GoRouter route tree, bottom-nav structure, modal hierarchy, deep-link strategy.
- **Chapter 6: Key Screens.** Onboarding (with bipolar disclaimer slide), Log Mood (intensity slider + AI suggestion pill), Garden (5 plant tiers + 4 atmospheres — show screenshots of EVERY tier and atmosphere), Insights (with mandatory ack dialog), Settings, History (with archived weeks). One screenshot per screen.
- **Chapter 7: Gamification Ethics — Token Economy & Skins.** Cite Cheng et al. (2019) on contingent rewards risks; SDT (Deci & Ryan 2000, Ryan & Deci 2017); explain anti-pattern guardrails: mood-agnostic earning, no loss aversion, no FOMO, no leaderboards, cosmetic-only, optional visibility.
- **Chapter 8: Therapeutic Safety.** Tier 3 determinism (no Gemini, curated phrases only); Quote Safety Filter (fail-closed for Tier 1/2); bipolar disclaimer placement (onboarding + Insights ack + every notification footer + Settings); the curated phrase pool (sample entries); cooldown logic; opt-out mechanics.
- **Chapter 9: Accessibility.** WCAG 2.2 AA contrast results across light + dark themes; Semantics labels coverage; dynamic type at 200%; TalkBack walkthrough notes from S5 sweep.
- **Chapter 10: Cross-Platform Considerations.** Android-specific (FCM, biometric, keystore); Web-specific (PWA, browser notifications, responsive breakpoints); shared codebase strategy.
- **Chapter 11: Usability Evaluation.** Heuristic evaluation (Nielsen) results; informal testing notes if any; reflections on persona acceptance criteria coverage.
- **References.** Same 37 citations.

### Report 5 — Enterprise Audit & Orchestration Report (final submission)

This is the **overall project report** mandated by the Enterprise Term Assignment. Required sections (5–8 pages):

- **Executive Summary** (½ page).
- **Section 1: Project Overview.** Product, team, courses, timeline.
- **Section 2: Multi-Agent Team Charter.** Why 4 agents; role separation; "the implementer cannot approve their own work" rule; how Plan Mode enforces it.
- **Section 3: Workflow Description.** Plan Mode → handoff brief (architect) → implementation (flutter-engineer) → review (qa-engineer) → security audit if sensitive (security-reviewer) → merge. Mention the hooks (format, analyze, secret-scan, layer-purity).
- **Section 4: Sprint Execution Audit (S2–S5).** Per sprint: PR count, test files added, domain coverage at sprint end, agent invocation count by type, human-team interventions, blockers and how resolved.
- **Section 5: Risk Register + Security Posture.** Risks tracked, mitigations executed; final Security Posture Report summary (Cloud Functions hardened, Firestore rules verified, no HIGH/CRITICAL deps, no secrets in source, no PII in logs).
- **Section 6: Evidence Package Index.** Links to: repo URL, every ADR, sprint demo transcripts, test result files, Crashlytics screenshots, golden test files, a11y sweep doc, performance profile doc.
- **Section 7: Compliance Matrix (Enterprise R1–R5).**
  - **R1 Authentication & Security:** email/Google OAuth + biometric + keystore + Firestore rules + Cloud Function PII filter + secret scan
  - **R2 Clean Architecture:** three-layer with domain-zero-imports + Freezed entities + Riverpod + repository abstractions
  - **R3 Multi-Agent Workflow:** architect/flutter-engineer/qa-engineer/security-reviewer + Plan Mode + handoff briefs + ADRs
  - **R4 Observability:** Crashlytics + structured logger + Remote Config flags + sprint metrics dashboard
  - **R5 Quality Gates:** correctness ≥80% domain coverage + security clean + a11y WCAG 2.2 AA + performance cold start <2s
- **Section 8: Lessons Learned for AI-Assisted Enterprise Development.** What worked, what didn't, recommendations for future student teams.

---

## LaTeX setup (Overleaf-compatible)

Each `.tex` file must be self-contained — pasteable into a fresh Overleaf project as a single document, with the shared `references.bib` uploaded alongside.

Use this preamble for every `.tex`:

```latex
\documentclass[11pt,a4paper]{article}
\usepackage[utf8]{inputenc}
\usepackage[T1]{fontenc}
\usepackage{lmodern}
\usepackage[margin=1in]{geometry}
\usepackage{graphicx}
\usepackage{hyperref}
\usepackage{booktabs}
\usepackage{longtable}
\usepackage{xcolor}
\usepackage{listings}
\usepackage{amsmath}
\usepackage{amssymb}
\usepackage{enumitem}
\usepackage{titling}
\usepackage{fancyhdr}
\usepackage{caption}
\usepackage{subcaption}
\usepackage[backend=biber,style=apa]{biblatex}

\addbibresource{references.bib}

\definecolor{moodgreen}{HTML}{2E7D5B}
\definecolor{moodorange}{HTML}{E65100}
\hypersetup{colorlinks=true, linkcolor=moodgreen, urlcolor=moodgreen, citecolor=moodgreen}

\lstset{
  basicstyle=\ttfamily\footnotesize,
  breaklines=true,
  frame=single,
  backgroundcolor=\color{gray!10},
  language=Dart
}

\pagestyle{fancy}
\fancyhf{}
\rhead{MoodBloom — Group 2}
\lhead{\leftmark}
\rfoot{\thepage}

\title{<REPORT TITLE>}
\author{
  Kraiwich Jaiton \and
  Teerin Kittichaicharoen \and
  Theerawat Patthawee \and
  Jedsarit Fanpimiy \and
  Napat Chang-ekwong \\[1ex]
  \small Group 2 \\
  \small CSC231 Agile SE / CSC234 User-Centric Mobile App Development \\
  \small KMUTT, Semester 2/2568
}
\date{<DATE>}

\begin{document}
\maketitle
\thispagestyle{empty}
\newpage
\tableofcontents
\newpage

% Content here

\printbibliography

\end{document}
```

### LaTeX conventions

- Tables: `tabular` for short, `longtable` for multi-page (WBS, Backlog, PDM, test case manifest)
- Lists: `itemize` for bullets, `enumerate` for numbered, `description` for term-definition
- Code: `lstlisting` environment with `language=Dart` (or `language={}` for pseudo-code)
- Math: inline `$S_t = v \cdot i / 5$`, display `\[ H_t = 0.15 S_t + 0.85 H_{t-1} \]`
- Figures: `\includegraphics[width=0.9\textwidth]{docs/architecture/conceptual.png}` — Claude Code, copy referenced images into `/reports/images/` and reference them as `images/conceptual.png`
- Citations: `\cite{russell1980circumplex}` inline; use `\textcite{neff2003}` for "Neff (2003)" style
- Headings: `\section`, `\subsection`, `\subsubsection` only — no deeper nesting

### references.bib format

Produce a single `/reports/references.bib` containing all 37 entries from spec section 8. Sample entries:

```bibtex
@article{russell1980circumplex,
  author = {Russell, James A.},
  title  = {A circumplex model of affect},
  journal = {Journal of Personality and Social Psychology},
  volume = {39},
  pages  = {1161--1178},
  year   = {1980}
}

@book{linehan1993dbt,
  author    = {Linehan, Marsha M.},
  title     = {Cognitive-Behavioral Treatment of Borderline Personality Disorder},
  publisher = {Guilford Press},
  year      = {1993}
}

@article{smit2022ewma,
  author = {Smit, Anne C. and Schat, Evelien and Ceulemans, Eva},
  title  = {The Exponentially Weighted Moving Average Procedure for Detecting Changes in Intensive Longitudinal Data},
  journal = {Assessment},
  volume = {30},
  number = {4},
  pages  = {1354--1376},
  year   = {2022}
}
```

Use cite-key convention `<firstauthor><year><shortword>` (lowercase, no spaces).

---

## Tone guidelines

- **Academic** for CSC231 and CSC234 — third person, past tense for completed work, present tense for the product as it exists. Cite every claim that isn't trivially obvious.
- **Honest and reflective** for sprint retrospectives — first person plural ("we found", "we struggled with") is fine. Show what went wrong, not just what went right. The "what the human team caught that the agents missed" section is gold.
- **Evidence-based** for the Enterprise Audit — every claim references a commit hash, ADR number, test result file, or screenshot. No vague "we ensured quality" — be specific: "Domain coverage measured at 84.2% via `flutter test --coverage` on commit `a3f1b9c` (May 18, 2026)".

---

## Avoid

- Marketing language ("revolutionary," "industry-leading," "groundbreaking")
- Overclaiming therapeutic efficacy ("MoodBloom helps users overcome anxiety" — instead: "MoodBloom is designed to support mood awareness, citing Firth et al. 2017 meta-analysis showing small-to-moderate effect sizes (g = 0.38) for mobile mental-health apps")
- Clinical labels applied to users ("anxious users") — say "users with elevated anxiety states" or just describe the persona
- Anything that contradicts the spec copy rules (no "delete/clear/reset" for garden, no "wilting" for plants, no clinical labels)
- Using the bipolar/medical disclaimer text verbatim more than necessary — reference it once with full text, summarize elsewhere

---

## Plan Mode — required before writing

Enter Plan Mode first. Produce:

1. **Read receipts:** confirm you've Read each input source. List any missing paths.
2. **File creation order:** which `.md` and `.tex` files you'll create in what order. Suggested: references.bib first (so all .tex can compile), then Sprint 4 + Sprint 5 retros (shortest), then CSC234 + CSC231 (parallel — different content focus), finally Enterprise Audit (depends on all others).
3. **Per-report outlines:** 1 paragraph per chapter, just enough to show you've thought through the structure.
4. **Risks:** anything that might block you (missing artifacts, ambiguous data, etc.)
5. **Estimate:** rough time / token / file count.

Wait for orchestrator approval before writing any reports. The orchestrator may revise scope or section structures.

---

## Quality gates before declaring done

Before any of the 5 reports is "done":

- [ ] Both `.md` and `.tex` versions exist and contain the same content (one is not a stub).
- [ ] `.tex` version compiles on Overleaf without errors (test by uploading to Overleaf with the shared `references.bib`).
- [ ] All citations in the report appear in `references.bib`.
- [ ] All image references resolve (images exist at the paths cited).
- [ ] Length is within the target band (don't pad to hit a target; don't truncate to fit).
- [ ] Copy rules respected (no "delete/clear/reset/wilting/dead").
- [ ] No clinical labels applied to personas.
- [ ] Reviewed by at least one human team member before submission.

---

## After completion

When all 11 files exist and pass the quality gates:

1. Print a one-line summary per file with line count.
2. Note any caveats (sections that need human review before submission, missing screenshots, etc.).
3. Suggest 2–3 things a human team member should sanity-check before submitting to course portals.

Do not declare the task complete until human review confirms each report is submission-ready.