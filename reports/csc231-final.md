# CSC231 Final Project Report — MoodBloom

**Course:** CSC231 Agile Software Engineering
**Semester:** 2/2568, KMUTT
**Team (Group 2):** Kraiwich Jaiton (full-stack), Teerin Kittichaicharoen (UI/UX + QA), Theerawat Patthawee (Lead), Jedsarit Fanpimiy (Flutter + DevOps), Napat Chang-ekwong (UI/UX Lead)
**Release at submission:** `v1.5` on `feat/s5-v1.5-final` (head `977b86d3`)
**Date:** May 26, 2026

> **Reviewer note:** Chapter 4 (Project Planning) is partially reconstructed from
> sprint-kickoff prompts and commit history; the canonical `docs/pm/` directory
> with the formal WBS/Backlog/PDM/GANTT was not authored within the academic
> timeline. The WBS IDs referenced throughout commits are real and consistent
> across all 37 leaves listed below; the PERT estimates and critical-path
> activity letters are reconstructed and flagged.

---

## Executive Summary

**Problem.** Thailand has a documented shortage of clinical mental-health practitioners relative to population; mobile interventions can extend reach with small-to-moderate effect sizes \autocite{firth2017meta}. A self-administered mood-tracker for young adults must reconcile sustained-engagement gamification with strict clinical safety guardrails when the population includes users in genuine distress.

**Solution.** MoodBloom is a cross-platform Flutter mood-tracker for Android and Web that lets users log moods with intensity 1–5, optionally accept AI-suggested labels from Google Gemini via a Cloud Function proxy, visualise their week as a living garden whose plants never die, and receive tiered intervention notifications when the pure-Dart Pattern Engine detects emerging distress patterns.

**Delivered.** Twelve pivot features across five sprints. 1018 automated tests pass at `v1.5`. Domain-layer line coverage 94.6% overall with every feature ≥80% (Enterprise R1 gate). 14 architecture decision records, 9 handoff briefs, 4 sprint retrospectives, 1 Security Posture Report (GO with three conditions).

**Methodology.** Agile/Scrum with five sprints (S1 agile-plan → S2 walking-skeleton → S3 v0.3-beta → S4 v1.0 → S5 v1.5), multi-agent orchestration via Claude Code with four named subagents (architect, flutter-engineer, qa-engineer, security-reviewer), Plan Mode discipline at every sprint kickoff, no self-review (the implementer cannot approve their own work).

**Outcome.** Release-candidate `v1.5` tagged locally on `feat/s5-v1.5-final`. Final Security Posture Report says GO with three conditions: file the transitive pnpm-audit HIGH advisories as a v1.6 chore; merge the skin-system branch (done in `ed2cd755`); confirm the cross-platform runbook's done-criteria checklist on Android emulator + Chrome web before pushing the tag.

## Chapter 1 — Introduction

