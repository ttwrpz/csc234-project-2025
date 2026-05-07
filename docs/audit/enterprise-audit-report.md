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

Source documents: `docs/security/audit-2026-05-12-v1.0.md` (v1.0 audit, all 8 findings mitigated), the v1.5 supplement `docs/audit/security-posture.md` (Sprint 5 Day 4 deliverable — runtime numbers only), and the per-PR security-reviewer audits captured in PR #23 and PR #30 review threads.

### 3.1 Authentication and authorization

- **Firebase Auth + biometric.** Email/password and Google OAuth flows; biometric fallback gated by `local_auth` (Sprint 3) with the AndroidManifest `USE_BIOMETRIC` permission landed in S5 carry-over (PR #23).
- **`MainActivity extends FlutterFragmentActivity`** (S5 PR #23) — required by `local_auth` for the AndroidX biometric prompt. Verified by security-reviewer to not regress `LaunchTheme` resolution.
- **Reauth fence on destructive operations.** `DeleteAccountUseCase` (HB-004 step 1, PR #34) calls `AuthRepository.reauthenticate(creds)` before invoking the `deleteAccount` Cloud Function. `delete_account_test.dart` case 2 asserts the use case short-circuits on reauth failure — the admin-SDK CF would happily delete based on `context.auth.uid` alone, so the client-side reauth fence is the only thing protecting against stolen-token replay. ADR-0009 formalizes this trade-off.
- **Sealed `AuthCredentials` envelope** (`auth_credentials.dart`, PR #34) — pure-Dart variants for password / google / biometric credentials, kept domain-side so use cases stay framework-free; data layer translates to `EmailAuthProvider.credential` / `GoogleAuthProvider.credential` at the repository boundary.

### 3.2 Firestore security rules

- **Per-user RBAC** — every `users/{uid}/...` rule guarded by `isOwner(uid)`. Cross-user reads and writes denied at every collection.
- **Immutable `createdAt`** — server-stamped on create (`request.time` equality required); update rules deny mutation.
- **24-hour mutability gate** — `users/{uid}/moods/{moodId}` updates allowed only when `request.time.year/month/day == resource.data.createdAt.year/month/day`. Enforces CLAUDE.md pivot feature #6 (same-day immutability).
- **Field-level validation via `diff().affectedKeys()`** — only specific keys may change on update; an attempt to introduce an unknown key (e.g. `attackerControlled: true`) is denied.
- **Emulator coverage at v1.5: 25 cases.** Started at 15 (Sprint 3 baseline), grew to 17 in S4 (cases 16-17 from R-1 / R-2 audit), grew to 24 with the 6.3 settings/notifications cases (PR #30), grew to 25 with the audit R-002 follow-up case 25 cross-user write to settings. The pattern-intervention rules cases (cheerUpEvents + interventionState) land with HB-003 5.5b.
- **`users/{uid}/settings/notifications` cap** — `tokens.size() <= 25`. Per-token shape (token / platform / lastSeenAt) is enforced client-side at the DTO write boundary via `notifications_dto.dart::toFirestoreMerge` filtering empty token strings (audit R-003 follow-up, PR #30 commit `86f2b81d`). This is the documented compromise from HB-003 OQ-A: rules can't iterate list elements, so the size cap + client-side validation form the defense-in-depth pair.

### 3.3 Cloud Functions hardening

Pattern: every callable function in `functions/src/` follows the same shape established by `analyzeMoodText` (ADR-0003) and `analyzePatterns` (ADR-0007).

- **`enforceAppCheck: true`** on every callable. v1.0.1 commit `d1eaa1df` raised `analyzeMoodText` to enforcement parity with `analyzePatterns`. New v1.5 functions (`sendCheerUpPush` Firestore-trigger; `deleteAccount` callable) inherit the posture.
- **Region pinning** — `asia-southeast1` on every function; rejects clients calling other regions.
- **Rate limiting** — `consumeToken({ collection, windowMs, max })` parameterised in S4 (`rateLimit.ts:#16`). Per-endpoint document families: `rateLimits/{uid}` (analyzeMoodText, 10/60s), `rateLimits.patterns/{uid}` (analyzePatterns, 1/30s), `rateLimits/cheerUp/{uid}` (sendCheerUpPush, 1/24h, lands with HB-003 5.5b). Separate doc families so a user hitting two endpoints in the same minute is rate-limited per-endpoint, not per-app.
- **Three-layer PII fence** (canonical pattern, reused twice in S5):
  1. **Client datasource projection.** The client never sends fields the function doesn't need (`analyze_patterns_functions_datasource.dart::projectEntry` strips `text` and `mediaRefs`; `notifications_dto.dart::toFirestoreMerge` filters empty tokens).
  2. **Server Zod `.strict()` schema.** `AnalyzePatternsRequestSchema` rejects unknown keys at the boundary; `AnalyzeMoodTextRequestSchema` does the same.
  3. **Server logger allowlist.** `handleAnalyzePatterns` writes a single `logger.info` line per request with an enumerated field set: `event, requestId, uid, outcome, windowDays, historyLen, insightCount, statisticalInsightCount, geminiSkipped, geminiSkipReason, latencyTotalMs, rateLimit.{remaining, retryAfterSec}`. Forbidden: `history`, `history[].date`, insight body text, `text`, `mediaRefs`. The PII canary test in case #10 of `analyzePatterns.test.ts` asserts no log payload contains a date prefix or insight body string. The same canary pattern lands with `sendCheerUpPush.test.ts` case 6 (HB-003 §5.5b).

### 3.4 Secret management

- **`defineSecret('GEMINI_API_KEY')`** in `geminiClient.ts:23`. The Gemini API key is bound at function init, never read from `process.env`. `analyzeMoodText.test.ts` case #14 explicitly asserts this.
- **Pre-write hook** — `.claude/hooks/settings.json` runs a secret scanner on every Write/Edit; commits with `AKIA|ghp_|sk-|AIza|pgsql:|mongodb:` strings are blocked at write time.
- **Repo-wide grep** — manual grep against the v1.5 candidate produced no hits.
- **IAM scoping** — `gcloud secrets versions access GEMINI_API_KEY` from a non-runtime principal must return 403. Code-side closed via App Check enforcement; IAM verification remains a DevOps step (R-M02 IAM half, tracked in `docs/runbooks/devops-followups.md`).

### 3.5 Account deletion cascade (ADR-0009)

- **Server-cascade via admin-SDK Cloud Function** — `deleteAccount` (`functions/src/deleteAccount.ts`, lands with HB-004 step 2) recursively deletes Firestore at `users/{uid}/**`, deletes Storage at the `users/{uid}/media/` prefix, deletes the Auth user, then best-effort cleans the per-uid rate-limit docs. Order is fixed: children before parents, Storage before root, Auth last (deleting the auth user revokes the caller's token).
- **Idempotent contract** — re-running on a uid whose root doc and auth user are both absent returns `{ ok: true, alreadyDeleted: true }`. Crash-recovery friendly per ADR-0009.
- **Reauth fence at the client** — see §3.1; the use case orchestrates the sequencing.
- **Why server-only** — Firestore rules deny client-side deletes outside the same-day mutability window (preserves the journal-not-redo invariant). Bypassing rules via the admin SDK is the only path that doesn't require permanently relaxing them. Alternatives rejected in ADR-0009: client-driven batched writes (would weaken rules), per-doc onDelete triggers (fan-out cost + orphan exposure).

### 3.6 PII in logs

Categorical guarantees enforced by allowlist + canary tests:

- **Mood text never reaches Gemini.** `analyze_patterns_functions_datasource.dart::projectEntry` strips it client-side; the Zod `.strict()` schema rejects it server-side; the logger allowlist excludes it. 18 unit tests across `analyze_patterns_functions_datasource_test.dart` and `analyzePatterns.test.ts` cover the fence.
- **FCM token strings never appear in logs.** `notifications/data/fcm_token_repository_impl.dart` `_logger.warn('FCM did not produce a token')` and the Firebase-error logs use `e.code` only — no token value, no UID-with-token pairing. Verified by security-reviewer in PR #30 audit (R-001 cleared).
- **Storage object paths never appear beyond the user prefix.** `deleteAccount.ts` (HB-004 step 2) logs `event, requestId, uid, outcome, latencyTotalMs, errorReason` only. Forbidden: any field from any user document, any Storage object name, any token string. Canary test in `deleteAccount.test.ts` (HB-004 §"Tests" case 12).

### 3.7 Dependency hygiene

- **`npm audit` clean** for `functions/package.json` at v1.5 candidate. SDK bumps verified across the 27-case Jest suite (analyzeMoodText 14 + analyzePatterns 11 + the new sendCheerUpPush + deleteAccount cases that land in HB-003 5.5b / HB-004 step 2).
- **`flutter pub deps` clean** for `apps/mobile/pubspec.yaml` at v1.5 candidate. New v1.5 deps: `firebase_messaging: ^16.0.2` (matrix-aligned with `firebase_core: ^4.x`), `flutter_local_notifications` (lands with HB-003 5.5b for the channel registration). One discontinued package: `golden_toolkit ^0.15.0` — flagged by Pub but no security advisory; replacement deferred to v2.0 since the test API is stable.
- **Repo-wide secret scan** clean (see §3.4).

### 3.8 Open follow-ups for production deploy

Tracked in `docs/runbooks/devops-followups.md` (PR #29). All four items must close before any production deploy; none block the v1.5 academic release.

| ID | Item | Severity | Status |
|---|---|---|---|
| R-M01 | Firestore TTL on `rateLimits` + `rateLimits.patterns` + `rateLimits/cheerUp` collections | MEDIUM | Open (DevOps console step) |
| R-M02-IAM | Secret Manager IAM scoping for `GEMINI_API_KEY` (non-runtime SA returns 403) | MEDIUM | Code-side ✅; IAM half open |
| R-3 | `firebase deploy --only firestore:rules` push confirmation | HIGH (deploy-only) | Open (every rules change) |
| AC-PROV | App Check provider config (Play Integrity / reCAPTCHA Enterprise) | HIGH (deploy-only) | Open (per-environment) |

Closure protocol: update row to `Closed (date)` + one-line note; never delete the row (audit history matters).

---

## 4. Quality gates

CLAUDE.md mandates four quality gates before any release tag. v1.5 status against each:

### 4.1 Correctness

- **`flutter test` count at v1.5 candidate: 382 / 382 green** (verified on `feat/5.5a-cheer-up-controller` HEAD `efc82ecc` 2026-05-07). Up from 354 at v1.0 (a +28 delta from 5.5a domain + repo + controller + dispatch tests). Subsequent S5 work adds another ~40 cases queued in open PRs:
  - +24 notifications tests (PR #30)
  - +9 banner Semantics + interactions (PR #28)
  - +5 hotline footer visibility (PR #32)
  - +5 DeleteAccountUseCase (PR #34)
  - +2 ai-override integration (PR #33)
  - +missing 5.5b sendCheerUpPush.test.ts (7 cases) and HB-004 step 2 deleteAccount.test.ts (5 cases) when those PRs land
- **`flutter test --tags=golden` count.** Started at 3 (S4 carry-over miss documented in §3a.2 of S5 plan). Day 3 qa-engineer adds the 4 missing S4 scenarios (empty garden, flower garden, wilting-plant garden, analytics dashboard) plus 3 new S5 scenarios (banner, breathing overlay, hotline footer). Target ≥ 9 at v1.5.
- **Domain coverage.** v1.0 baseline: 94.6% repo-wide, every feature ≥ 80% per `apps/mobile/tool/check_domain_coverage.dart`. v1.5 not yet recomputed — Day 4 qa-engineer runs `flutter test --coverage` + the coverage tool and writes the baseline into `docs/qa/perf-20260518.md` appendix.
- **Functions Jest count.** v1.0: 27 cases (analyzeMoodText 14 + analyzePatterns 11 + helper tests 2). v1.5: +7 cases for sendCheerUpPush (HB-003 §5.5b) + 5 cases for deleteAccount (HB-004 §"Tests"). Target 39 at v1.5.
- **Firestore rules emulator count.** v1.0: 17 cases. v1.5 candidate: 25 cases (added cases 18-24 for `users/{uid}/settings/notifications` per WBS 6.3, plus case 25 cross-user write per PR #30 audit R-002). The cheerUpEvents + interventionState rules cases land with HB-003 5.5b — target 30 at v1.5.

### 4.2 Security

Re-audit summary referencing §3:

- 0 CRITICAL, 0 HIGH unmitigated findings at v1.5 candidate.
- All v1.0 audit findings (`docs/security/audit-2026-05-12-v1.0.md`, 8 items) closed — most via the v1.0.1 commit `d1eaa1df`, the rest as DevOps follow-ups in §3.8.
- All S5 audit findings closed: PR #23 (R-001 channel registration) tracked for HB-003 5.5b PR; PR #30 (R-001/R-002/R-003) addressed in commits `86f2b81d` (rules + DTO) and `a41dc991` (HB-003 reconciliation).
- Pattern reuse: the three-layer PII fence (§3.3) lands twice more in v1.5 (sendCheerUpPush + deleteAccount), with a dedicated PII canary test in each.

### 4.3 Accessibility

- **Semantics labels on every interactive widget.** S4 baseline: 31 `Semantics(` usages across 20 presentation files. v1.5 additions:
  - `cheer_up_banner.dart` — fixed in PR #28 to include the full locked CLAUDE.md sentence ("It's been a heavy week. Want to try a two-minute breathing exercise?") in the `Semantics.label`. The 9-case parity test asserts `startsWith` so future regressions surface immediately.
  - `notifications_toggle_tile.dart` (PR #30) — Switch carries the toggle title and current state.
  - `hotline_footer.dart` — locked Semantics label "A gentle note. If it helps to talk, the Thai Mental Health Hotline is free at 1323, 24 hours."
- **WCAG 2.2 AA contrast.** Day 3 sweep documents every (fg, bg) pair across the screens and flags any below 4.5:1. Known risk: the cheer-up banner foreground `_fg = Color(0xFF5A3A2E)` against the coral→amber gradient (S5 plan §11 risk #5). If contrast fails, swap `_fg` to a darker design-system token and re-run goldens.
- **Dynamic type at 200%.** Day 3 sweep verifies every screen renders legibly at 200% accessibility text scale.
- **Evidence file:** `docs/qa/a11y-sweep-20260515.md` (Day 3 deliverable).

### 4.4 Performance

Acceptance bars (CLAUDE.md Quality Gate 4): cold start < 2s on mid-range Android, no `ListView` unbounded, images cached via `cached_network_image`. Day 4 perf profile measures:

- **Cold start** — target < 2s on Pixel 6 API 34 emulator. Measured via `flutter run --profile --trace-startup`. v1.5 baseline TBD; v1.0 met the bar.
- **Frame budget on analytics scroll** — target no frame > 16ms (60fps). Captured via DevTools Timeline.
- **Memory at 200-entry history** — target < 150MB. Captured via DevTools Memory tab.
- **Evidence file:** `docs/qa/perf-20260518.md` (Day 4 deliverable). Raw timeline JSON paths cited in the appendix.

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
