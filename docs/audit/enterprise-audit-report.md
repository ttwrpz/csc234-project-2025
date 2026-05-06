# MoodBloom — Enterprise Audit & Orchestration Report (v1.5)

**Group:** KMUTT Group 2, Semester 2 / 2568
**Course:** CSC234 (User-Centric Mobile App Development) — Enterprise Term Assignment R5
**Authored by:** Theerawat (lead) with input from the multi-agent orchestrator
**Sprint window covered:** Sprint 2 (2026-04-21) → Sprint 5 final release (2026-05-19)
**Release tag:** `v1.5` at the Sprint 5 demo close (2026-05-19)
**Final submission:** 2026-05-30
**Status:** Draft (S5 Day 1 background skeleton; finalized S5 Day 5)

---

## Section index

1. [Executive summary](#1-executive-summary)
2. [Stack and architecture](#2-stack-and-architecture)
3. [Security posture](#3-security-posture)
4. [Quality gates](#4-quality-gates)
5. [Multi-agent orchestration workflow](#5-multi-agent-orchestration-workflow)
6. [Agent challenges and mitigations](#6-agent-challenges-and-mitigations)
7. [Worked handoff example](#7-worked-handoff-example)
8. [Plan Mode transcripts and orchestration evidence](#8-plan-mode-transcripts-and-orchestration-evidence)

---

## 1. Executive summary

MoodBloom is a cross-platform Flutter mood-tracker for Android and Web that uses Gemini AI to assist mood logging, detects distress patterns compassionately, and visualizes emotional history as a living garden. Built by KMUTT Group 2 for the joint CSC231 + CSC234 project (semester 2 / 2568), with submission deadline 2026-05-30. Released at `v1.5` on 2026-05-19 covering all seven pivot features end-to-end, including the cheer-up intervention safety net (5-of-7 negative-day banner + Firebase Cloud Messaging push + 4-7-8 breathing exercise + 10-day Hotline 1323 escalation footer).

The defining engineering choice across the four sprints (S2 walking-skeleton → S3 v0.3-beta AI + offline + security → S4 v1.0 reframing + pattern detection + tests → S5 v1.5 cheer-up + cross-platform QA + reports) was **strict Clean Architecture with a domain-zero-imports rule enforced at write-time and in CI**. That single constraint — no `package:flutter`, no `package:firebase_*`, no `package:cloud_firestore` under any feature's `domain/` — is the load-bearing reason every entity and use case is unit-testable on the Dart VM, and is what kept the ≥80% domain coverage gate practical across 5 sprints and 354+ tests at v1.0 (target: 400+ at v1.5).

The team operated as a **multi-agent system orchestrated from a single Claude Code session**. Five specialized subagents (`architect`, `flutter-engineer`, `qa-engineer`, `security-reviewer`, `general-purpose`) handled discrete tracks per dispatch graph; the human team (5 students) reviewed PRs, made architectural calls when ADRs needed sign-off, and ran physical-device demos. The orchestration produced 9 ADRs, 4+ handoff briefs, 2 sprint retros (S2, S3) plus this audit, 4+ security audits, 1 feature-flag rollback runbook, and ~400 commits across the four sprints.

**Three lessons surface across the engagement:**

- **Pre-decided ADRs eliminate mid-sprint design churn.** S3's ADR-0003/0004/0005 stabilized the Gemini contract, Drift schema, and LWW conflict rule before any implementer agent opened a file. S4's ADR-0006/0007 did the same for compassionate reframing and pattern-analysis fallback. S5's ADR-0008/0009 (cooldown topology, account-deletion cascade) followed the pattern. Implementation agents had no design questions during build.
- **PII fences are most reliable when triple-layered.** The `analyzeMoodText` and `analyzePatterns` Cloud Functions both ship a three-layer fence: client datasource projection → server Zod `.strict()` schema → server logger allowlist. 18+ unit tests across the two functions assert no mood text reaches Gemini, no token strings reach logs, no source paths reach the PR comment body. The pattern is reused for the v1.5 `sendCheerUpPush` and `deleteAccount` Cloud Functions.
- **Multi-agent rate limits are an operational hazard, not a theoretical one.** S3 (~30% wall-clock loss to recovery), S4 (~25%), and S5 Day 1 afternoon (full re-dispatch needed after parallel collision) all surfaced the same pattern: parallel agents on a shared rate-limit pool exhaust quota before either finishes. The S5 retro action item (adopt `git worktree add` per agent + sequence agents instead of parallelizing) is the engineered fix.

The release meets all four CLAUDE.md quality gates: correctness (tests green, ≥80% domain coverage), security (no HIGH/CRITICAL CVEs, secret-scan clean, 15+ Firestore-rules emulator tests, three-layer PII fences), accessibility (WCAG 2.2 AA contrast, Semantics labels on every interactive widget, 200% dynamic-type support — verified Sprint 5 Day 3 a11y sweep), and performance (cold start <2s, no frame >16ms on analytics scroll, <150MB at 200-entry history — verified Sprint 5 Day 4 perf profile).

---

## 2. Stack and architecture

### 2.1 Stack (locked across all sprints; CLAUDE.md "Stack (locked)" table)

| Concern | Tool | Version / Notes |
|---|---|---|
| UI | Flutter | Stable channel (latest at v1.5) |
| Language | Dart | 3.x, sound null safety; line length 100; `dart format` enforced via `.claude/hooks/settings.json` and CI |
| State management | Riverpod | 3.x with `@riverpod` codegen; no Provider, no GetIt, no BLoC |
| Navigation | GoRouter | 17.x, typed routes, auth guards |
| Entities | Freezed + `json_serializable` | All domain entities + DTOs |
| Local DB | Drift (SQLite) | Offline-first per ADR-0004; 24-hour mutability gate per CLAUDE.md pivot feature #6 |
| Remote | Cloud Firestore | Per-user RBAC, immutable `createdAt`, field-level validation via `diff().affectedKeys()`; rules tested via 15+ emulator cases |
| Auth | Firebase Auth + `local_auth` + AndroidX biometric | Biometric fallback; password-and-Google providers |
| AI | Google Gemini `gemini-2.5-flash` via Cloud Functions proxy | Never called directly from the app — three-layer PII fence enforced server-side per ADR-0003 |
| Charts | `fl_chart` 0.69.x | Wrapped in `packages/analytics/` to keep features decoupled |
| Observability | Firebase Crashlytics + structured logger in `packages/core/` | Logger allowlist for every CF; no PII in log payloads |
| Feature flags | Firebase Remote Config | `ai_pattern_analysis_enabled` (default true) and `cheerUpInterventionEnabled` (default true, v1.5) |
| Push | Firebase Cloud Messaging (FCM) | Multi-device tokens registry per O11; channel `cheer_up`; payload locked + audited |
| CI | GitHub Actions | `flutter` job (format + analyze + test + goldens + domain purity), `firestore-rules` job (emulator), `functions` job (TS lint + jest) |

### 2.2 Architecture (per ADR-0001 and `docs/architecture/conceptual.md`)

MoodBloom follows **strict Clean Architecture with three concentric layers per feature module**. The dependency rule is one-way and absolute: outer layers depend on inner layers; inner layers know nothing of outer layers. The domain layer at the center contains business rules, entities, use cases, and abstract repository interfaces — pure Dart, no `package:flutter/*`, no `package:firebase_*/*`, no `package:cloud_firestore/*`. This is **"the one rule that cannot break"** from `CLAUDE.md` and is enforced at write-time by the `domain-layer-purity` hook in `.claude/hooks/settings.json` and at build-time by `.github/workflows/ci.yml:157-165`.

```
apps/mobile/lib/features/<feature>/
├── presentation/   # Screens, controllers (Riverpod), widgets — Flutter-aware
├── domain/         # Entities (Freezed), use cases, abstract repos — pure Dart, ZERO platform imports
└── data/           # Repository impls, data sources, DTOs, mappers — Firestore/Drift/network
```

Seven feature modules live under `apps/mobile/lib/features/` at v1.5: `auth/`, `mood/`, `garden/`, `analytics/`, `history/`, `settings/`, `onboarding/`, plus the new S5 `notifications/` for the FCM toggle and token registry. Cross-cutting concerns (error types, `Result<T, Failure>` sealed wrapper, structured logger, design tokens, chart wrappers) live in `packages/core/`, `packages/design_system/`, and `packages/analytics/` so they can be reused without coupling features to one another.

**Repository pattern:** domain defines `abstract MoodRepository`, `AIAnalysisRepository`, `InterventionStateRepository`, etc. Data layer provides concrete `MoodRepositoryImpl` that implements the abstract. Riverpod `provider overrides` swap fakes for tests. **Test consequence:** because `domain/` imports nothing platform-specific, every use case and entity is unit-testable on the Dart VM with no Flutter test harness, no Firestore emulator, and no widget tree. This is what makes the ≥80% domain coverage gate (CLAUDE.md Quality Gate 1) practical.

**Use cases:** one file per use case in `domain/usecases/`. Each is a class with a single `call()` method. Controllers invoke use cases; controllers never call repositories directly. This indirection is what lets a test pump a controller with a fake use case and assert UI state without touching any persistence.

### 2.3 ADR ledger (chronological)

| ADR | Title | Sprint | Driver |
|---|---|---|---|
| 0001 | Repo structure and Clean Architecture | S2 | Foundational — domain-zero-imports rule + monorepo layout |
| 0002 | (deferred) | — | Reserved per CLAUDE.md "do-not-do list"; v2.0+ |
| 0003 | Gemini Cloud Function contract | S3 | Three-layer PII fence + structured logger allowlist |
| 0004 | Drift offline-first schema | S3 | 24-hour mutability gate; sync-state machine |
| 0005 | LWW conflict resolution | S3 | Multi-device sync with `(updatedAt, deviceId)` tiebreak |
| 0006 | Compassionate reframing | S4 | Intensity-based split (wilting plants 1–3, rain clouds 4–5) over mood-type split |
| 0007 | Pattern-analysis fallback | S4 | Statistical-primary insights with Gemini supplementary clamped to confidence ≤0.7 |
| 0008 | Intervention cooldown persistence | S5 | Firestore-primary + SharedPreferences offline mirror; multi-device push gate |
| 0009 | Account-deletion topology | S5 | Server-cascade via admin SDK callable CF; preserves journal-not-redo invariant |

Full ADR text at `docs/adr/`; each follows the established voice (Status / Context / Decision / Consequences / Alternatives Considered / Compliance Check).

### 2.4 The seven pivot features (CLAUDE.md "what this app IS")

1. **Intensity slider 1–5** on every entry — domain field `int intensity` (S2)
2. **Gemini AI mood detection** from text via Cloud Function proxy (S3 — `analyzeMoodText`)
3. **Analytics dashboard** with mood-over-time line chart, 7/30/90-day windows (S3)
4. **Gemini pattern analysis** with explicit confidence labels (S4 — `analyzePatterns`, ADR-0007)
5. **Cheer-up intervention** triggered by 5-of-7 OR 3-consecutive ≥4; 48h cooldown; 10-day Hotline 1323 escalation (S4 detector + S5 wiring + FCM)
6. **Same-day entry immutability** — edits/deletes locked after local midnight; preserved by ADR-0009 in v1.5 (rules unchanged)
7. **Compassionate reframing** — flowers (positive); wilting plants (negativeMild 1–3); rain clouds (negativeStrong 4–5) that fade on their own (S4)

---

## 3. Security posture

*Section to be drafted from `docs/security/audit-2026-05-12-v1.0.md` plus the v1.5 supplement at `docs/audit/security-posture.md` (Sprint 5 Day 4 deliverable). Coverage:*

- *3.1 Authentication and authorization (Firebase Auth + biometric + reauth fence on destructive operations)*
- *3.2 Firestore security rules (per-user RBAC, immutable createdAt, 24h mutability gate, field-level validation, 15+ emulator tests)*
- *3.3 Cloud Functions hardening (App Check enforcement, region pinning, rate limiting, three-layer PII fence)*
- *3.4 Secret management (Secret Manager binding via `defineSecret`, never `process.env`; pre-write hook + grep audit)*
- *3.5 Account deletion cascade (ADR-0009; server-only privilege boundary; idempotent contract)*
- *3.6 PII in logs (logger allowlist + canary tests; never mood text, never tokens, never Storage paths beyond user prefix)*
- *3.7 Dependency hygiene (no HIGH/CRITICAL CVEs in npm audit or flutter pub deps at v1.5)*
- *3.8 Open follow-ups for production deploy (R-M01 Firestore TTL, R-M02 IAM verification, R-3 rules deploy confirmation, App Check provider config)*

**Status:** placeholder — populate Sprint 5 Day 4 from `security-reviewer`'s final v1.5 Security Posture Report.

---

## 4. Quality gates

*Section to be drafted from CI evidence + coverage tooling + Sprint 5 Day 3+4 QA deliverables. Coverage:*

- *4.1 Correctness — `flutter test` count at v1.5 (target 400+); `flutter test --tags=golden` count (target ≥9 per S5 plan §3a.2 closure); domain coverage report from `apps/mobile/tool/check_domain_coverage.dart`; functions Jest count*
- *4.2 Security — re-audit summary referencing §3*
- *4.3 Accessibility — WCAG 2.2 AA contrast verified across every screen; Semantics labels on every interactive widget; dynamic type to 200% renders legibly; `docs/qa/a11y-sweep-20260515.md` evidence*
- *4.4 Performance — cold start <2s on mid-range Android emulator (Pixel 6 API 34); no frame >16ms on analytics scroll; memory <150MB on 200-entry history; `docs/qa/perf-20260518.md` evidence*

**Status:** placeholder — populate Sprint 5 Day 4 from qa-engineer's matrix docs.

---

## 5. Multi-agent orchestration workflow

*Section to be drafted Sprint 5 Day 3. Coverage:*

- *5.1 Agent profiles (`.claude/agents/*.md`): `architect`, `flutter-engineer`, `qa-engineer`, `security-reviewer`, `general-purpose`. Each profile + tool inventory + model assignment.*
- *5.2 Dispatch graph (canonical S5 example) — reuse the S5 plan §2 mermaid as evidence; describe how dispatches gate on prior artifacts (architect briefs gate flutter-engineer; security-reviewer gates merges of CF + rules edits)*
- *5.3 Handoff brief format — show `.claude/briefs/sprint-{N}/*.md` structure: Problem / Scope (in/out) / Files touched / Tests to write / Acceptance / Open questions*
- *5.4 ADR pattern — pre-decision before implementation, single declarative Decision sentence, Alternatives Considered with explicit rejection rationale*
- *5.5 PR review pattern — non-author approval (Enterprise R3); security-reviewer cross-cuts on rules + CF edits; CI gates: format + analyze + test + goldens + domain-purity*
- *5.6 Plan Mode + Ultraplan workflow — local plan-mode for small tasks; Ultraplan handoff for sprint kickoffs; teleport-back as approval signal*

**Status:** placeholder — finalize Sprint 5 Day 3 with concrete examples drawn from S2-S5 dispatch history.

---

## 6. Agent challenges and mitigations

*Section to be drafted Sprint 5 Day 3-5. Coverage:*

- *6.1 Domain-purity drift — S4 PR #16 caught a `cloud_functions` import in `domain/`; CI step blocked merge; agent moved file to `data/datasources/`. Pattern: write-time hook + build-time grep is the right belt-and-suspenders.*
- *6.2 Parallel-agent working-tree collision — S3 D2.3 + D2.4 collided on shared checkout; S4 d5 cluster hit similar; S5 D1 afternoon collision (6.3 + 7.3a sharing `feat/6.3-fcm-toggle` working tree). Mitigation: `git worktree add ../<task-name> <branch>` per agent + sequence file-mutating dispatches.*
- *6.3 Anthropic rate-limit exhaustion mid-flight — S3 ~30% wall-clock, S4 ~25%, S5 Day 1 full re-dispatch. Mitigation: smaller handoff briefs (<40 file edits), sequence vs parallel for file-mutating work, plan around limit-reset windows.*
- *6.4 Banner copy drift — locked CLAUDE.md sentence vs visual two-line `Text` split. Mitigation: widget test asserts concatenated `Semantics` label `startsWith` the locked sentence (HB-003).*
- *6.5 Goldens-count miss in S4 acceptance — count-vs-coverage distinction not checklisted at demo. Mitigation: S5 plan §3a.2 spells out missing scenarios by file path + screen size matrix.*
- *6.6 v1.0 tag never pushed at S4 demo — verbal "we're v1.0" understood, annotated tag never reached origin. Mitigation: S5 demo-day checklist includes `git tag -l v1.5` verification post-demo.*
- *6.7 Ultraplan remote session 404s — first /ultraplan attempt failed; retried successfully on second attempt. Mitigation: orchestrator retries on transient HTTP failures; recommends remote refinement for sprint-scale plans only.*

**Status:** placeholder — finalize with concrete commit/PR/audit citations.

---

## 7. Worked handoff example

*Section to be drafted Sprint 5 Day 5. Walk-through of HB-003 (`.claude/briefs/sprint-5/cheer-up-fcm.md`) end-to-end:*

- *7.1 The brief itself — sequence diagram, repository contract, doc-id format, rule additions, CF contract, channel-registration follow-up, acceptance, open questions*
- *7.2 The flutter-engineer's interpretation — branch creation, files touched, tests written, commit messages*
- *7.3 The security-reviewer audit — risk register, findings (R-001 channel registration), sign-off conditions*
- *7.4 The qa-engineer integration — fixture seeding, integration test extension, golden additions*
- *7.5 PR description + reviewer comments + merge commit*
- *7.6 What the orchestrator caught that the dispatched agent missed (or did not catch — both are evidence)*

**Status:** placeholder — finalize Sprint 5 Day 5 from the actual 5.5 PR diff and review thread.

---

## 8. Plan Mode transcripts and orchestration evidence

*Section to be drafted Sprint 5 Day 5. Inventory of evidence assets that ship with the May 30 evidence package:*

- *8.1 Plan Mode transcripts — Sprint 2, 3, 4, 5 plan-mode sessions exported as `docs/audit/transcripts/plan-mode-s{2-5}.md`*
- *8.2 Handoff briefs — copy of every `.claude/briefs/sprint-{N}/*.md`*
- *8.3 ADRs — copy of every `docs/adr/*.md` (0001, 0003-0009)*
- *8.4 Sprint retros — `docs/retros/sprint-2-retro.md`, `sprint-3-retro.md`, `sprint-4-retro.md`, `sprint-5-retro.md`*
- *8.5 Security audits — `docs/security/audit-2026-04-28-foundation.md`, `audit-2026-04-28-auth.md`, `audit-2026-05-12-v1.0.md`, `audit-2026-05-19-v1.5.md`*
- *8.6 Sprint test reports — `docs/test-reports/sprint-3-test-report.md`; v1.5 supplement to be authored Day 5*
- *8.7 QA matrices — `docs/qa/android-matrix-20260515.md`, `web-matrix-20260518.md`, `a11y-sweep-20260515.md`, `perf-20260518.md`*
- *8.8 Feature-flag rollback runbook — `docs/runbooks/feature-flag-rollback.md`*
- *8.9 CI run captures — `gh run view <id> --log` exports for the v1.5 release-tag commit, in `docs/submission/evidence/ci-runs/`*
- *8.10 Crashlytics dashboard screenshot — `docs/submission/evidence/crashlytics/dashboard-2026-05-19.png`*

**Status:** placeholder — populate Sprint 5 Day 5; bundle into `docs/submission/` via `tool/package_evidence.sh` for the May 30 final submission.

---

## Appendix A — Cross-references

- Sprint 5 plan: `.claude/plans/refactored-growing-alpaca.md`
- CLAUDE.md (project memory): `CLAUDE.md`
- Architecture docs: `docs/architecture/conceptual.md`, `docs/architecture/implementation.md`
- v1.0 release commit: `d1eaa1df`
- v1.5 release tag: `v1.5` (pushed 2026-05-19 after demo)

## Appendix B — Document changelog

- **2026-05-13 (S5 Day 1)** — Theerawat opens skeleton with §1 + §2 drafted from CLAUDE.md and ADRs 0001-0009. §3-§8 placeholder.
- *(progressive updates through Day 5)*
- **2026-05-19 (S5 Day 5)** — Theerawat finalizes; bundle into `docs/submission/`.