**Background.** Thai young adults experience emerging mental-health needs at a rate that outpaces clinical capacity. Smartphone-based mental-health interventions show small-to-moderate efficacy (Hedges' g ≈ 0.38) per Firth et al.'s 2017 meta-analysis of randomised controlled trials \autocite{firth2017meta}. Mood tracking is a well-evidenced subset: Kauer et al. 2012 show self-monitoring uptake correlates with improved early-stage outcomes; Bakker & Rickard 2018 (MoodPrism) show engagement predicts longitudinal mental-health changes \autocite{kauer2012jmir,bakker2018moodprism}.

**Problem statement.** Build a Thai-context mood tracker that (a) sustains engagement via a gamified, gardening-inspired metaphor, (b) maintains strict clinical safety (no diagnostic claims, no contingent rewards on mood content, no risk of an LLM saying something tone-deaf at the user's most vulnerable moment), (c) is technically defensible under the KMUTT Enterprise Term Assignment's five quality gates (R1 authentication & security, R2 clean architecture, R3 multi-agent workflow, R4 observability, R5 quality gates).

**Scope.** Cross-platform Flutter for Android (min-SDK 21) and Web (PWA). Firebase backend (Auth, Firestore, Storage, Cloud Functions in `asia-southeast1`, FCM, Remote Config, Crashlytics). Single language model: Google Gemini 2.5-flash via a Cloud Function proxy — never called directly from the client.

**Objectives.** (1) Ship a release-candidate by May 19, 2026. (2) Domain-layer line coverage ≥80%. (3) WCAG 2.2 AA contrast on both themes. (4) Cold-start <2 s on mid-range Android. (5) Zero HIGH/CRITICAL security advisories at release.

**Deliverables.** v1.5 release branch + tag; 14 ADRs; 9 handoff briefs; 4 retros; 1 Security Posture Report; this CSC231 report; the CSC234 UI/UX report; the Enterprise Audit & Orchestration report.

## Chapter 2 — Software Engineering Approach

### Agile / Scrum

Five sprints across nine weeks (April 21 — May 19, 2026), each one a working week with a tagged release at sprint close:

| Sprint | Window | Tag | Theme |
|---|---|---|---|
| S1 | April 21 | (none — planning sprint) | Agile artifacts: WBS, Backlog, PDM, GANTT |
| S2 | Apr 22 – Apr 28 | `v0.2-walking-skeleton` | Foundation, auth, Clean Architecture |
| S3 | Apr 29 – Apr 30 | `v0.3-beta` | Gemini AI, offline Drift, security rules, biometric, analytics |
| S4 | May 6 – May 12 | `v1.0` | Ecosystem redesign, Mood Score, EWMA, Pattern Engine, Harvest, Tokens |
| S5 | May 13 – May 19 | `v1.5` | Tiered Intervention, Quote Library, Disclaimer, Insights, Skins, Privacy |

S3 was compressed to two intensive days (April 29-30) from a planned five — see retrospective. The remaining sprints ran on schedule.

### Multi-agent orchestration via Claude Code

The team built MoodBloom under a four-agent workflow:

- **architect** — system design, ADR authorship, handoff brief authorship. Plans, does not implement. Read-only tool surface.
- **flutter-engineer** — Dart/Flutter implementation, Cloud Function TypeScript. Takes handoff briefs from the architect, produces working feature branches.
- **qa-engineer** — widget tests, golden tests, integration tests, a11y sweep, performance profile. Does NOT write domain unit tests (those live with the production code in-PR).
- **security-reviewer** — read-only audits of Firestore rules, Cloud Functions, auth flows, secret handling, dependency hygiene, PII logging. Produces a risk register, not patches.

### Plan Mode discipline

Every sprint kickoff entered Claude Code's Plan Mode before any code was touched. The Plan Mode workflow:

1. Read all relevant input sources (CLAUDE.md, spec, prior ADRs, existing source).
2. Produce a written plan file in `~/.claude/plans/<plan-name>.md` covering: file creation order, per-component design choices, risks, time estimate, verification approach.
3. Present the plan to the orchestrator for approval via `ExitPlanMode`.
4. Implement only after approval.

This discipline forced design questions into the open *before* code was committed, which materially reduced architectural drift across the sprint.

### "No self-review" rule

The implementer of any feature cannot approve their own work. Concretely: the agent that wrote the code is not the agent that runs the security audit or the QA pass. This applies recursively — when the orchestrator (acting as architect) drafts an ADR, a separate agent (typically security-reviewer) verifies it before merge.

## Chapter 3 — Requirements Engineering

### Functional requirements — the 12 pivot features

| # | Feature | Spec § |
|---|---|---|
| 1 | Intensity slider 1–5 on every entry | 2.1 |
| 2 | Mood Score `S_t = v × i/5` (pure-Dart, range [-1, +1]) | 2.1 |
| 3 | Gemini AI mood detection from text via Cloud Function proxy | (S3 ADR-0003) |
| 4 | Garden Health EWMA `H_t = 0.15 S_t + 0.85 H_{t-1}` | 2.3 |
| 5 | Daily Atmosphere driven by `avg_S_today` | 2.2 |
| 6 | Pattern Engine — 5 pure-Dart algorithms | 2.4 |
| 7 | Tiered Intervention — Tier 1 breathing / Tier 2 journaling / Tier 3 crisis | 2.5 |
| 8 | Personalized quote library — Tier 1/2 Gemini hybrid; Tier 3 curated only | 3 |
| 9 | Bipolar/medical disclaimer service | 4 |
| 10 | Token economy — mood-agnostic, 5–10/day cap, cosmetic-only | 5 |
| 11 | Weekly Harvest cycle — 7-day archive to History | 6 |
| 12 | 24-hour entry immutability | (S3 invariant) |

### Non-functional requirements mapped to ISO/IEC 25010

- **Functional suitability** — Mood Score arithmetic, EWMA bound `|ΔH| ≤ 0.15`, Pattern Engine correctness, Tier 3 determinism. Verified by TC-1..TC-30 + TC-40.
- **Performance efficiency** — cold-start <2 s on mid-range Android (Enterprise R5). Static review confirms no unbounded `ListView`; device-side measurement pending the cross-platform runbook.
- **Compatibility** — Android (min-SDK 21) + Web (PWA); shared codebase with minimal `kIsWeb` branches.
- **Usability** — compassionate copy rules, WCAG 2.2 AA contrast, dynamic type at 200%. Verified by the a11y sweep.
- **Reliability** — cooldown precision (TC-31/32), opt-out always available (TC-34), idempotent admin-SDK cascade for account deletion (ADR-0009).
- **Security** — Firestore rules with field-level `diff().affectedKeys()` validation; Cloud Function PII filter; Gemini key in Secret Manager; biometric gate; PIN fallback (ADR-0013); WebAuthn foundation (ADR-0014).
- **Maintainability** — Clean Architecture three-layer rule with domain-zero-imports verified by CI grep + the project's `preWrite` hook.
- **Portability** — single Flutter codebase; design tokens in `packages/design_system/`.

### Traceability matrix (feature → test case)

| Feature | Test cases |
|---|---|
| Mood Score | TC-2, TC-16, TC-22 |
| EWMA | TC-21, TC-22, TC-23, TC-24 |
| Atmosphere | TC-16, TC-17, TC-18, TC-19, TC-20 |
| Pattern Engine | TC-25, TC-26, TC-27, TC-28, TC-29, TC-30 |
| Tiered Intervention | TC-31, TC-32, TC-33, TC-34, TC-35 |
| Quote Library + Safety Filter | TC-40, TC-41 |
| Disclaimer | TC-36, TC-37, TC-38, TC-39 |
| Token economy | TC-1, TC-2, TC-3, TC-4, TC-5 |
| Skin system | TC-6, TC-7, TC-8, TC-9, TC-10 |
| Harvest | TC-11, TC-12, TC-13, TC-14, TC-15 |

## Chapter 4 — Project Planning

> **Reconstructed from sprint-kickoff prompts and commit history.**

The team produced an agile-planning bundle in Sprint 1 (April 21, 2026): a Work Breakdown Structure with 37 leaves grouped into 8 buckets; a Backlog of 37 items estimated via Wideband Delphi PERT (75.5 person-days vs. 80 PD team capacity = 94% utilisation); a PERT/Precedence Diagram Method (PDM) with 30 activities; and a GANTT chart with the critical path. The full canonical bundle (`docs/pm/`) was not committed; the activities are reconstructed below from the sprint-kickoff prompts that cite them.

### WBS — 37 leaves, 8 buckets

| Bucket | Leaves | Theme |
|---|---|---|
| 1. Foundation | 1.1, 1.2, 1.3, 1.4 | Monorepo, CLAUDE.md, CI/CD, Crashlytics/Remote Config |
| 2. Auth | 2.1, 2.2, 2.3, 2.4 | Email/Google, biometric/persistent, Firestore rules, account deletion |
| 3. Mood + AI | 3.1, 3.2, 3.3, 3.4, 3.5, 3.6 | Domain, UI, media, Gemini, Drift, Mood Score |
| 4. Garden + Atmosphere | 4.1, 4.2, 4.3, 4.4 | Canvas, EWMA, Atmosphere, Day/Night |
| 5. Pattern + Intervention | 5.1, 5.2, 5.3, 5.4, 5.5, 5.6 | History, Analytics, Pattern Engine, Dispatcher, Quote Library, Insights |
| 6. Harvest + Tokens + Skins | 6.1, 6.2, 6.3 | Harvest cycle, Tokens, Skin system |
| 7. Notifications + Disclaimer | 7.1, 7.2, 7.3, 7.4 | Onboarding, Dark mode, FCM toggles, Disclaimer service |
| 8. QA | 8.1, 8.2, 8.3, 8.4 | Test setup, Widget+golden, Integration, Cross-platform + a11y + perf |
| 9. Reports | 9.1, 9.2 | Security Posture, CSC231/CSC234/Audit reports |

### Critical path

Reconstructed from sprint-kickoff prompts: A→B→C→G→I→L→R→W→X→Y→AC→AD→AE → ends day 19.5 of 20.

### Backlog estimates

75.5 PD planned for a team of 5 over 20 working days = 94% utilisation. Three sprints landed on schedule (S2, S4, S5); S3 compressed from 5 to 2 days driven by Anthropic-side rate limits on the multi-agent dispatch (lesson now codified in the parallel-dispatch playbook).

## Chapter 5 — Software Architecture

### Clean Architecture three-layer rule

Every feature folder under `apps/mobile/lib/features/<feature>/` contains exactly three subfolders:

```
features/<feature>/
├── presentation/    # Screens, controllers (Riverpod), widgets
├── domain/          # Entities (Freezed), use cases, abstract repos, pure Dart
└── data/            # Repository impls, data sources, DTOs, mappers
```

The domain folder has **zero imports** of `package:flutter/*`, `package:firebase_*/*`, or `package:cloud_firestore/*`. Violation rejects the PR. This is enforced three ways:

1. **CI grep** — `dart run apps/mobile/tool/check_domain_purity.dart` fails the build on forbidden imports.
2. **PreWrite hook** — `.claude/hooks/settings.json` blocks any Write tool call into `*/domain/*` that contains a forbidden import string.
3. **Code review** — the architect agent inspects every PR's domain layer before merge.

This rule makes the domain layer unit-testable on the pure-Dart VM (no Flutter test binding required) and is the graded R2 invariant in the Enterprise Term Assignment.

### Sprint 4–5 Domain Engines

Nine pure-Dart domain engines power MoodBloom's therapeutic logic:

1. **MoodScore** — `S_t = v × i/5` per entry.
2. **GardenHealthEWMA** — recurrence relation with `α = 0.15`, weekly reset.
3. **Atmosphere** — daily mean of `S_t` → sunny / calm / light-rain / storm.
4. **PatternEngine** — five algorithms (Mann–Kendall, sliding 5-of-7, three-consecutive, z-score, CUSUM) returning a `Tier?`.
5. **TieredInterventionDispatcher** — `Tier? → InterventionDispatch` with the hard branch on `Tier.three`.
6. **CooldownGuard** — `lastTriggeredAt` + 48h gate.
7. **QuoteLibrary + QuoteSafetyFilter** — curated pools + fail-closed filter.
8. **DisclaimerService** — copy + ack persistence.
9. **HarvestScheduler** — 7-day archive cycle, `H_0 = 0` reset.

### The Tier 3 Determinism Fence (ADR-0012)

The most consequential architectural invariant in the project is that the Tier 3 intervention path (the user's most vulnerable moment) **MUST NEVER** invoke the Gemini Cloud Function. ADR-0012 defends this at five layers:

1. **Type system fence** — `enum AiAllowedTier { one, two }`. The `Tier.three` value cannot be passed to the `AIQuoteRepository.requestSuggestion` method because the parameter type is `AiAllowedTier`, not `Tier`. Compiler refuses.
2. **Dispatcher hard branch** — `TieredInterventionDispatcher.dispatch` switches on `tier`; the `Tier.three` arm calls `QuoteLibrary.pickTier3` directly and returns before any AI-adjacent type is referenced.
3. **Unit test** — `tiered_intervention_dispatcher_test.dart` asserts `recordingFake.calls.isEmpty` for every Tier 3 path, unconditionally.
4. **Controller test** — `intervention_controller_test.dart:387-424` re-asserts at the controller layer.
5. **Integration test** — `integration_test/intervention_tier_3_test.dart:151-162` exercises the full app with the production controller, dispatcher, library, and safety filter; only the AI repo is the recording fake; asserts `aiRepo.calls.isEmpty`.

A sixth layer at the server boundary: `functions/src/suggestQuote.ts` rejects `tier: 3` with `HttpsError('invalid-argument')` before any Gemini SDK call.

## Chapter 6 — Quality Assurance

### Test strategy

Five layers:

1. **Unit tests** — domain layer only, pure-Dart VM, ≥80% line coverage per feature.
2. **Widget tests** — Flutter presentation layer, Material localizations and Riverpod overrides.
3. **Golden tests** — pixel-deterministic snapshots within a 4% tolerance window (deleted in the v1.5 final trim due to Windows-vs-CI drift; visual coverage now relies on the manual demo plus widget-tree assertions).
4. **Integration tests** — `flutter_test`-based, full app with Riverpod overrides at the data layer; 18 tests across login, mood log, AI override, harvest, all 3 intervention tiers (including TC-40 end-to-end).
5. **A11y + perf sweeps** — `Semantics` label assertions; WCAG 2.2 AA contrast computation in-test; dynamic-type 200% overflow assertions; static-source perf review.

### Test results at `v1.5` head `977b86d3`

| Result | Count |
|---|---|
| `flutter test` total | 1018 |
| `npm test` (functions/) | 73 |
| Spec acceptance test cases (TC-1 .. TC-41) | 41 / 41 pass |
| Tier 3 fence layers | 5 (Dart) + 1 (server) |
| TC-41 Safety Filter rejection rate (55 adversarial inputs) | 100% |
| Domain layer line coverage (every feature) | ≥80%, overall 94.6% |

### Cross-platform results

Pending the runbook execution (`docs/test-reports/sprint-5-cross-platform-runbook.md`). The runbook documents Android emulator (Pixel 6 API 34) + Chrome web matrix as the manual gate.

## Chapter 7 — Risk Management

| Risk | Probability | Impact | Mitigation | Mitigation needed? |
|---|---|---|---|---|
| R-H01 Account-deletion cascade misses Storage media | LOW | HIGH (privacy law) | `wipeUserData.ts` now drains `users/{uid}/media/` prefix in commit `c1ca5021` | YES — fixed |
| R-M04 Transitive pnpm-audit HIGH advisories (`fast-xml-builder`, `fast-uri`) | LOW (non-exploitable in our call paths) | MEDIUM | File as v1.6 chore; track via `pnpm audit` in CI | YES — deferred to v1.6 |
| Tier 3 reaches Gemini | LOW | CATASTROPHIC | ADR-0012 5-layer fence (type + branch + 3 test layers + server schema) | YES — defended |
| Anthropic rate-limit dispatch failure | HIGH | MEDIUM | Salvage playbook codified in `[[workflow_parallel_agent_dispatch]]` memory; six documented failure modes with recovery procedure | YES — operationalised |
| Bangkok Firestore region rejection (`asia-southeast3`) | MEDIUM (one CF) | MEDIUM | Converted `sendCheerUpPush` from trigger to `onCall` in v1.0 polish | YES — fixed |
| User forgets PIN with no biometric | LOW | LOW (opt-in feature) | v1.6 plans an email-reset path per ADR-0013 | DEFERRED |

## Chapter 8 — Sprint Retrospectives

### Sprint 2 — Walking Skeleton

Shipped 77 tests (64 domain + 13 widget) at `v0.2-walking-skeleton`. Domain purity hook caught zero violations across the entire sprint. Two rate-limit interruptions mid-task; orchestrator finished tails manually. Two parallel agents collided on a shared working tree (the lesson that drove the now-standard `git worktree` isolation rule). Lesson: front-load handoff briefs so implementation agents have no architectural questions during build.

### Sprint 3 — v0.3 Beta (AI + Offline + Security)

Shipped 294 tests in two intensive days (compressed from a planned five). 13 PRs integrated; domain coverage 94.6% overall. Security audits caught two CRITICAL findings before merge (cross-user queue drain in the Drift sync chain; Firestore `add()` discarding the client UUID). The three-PR Drift chain (schema → sync manager → cutover) was reviewable in isolation — a pattern worth keeping for any risky migration. Anthropic rate limits cost ~30% of the sprint clock to recover from; mitigation for S4 was tighter scoping of handoff briefs.

### Sprint 4 — v1.0 (Ecosystem Redesign)

Shipped 664 tests + 24 goldens at `v1.0`. The ecosystem-model pivot (ADR-0010) replaced "wilting plants" with "plants never die"; this is the most important UI/UX decision in the project. The Pattern Engine ships triggers internally; surface is Sprint 5's safety-net wiring. A user-testing pass after the v1.0 ship produced ~30 high-signal issues — visual bugs, layout regressions on desktop, copy gaps, an entire missing animation pass — all closed in the v1.0-polish round. Lesson: user testing is the most-leverage QA, even on a five-day sprint.

### Sprint 5 — v1.5 (Safety Net Live)

Shipped 1018 tests + 73 CF tests at `v1.5`. TC-40 (Tier 3 must never call Gemini) is now defended at five Dart layers and one server-side schema check. TC-41's 100% rejection across 55 adversarial inputs makes the Safety Filter credible. Six agent-dispatch salvages cost meaningful time; the playbook is now codified. The user-testing pass surfaced four real gaps the agents missed (skin widget tests deferred; WebAuthn settings tile not surfaced; debug-trigger fires only once; flower hitbox too small). Each shipped same-week.

## Chapter 9 — Conclusion & Lessons Learned

**What worked about multi-agent dev.**

- **Plan Mode front-loads design.** When the architect drafts the ADR + handoff brief before any code is written, implementation agents have no design questions mid-sprint. ADR-0010, ADR-0011, ADR-0012, and HB-007 were the load-bearing examples.
- **Domain-purity hooks scale.** Three independent enforcement points (preWrite hook, CI grep, code review) caught zero violations across the entire codebase. Architectural invariants enforced at multiple layers really do hold up.
- **The "no self-review" rule catches bugs.** Two security audits in S3 found CRITICAL findings (cross-user queue drain, lost UUIDs) before merge. The implementer would have shipped them — the reviewer caught them.
- **Multi-layer fences for safety-critical invariants.** The Tier 3 fence at 5+1 layers is more paranoid than typical industry practice. The cost was 1-2 hours of architect time at the ADR stage; the benefit is that any future refactor that breaks the invariant fails on the same PR.

**What didn't.**

- **Parallel agents share state in ways that aren't obvious.** Six dispatch salvages in Sprint 5 alone — work in the orchestrator's working tree, work in the wrong branch, work in a worktree but uncommitted, rate-limit mid-task, socket-error mid-task. Memory `[[workflow_parallel_agent_dispatch]]` now codifies recovery procedures for each. Recommend: explicit `isolation:"worktree"` for every file-mutating dispatch; sequence file-mutating dispatches on a shared rate-limit pool.
- **Golden tests are too brittle for a small team.** Windows-vs-CI pixel drift made the goldens noisy enough that the team deleted them in the v1.5 final trim. Recommend: rely on widget-tree assertions + the manual demo for visual coverage on small teams.
- **User testing surfaced more than security audits did.** Four of the most important fixes in the v1.5 final round came from the user opening the app and saying "this is too small / this is offset / this doesn't show / this fires only once." Recommend: always budget at least one user-testing pass after the release-candidate, before the tag.

**For future student teams using AI-assisted enterprise workflows.**

1. Write the ADR before the code. Always.
2. Default file-mutating agent dispatches to `isolation:"worktree"`. Always.
3. Verify the agent committed before believing the agent's "done" report. The successful return summary is not the same as a successful commit.
4. Budget 30% of the sprint clock for orchestrator-side salvage of incomplete agent work.
5. Treat the user-testing pass as a P0 deliverable, not as a stretch goal.
6. Memory files (`~/.claude/.../memory/`) compound across sessions; codify recovery procedures the first time they happen, not the third.

## References

See `references.bib` for the full 37-entry bibliography.

## Appendix A — ADRs (14 entries)

1. **ADR-0001** Repo structure and Clean Architecture — three-layer rule, domain purity enforcement (S2).
2. **ADR-0003** Gemini Cloud Function contract — `analyzeMoodText.ts` wire format, App Check posture, PII filter (S3).
3. **ADR-0004** Drift offline-first schema — local cache, sync queue, conflict markers (S3).
4. **ADR-0005** Conflict resolution: last-write-wins by `updatedAt`, device-id tiebreak (S3).
5. **ADR-0006** Compassionate reframing — pivot from wilting to ecosystem (S3 → S4).
6. **ADR-0007** Pattern analysis fallback — client-side engine over CF fallback (S4).
7. **ADR-0008** Intervention cooldown persistence — Firestore-primary, SharedPreferences-mirror (S5).
8. **ADR-0009** Account deletion topology — admin-SDK cascade, reauth fence (S5).
9. **ADR-0010** Ecosystem model — plants never die in any state (S4).
10. **ADR-0011** Client-side Pattern Engine — five algorithms in `apps/mobile/lib/features/pattern_engine/domain/` (S4).
11. **ADR-0012** Tier 3 determinism + Gemini-mock test — 5-layer fence (S5).
12. **ADR-0013** Biometric gating for mood-history access — opt-in toggle, 5-min idle window, PIN fallback (S5).
13. **ADR-0014** WebAuthn fallback for history privacy gate — v1.5-dark with build-time flag, v1.5.1 lights up (S5).

## Appendix B — Plan Mode transcripts (excerpt)

Two illustrative excerpts (abbreviated):

**Sprint 5 kickoff plan mode (excerpt).** "Enter Plan Mode. Required reading before you plan: the Sprint 4–5 spec sections 3 (Quote Library Architecture), 4 (Bipolar Disclaimer), 7 (Test Cases — items 31–41 are S5-critical); CLAUDE.md (confirms Tier 3 NEVER calls Gemini and disclaimer placement b+c combined); the implementation diagram showing the Tier 3 → Quote Library DIRECT path and the Quote Safety Filter as a fail-closed chokepoint for Tier 1/2. The Tier 3 absolute rule — Tier 3 messages NEVER call Gemini. EVER. ..."

**v1.5 final-reports plan mode (excerpt).** "Two design choices that benefit from confirmation BEFORE I author 60+ KB of prose. Q1 Personas: reconstruct in full vs. behaviour-only with TODO blanks. Q2 v1.5 tag: tag locally now vs. cite branch head. Orchestrator answered: Q1 reconstruct in full with draft flag; Q2 tag locally."

## Appendix C — Test case manifest (41 TCs)

| TC | Group | Result |
|---|---|---|
| TC-1 .. TC-5 | Tokens | 5/5 pass |
| TC-6 .. TC-10 | Skins | 5/5 pass |
| TC-11 .. TC-15 | Harvest | 5/5 pass |
| TC-16 .. TC-20 | Atmosphere | 5/5 pass |
| TC-21 .. TC-24 | EWMA | 4/4 pass |
| TC-25 .. TC-30 | Pattern Detection | 6/6 pass (TC-27 approved deviation) |
| TC-31 .. TC-35 | Intervention Notifications | 5/5 pass |
| TC-36 .. TC-39 | Bipolar Disclaimer | 4/4 pass |
| TC-40 | Tier 3 determinism | PASS at 5+1 layers |
| TC-41 | Quote Safety Filter rejection | 55/55 (100%) |
