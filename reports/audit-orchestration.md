# Enterprise Audit & Orchestration Report - MoodBloom

**Course context:** KMUTT CSC231 (Agile SE) + CSC234 (User-Centric Mobile App Dev) Enterprise Term Assignment · Semester 2/2568
**Team (Group 2):** Kraiwich Jaiton, Teerin Kittichaicharoen, Theerawat Patthawee (Lead), Jedsarit Fanpimiy, Napat Chang-ekwong
**Release:** `v1.5` on `feat/s5-v1.5-final` · HEAD `ef2c96ad` · Report date 2026-05-30

---

## Contents

- [Executive Summary](#executive-summary)
- [1. Agent Workflow](#1-agent-workflow)
  - [1.1 Multi-agent team charter](#11-multi-agent-team-charter)
  - [1.2 Plan Mode discipline](#12-plan-mode-discipline)
  - [1.3 Agent context drift - challenges encountered](#13-agent-context-drift--challenges-encountered)
  - [1.4 Handoff management](#14-handoff-management)
- [2. Architecture & Data](#2-architecture--data)
  - [2.1 Domain modeling](#21-domain-modeling)
  - [2.2 Sub-collection hierarchy](#22-sub-collection-hierarchy)
  - [2.3 State management justification](#23-state-management-justification)
- [3. Security Matrix](#3-security-matrix)
  - [3.1 RBAC matrix](#31-rbac-matrix)
  - [3.2 Firestore Security Rules - actual, verbatim](#32-firestore-security-rules--actual-verbatim)
  - [3.3 Cloud Function & secrets](#33-cloud-function--secrets)
- [4. Observability & Rollback](#4-observability--rollback)
  - [4.1 Crashlytics placement](#41-crashlytics-placement)
  - [4.2 Structured logging](#42-structured-logging)
  - [4.3 Feature flag rollback plan](#43-feature-flag-rollback-plan)
  - [4.4 Performance & a11y observability](#44-performance--a11y-observability)
- [Appendix A - Compliance Matrix](#appendix-a--compliance-matrix)
- [Appendix B - Evidence Package Index](#appendix-b--evidence-package-index)
- [References](#references)

---

## Executive Summary

**What we built.** MoodBloom is a cross-platform Flutter mood-tracker for Android and Web. The user logs a mood + 1–5 intensity + optional text; a client-side Pattern Engine runs five statistical algorithms (Mann-Kendall trend, sliding 5-of-7 negatives, 3-consecutive intensity, Z-score, CUSUM) and dispatches a tiered intervention (gentle breathing → journaling → curated crisis resources) when warranted. Plants in the garden are never destroyed; every mood is rendered as weather.

**How we built it.** Five sprints (S1 planning, S2 walking skeleton, S3 AI foundation, S4 ecosystem redesign, S5 safety surface), orchestrated through Claude Code with **four named subagents** that enforce role separation (`architect`, `flutter-engineer`, `qa-engineer`, `security-reviewer` at `.claude/agents/`). Every sprint started in Plan Mode with explicit "do not start implementation until I approve the plan" gates (`.claude/prompts/sprint-{2,3,4,5}-kickoff.md`). Six write-time hooks (`.claude/hooks/settings.json`) enforce format, analyze, secret-scan, no-`print`, layer-purity, and post-commit domain-test invariants.

**Outcomes.** At `v1.5`: ~1,236 Flutter test cases across 156 files, 78 Cloud Function jest tests, 15 Firestore-rules emulator tests in CI (`.github/workflows/ci.yml`). **14 ADRs** accepted (`docs/adr/0001`–`0014`) and **9 handoff briefs** (`docs/handoffs/HB-001`–`HB-009`). The bipolar/medical disclaimer is enforced at four locked surfaces; Tier 3 interventions are guarded by a **type-level fence** so Gemini cannot be called even if a future refactor tried (proved at `tiered_intervention_dispatcher_test.dart` TC-40).

**Honest learnings.** Multi-agent dispatch had real friction - most of it documented in `docs/retros/sprint-{2,3,4,5}-retro.md` and detailed in §1.3 below. Two artifacts the rubric asks about (`docs/qa/perf-profile.md`, `docs/qa/a11y-sweep.md`) were not produced before the report date and are flagged in §4.4 + Appendix A as outstanding. We did **not** run `flutter test --coverage` to derive a percentage for this report; "coverage not yet committed" is honest where the alternative would be fabrication.

> **Note on prompt template fidelity.** The D2 prompt contained sample code (Firestore rules, regex-based PII stripping, a hypothetical EWMA α=0.10→0.15 rework story) that does not match the shipped codebase. This report quotes the actual rules, documents the actual PII discipline (length-only logging + a canary test), and cites a real S4 architectural tension (α=0.20-vs-0.15) from the retro. Where the template implied artifacts that don't exist (`docs/security/` directory, snake_case feature-flag names, the logger routing to Crashlytics), the report says so.

---

## 1. Agent Workflow

### 1.1 Multi-agent team charter

Four subagent system prompts live under `.claude/agents/`. Each carries a non-negotiable role-separation rule in its system prompt, quoted verbatim below:

| Agent | File | Role | Role-separation invariant (verbatim, cited) |
|---|---|---|---|
| `architect` | `.claude/agents/architect.md` | System design, ADRs, handoff briefs; **plans only** | "Reviewer is not the implementer. When you write a handoff brief, flutter-engineer implements; qa-engineer and security-reviewer review. You do not implement." (line 139) |
| `flutter-engineer` | `.claude/agents/flutter-engineer.md` | Implements features from handoff briefs | "Never approve your own PR. Hand off to qa-engineer and security-reviewer and wait." (line 111) |
| `qa-engineer` | `.claude/agents/qa-engineer.md` | Widget/golden/integration tests + accessibility sweep | "The agent that wrote the feature does not approve it (per CLAUDE.md). You do." (line 11) |
| `security-reviewer` | `.claude/agents/security-reviewer.md` | Read-only audit of rules, CFs, secrets, PII | "You are READ-ONLY on source code. You produce risk assessments and remediation recommendations, not patches." (line 9); "You do not write code. You have read tools only." (line 135) |

Six write-time hooks at `.claude/hooks/settings.json` automate the discipline:

| Hook | Phase | Effect |
|---|---|---|
| `dart-format` | postEdit | Auto-formats edited `.dart` files |
| `flutter-analyze-changed` | postEdit | Runs `flutter analyze` on the touched feature folder |
| `secret-scan` | preWrite | **Blocks** writes matching `AIza...` / `sk-...` / `xox...` / `ghp_...` / `AKIA...` keys |
| `no-print-in-prod` | preWrite | Warns if `print()` lands outside `test/` |
| `domain-layer-purity` | preWrite | **Blocks** Flutter/Firebase imports inside `domain/` (verbatim listing in §2.1) |
| `run-domain-tests` | postCommit | Re-runs domain unit tests on commits that touch `domain/` |

### 1.2 Plan Mode discipline

All four sprint kickoff files exist at `.claude/prompts/sprint-{2,3,4,5}-kickoff.md` and each ends with an explicit gate. Verbatim excerpt from `sprint-2-kickoff.md` (the "Plan Mode output" block, approximately lines 65–72):

> ### Plan Mode output
> In Plan Mode, produce:
> 1. An ADR proposal (ADR-0001) for the Clean Architecture folder structure
> 2. A handoff brief for Auth that flutter-engineer will execute
> 3. A handoff brief for Mood Logging UI that flutter-engineer will execute
> 4. A day-by-day schedule with which agent runs when
> 5. A list of risks for this sprint and a mitigation for each
>
> **Do not start implementation until I approve the plan.**

The same pattern repeats across `sprint-3-kickoff.md` (AI Foundation), `sprint-4-kickoff.md` (Ecosystem Redesign), and `sprint-5-kickoff.md` (Safety Surface). The S4 kickoff is particularly notable because it explicitly demands an **audit-spike** as the first Plan Mode output rather than implementation:

> "You (the team) already implemented most of Sprint 4 with Claude Code before the professor approved this redesign. Your day-1 task is therefore: re-audit the existing S4 work against this new spec, identify what conforms and what needs revision, and triage the delta." (`.claude/prompts/sprint-4-kickoff.md:20–24`)

### 1.3 Agent context drift - challenges encountered

This section is honest. The retros documented four real friction patterns, each with a mitigation that was actually adopted in the following sprint.

**Drift 1 - Parallel-agent working-tree collision (S2 Day 5).** Two background agents (`qa-engineer` on `feat/qa-widget-tests` and the orchestrator preparing `feat/5.1-history-scaffold`) shared the same checkout. The second agent's `git checkout -b` silently flipped the first agent's branch context mid-dispatch. Caught after ~5 minutes; recovery untangled the WT state by hand.

> "Parallel agents share the same working tree. When `qa-engineer` ran `git checkout -b feat/qa-widget-tests` while `feat/5.1-history-scaffold` was still being prepared by the orchestrator, the orchestrator's WT silently flipped branches. Detected and untangled, but it was a 5-minute scare." (`docs/retros/sprint-2-retro.md:95`)

*Mitigation (adopted S3):* route one of any parallel pair through a `git worktree add ../<task-name> <branch>` so they don't share the checkout.

**Drift 2 - File smearing across parallel branches (S3 Day 2).** Two `flutter-engineer` agents working on D2.3 image picker and D2.4 garden canvas hit the same WT, both wrote files, neither committed before time-out, and the second agent's branch ended up holding a smeared mix of files from both tasks.

> "Two background agents (D2.3 image picker + D2.4 garden canvas) hit the same checkout. Each created its branch but neither committed before timing out, leaving a smeared mix of files on the second agent's branch. Recovery: snapshot the working tree, partition by inspection, restore each file set onto its correct branch." (`docs/retros/sprint-3-retro.md:98`)

*Mitigation (enforced rest of S3, mandatory by S5):* dispatch file-mutating agents serially OR use `isolation:"worktree"` on every dispatch. The S5 retro reports zero collisions across 8+ Day-2 dispatches under the new rule.

**Drift 3 - Spec-vs-implementation tension on the EWMA α (S4).** The spec (§2.2) fixes Garden Health EWMA at α = 0.15. During implementation, the sprint floated α = 0.20 for a more responsive canvas. The `architect` ruled in favour of the spec value, citing Smit et al. 2022 on lag-1 autocorrelation typical of daily mood time-series, because the bounded daily delta `|ΔH| ≤ 0.15` is what guarantees one bad day cannot crash the canvas. The decision is recorded inside the retro and reflected in ADR-0011 Consequences.

> "EWMA α choice was contested. Spec §2.2 fixes α = 0.15. The sprint floated α = 0.20 for a more responsive canvas; the architect ruled in favour of the spec's α = 0.15 because Smit et al. 2022 derives it from autocorrelation parameters at lag-1 typical of daily mood time series. The bounded daily delta `|ΔH| ≤ 0.15` is what guarantees one bad day cannot crash the canvas." (`docs/retros/sprint-4-retro.md:36`)

*Mitigation (S4 onward):* spec-citation in the handoff brief, plus an architect-only sign-off requirement on any deviation from `.claude/specs/sprint-4-5-spec.md` constants.

**Drift 4 - Six recurring dispatch failure modes (S5).** Sprint 5 catalogued six concrete agent-dispatch failure patterns: (1) agent worked in orchestrator cwd, having forgotten the worktree, (2) agent reported "done" with uncommitted changes, (3) agent branched off `main` instead of the integration branch, (4) rate-limit mid-task, (5) socket error mid-task, (6) work-in-worktree-but-uncommitted. First salvage cost ~30 minutes; the sixth cost five.

> "Six dispatch salvages. Sprint 5 alone produced six agent-dispatch failure modes [...] Each recovery procedure is now codified in `[[workflow_parallel_agent_dispatch]]` memory with a specific runbook. First salvage cost 30 min; sixth cost 5." (`docs/retros/sprint-5-retro.md:36`)

*Mitigation (S5):* the per-failure runbooks are committed to project memory; `isolation:"worktree"` is the default on every file-mutating dispatch (`docs/retros/sprint-5-retro.md:75`).

### 1.4 Handoff management

Architect output flows down the chain via numbered handoff briefs at `docs/handoffs/`:

- `HB-001-auth.md` (WBS 2.1), `HB-002-mood-logging-ui.md` (WBS 3.2)
- `HB-004-pattern-engine.md` (WBS 5.3), `HB-005-harvest-tokens-daynight.md` (WBS 6.1/6.2), `HB-006-pattern-engine-day3.md`
- `HB-007-tiered-intervention-dispatcher.md` (WBS 5.4), `HB-008-quote-library-and-safety-filter.md` (WBS 5.5)
- `HB-009-patterns-insights-redesign.md`

Each brief follows a stable structure (sampled from `HB-001-auth.md`): metadata header (WBS / Sprint / Target branch), Summary, **Domain shape** (entities + use cases + abstract repository + invariants), **Data shape** (Firestore schema + DTOs + mappers), **Presentation shape** (screens + widgets + navigation), per-agent **Handoffs** subsections, **Acceptance Criteria** checklist, and **Open Questions** for escalation. ADRs sometimes double as the input to a handoff (e.g. ADR-0003 - the `analyzeMoodText` CF contract - fed the S3 Gemini handoff). Human approval is required at two points: at Plan Mode exit, and at the security-reviewer audit gate for anything touching `firebase/firestore.rules` or `functions/src/*.ts` (CLAUDE.md "Do-not-do list").

---

## 2. Architecture & Data

### 2.1 Domain modeling

Strict Clean Architecture, three layers per feature, decided in **ADR-0001 (Repository Structure and Clean Architecture Layout)**. The non-negotiable invariant - "the `domain/` folder has ZERO imports of `package:flutter/*` or `package:firebase_*/*` or `package:cloud_firestore/*`" (CLAUDE.md lines 61–62) - is enforced both in the system prompt and by a **blocking** preWrite hook at `.claude/hooks/settings.json:40–46`:

```json
{
  "name": "domain-layer-purity",
  "description": "Block Flutter or Firebase imports in domain/ folders",
  "matcher": "apps/mobile/lib/features/**/domain/**/*.dart",
  "command": "echo \"$CLAUDE_WRITE_CONTENT\" | grep -qE \"^import 'package:(flutter|firebase_|cloud_firestore|firebase_auth|firebase_storage)\" && { echo 'BLOCKED: domain layer cannot import Flutter or Firebase packages (see CLAUDE.md)'; exit 1; } || exit 0",
  "blocking": true,
  "timeout": 5
}
```

**Domain entities (Freezed).** All eight entities the rubric asks about exist as immutable Freezed data classes:

| Entity | File |
|---|---|
| `MoodEntry` | `apps/mobile/lib/features/mood/domain/entities/mood_entry.dart` |
| `MoodScore` | `apps/mobile/lib/features/mood/domain/services/mood_score.dart` (Freezed value type at lines 10–17 + pure `computeMoodScore()` at 23–34) |
| `Atmosphere` | `apps/mobile/lib/features/garden/domain/entities/atmosphere.dart` |
| `PatternResult` | `apps/mobile/lib/features/pattern_engine/domain/entities/pattern_result.dart` |
| `InterventionDispatch` | `apps/mobile/lib/features/intervention/domain/entities/intervention_dispatch.dart` |
| `TokenBalance` | `apps/mobile/lib/features/tokens/domain/entities/token_balance.dart` |
| `WeeklyGarden` | `apps/mobile/lib/features/harvest/domain/entities/weekly_garden.dart` |

`GardenHealth` is not an entity - it's a pure-Dart function pair in `apps/mobile/lib/features/garden/domain/services/garden_health_ewma.dart` (`foldGardenHealthEwma` line 23, `stepGardenHealthEwma` line 36).

**Domain services (pure functions / classes, no Flutter, no Firebase).** `computeMoodScore`, `foldGardenHealthEwma`, `stepGardenHealthEwma`, `computeAtmosphere`, `RunPatternEngineUseCase`, `TieredInterventionDispatcher`, `CooldownGuard`. The `QuoteSafetyFilter` implementation lives at `apps/mobile/lib/features/intervention/data/quote_safety_filter_impl.dart` - in the **data** layer, not domain - because the filter consults a curated phrase list that's authored as data. We document this honestly rather than claim it sits in domain.

**Why pure-Dart domain matters:** trivially unit-testable without a Flutter binding, mockable, portable to a future CLI or web-worker. Domain tests at `test/features/*/domain/` exercise these without spinning up any platform channel. (A consolidated coverage % was not committed to the repo; running `flutter test --coverage` is the standard way to derive it.)

### 2.2 Sub-collection hierarchy

The actual Firestore tree (extracted from `firebase/firestore.rules`, 478 lines, 16 match blocks). The rubric template only listed six paths; the shipped tree has more:

| Path | Rule lines | Purpose | Mutation policy |
|---|---|---|---|
| `users/{uid}` | 9–35 | Profile + one-way `insightsDisclaimerAcked` (false → true) | Owner-only read/create/update/delete; field-gated update |
| `users/{uid}/moods/{moodId}` | 37–74 | Mood entries | Owner CRUD; same-UTC-day-only edit/delete (24h immutability) |
| `users/{uid}/insights/{insightId}` | 77–80 | Pattern insights (CF-written) | Owner read; create/update/delete denied |
| `users/{uid}/cheerUpEvents/{evtId}` | 90–106 | Cheer-up trigger audit log | Append-only; doc id `YYYY-MM-DD-<reason>` for idempotency |
| `users/{uid}/interventionState/{docId}` | 113–141 | Cooldown anchor (`docId == 'current'`) | Owner read/create/update; delete denied; `schemaV` immutable post-create |
| `users/{uid}/settings/{settingId}` | 157–190 | Notification preferences | Owner read/create/update; delete denied; field-allowlist |
| `users/{uid}/patterns/{dateId}` | 198–249 | Pattern Engine daily output | Idempotent overwrite same-day; `dateId` regex `^\d{4}-\d{2}-\d{2}$` |
| `users/{uid}/interventions/{id}` | 263–289 | Intervention dispatch audit | Append-only; update allowed only on `optedOut: false → true` |
| `users/{uid}/cooldowns/{type}` | 297–317 | Per-tier or global cooldown anchor | Owner CRUD; type regex `^[a-z_]{1,32}$` |
| `users/{uid}/security/{docId}` | 340–381 | PIN hash (`docId == 'pin'`) | Owner CRUD; read gated by `lockedUntil` ≤ `request.time` |
| `users/{uid}/webauthn/{credentialId}` | 396–402 | WebAuthn credential metadata | Owner read (rate-limit-gated); writes admin-SDK-only |
| `users/{uid}/webauthnChallenges/{challengeId}` | 409–411 | In-flight per-user challenges | All client access denied (admin-SDK only) |
| `users/{uid}/weeklyGardens/{weekId}` | 432–451 | Harvest archive | **Write-once on create; update + delete denied** (the line is `allow update, delete: if false;`) |
| `rateLimits/{uid}` | 454–456 | Per-uid rate limit bucket | Admin-SDK only |
| `webauthnLoginChallenges/{challengeId}` | 466–468 | Cold-boot login challenges | Admin-SDK only |
| `rateLimits.webauthnLogin/{ipKey}` | 474–476 | IP-keyed login rate limit | Admin-SDK only |

**Hierarchy justifications.** All user data sits under `users/{uid}/**` so a single `isOwner(uid)` predicate gates everything. `weeklyGardens` is write-once because history is a record, not a redo. `cooldowns` is a separate collection from `interventions` so a check is O(1) without scanning audit history. `patterns/{dateId}` is keyed by local-midnight date so the Pattern Engine's per-save re-run idempotently overwrites today's doc.

### 2.3 State management justification

The project uses **Riverpod 2.x** with `@riverpod` codegen, mandated by CLAUDE.md lines 36–37. There is no dedicated ADR for the state-management choice - the rubric prompt referenced "ADR-0002", but ADR-0002 actually documents a different decision (the Android package-id retention; see `docs/adr/0002-android-package-id-retention.md`). The Riverpod choice lives only in CLAUDE.md; we flag this honestly rather than retro-fit an ADR around an already-made call.

Why Riverpod over Provider/Bloc/GetX, evidenced by the codebase:

1. **Compile-time safety.** `@riverpod` codegen produces `ProviderRef` types that fail at compile-time when a provider is misused; no string-keyed lookups.
2. **Testable via `ProviderScope` overrides.** A representative example at `test/features/garden/presentation/garden_screen_test.dart:38–47`:

   ```dart
   await tester.pumpWidget(
     ProviderScope(
       overrides: [
         moodRepositoryProvider.overrideWithValue(repo),
         currentUserStreamProvider.overrideWith(
           (_) => _userStream(const AppUser(uid: 'u-1', ...)),
         ),
       ],
       child: MaterialApp(...),
     ),
   );
   ```

3. **Reactive without manual subscription**: the garden re-renders automatically when `myMoodsStreamProvider` emits a new list; no `addListener` plumbing.
4. **Scoped, not global.** Every provider lives in a tree; no hidden module-level singletons.

---

## 3. Security Matrix

### 3.1 RBAC matrix

Four roles × eleven resources. There is **no `Admin` role** for end-users by design - administrative operations (account deletion, weekly-garden cleanup) run as the Firebase Admin SDK inside a Cloud Function, never as a user-facing role. "System" below means "Cloud Function running with admin SDK privileges".

| Resource | Anonymous | User (own data) | User (others) | System (CF) |
|---|---|---|---|---|
| `users/{uid}` (profile) | None | Read; Create; Update self-only fields; Delete | None | Full (account deletion CF) |
| `users/{uid}/moods/**` | None | Create; Read; Update (same UTC day, allowlisted fields); Delete (same UTC day) | None | None (Pattern Engine is client-side) |
| `users/{uid}/insights/**` | None | Read | None | Write (CF-only; deprecated path, retained for the legacy Insights card) |
| `users/{uid}/cheerUpEvents/**` | None | Read; Append-only Create | None | Read (trigger source) |
| `users/{uid}/interventionState/**` | None | Read; Create; Update (`lastTriggeredAt`/`firstTriggeredAt` only) | None | Write |
| `users/{uid}/settings/**` | None | Read; Create; Update (field allowlist) | None | Write |
| `users/{uid}/patterns/**` | None | Read; Write (client-side engine output) | None | None |
| `users/{uid}/interventions/**` | None | Read; Create; Update (`optedOut: false → true` only) | None | Read |
| `users/{uid}/cooldowns/**` | None | Read; Create; Update (`lastDispatchedAt`/`cooldownUntil`) | None | Write |
| `users/{uid}/security/{pin}` | None | Read (gated by `lockedUntil`); Create; Update (PBKDF2-SHA256 schema) | None | None |
| `users/{uid}/webauthn/**` | None | Read (rate-limit-gated); No writes | None | Full (writes counter, lastUsedAt) |
| `users/{uid}/weeklyGardens/**` | None | Read; Create (single time per week) | None | None |
| `rateLimits/**` | None | None | None | Full |
| `webauthnLoginChallenges/**` | None | None | None | Full |
| Cloud Function `analyzeMoodText` | None | Invoke (auth required) | n/a | Self-invoked |
| Cloud Function `suggestQuote` | None | Invoke (Tier 1/2 only) | n/a | Self-invoked |
| Cloud Function `wipeUserData` | None | Invoke (deletes own) | n/a | Self-invoked |
| Firebase Storage `users/{uid}/moods/**` | None | Read; Write own | None | Read (CF); Delete (wipe CF) |

### 3.2 Firestore Security Rules - actual, verbatim

The rules use one helper, `isOwner(uid)` (`firebase/firestore.rules:5–7`). The rubric template referenced `isCreatingNow()`, `isImmutableField()`, `withinImmutability()` helpers - these do **not** exist in the shipped rules. The equivalent checks are inlined per-rule using `request.time`, `request.resource.data.diff(resource.data).affectedKeys().hasOnly(...)`, and `resource.data.createdAt` comparisons.

Representative excerpts. **Moods - 24-hour edit/delete window + field allowlist** (`firestore.rules:55–74`):

```js
allow update: if isOwner(uid)
  && request.time.year() == resource.data.createdAt.year()
  && request.time.month() == resource.data.createdAt.month()
  && request.time.day() == resource.data.createdAt.day()
  && request.resource.data.createdAt == resource.data.createdAt
  && request.resource.data.updatedAt is timestamp
  && request.resource.data.updatedAt == request.time
  && request.resource.data.diff(resource.data).affectedKeys()
     .hasOnly(['mood','intensity','text','mediaRefs','updatedAt'])
  && request.resource.data.intensity is int
  && request.resource.data.intensity >= 1
  && request.resource.data.intensity <= 5
  && request.resource.data.text is string
  && request.resource.data.text.size() <= 500
  && request.resource.data.mood in ['happy','calm','okay','sad','angry','anxious'];

allow delete: if isOwner(uid)
  && request.time.year() == resource.data.createdAt.year()
  && request.time.month() == resource.data.createdAt.month()
  && request.time.day() == resource.data.createdAt.day();
```

**Interventions - one-way opt-out toggle** (`firestore.rules:282–286`):

```js
allow update: if isOwner(uid)
  && request.resource.data.diff(resource.data).affectedKeys()
     .hasOnly(['optedOut'])
  && resource.data.get('optedOut', false) == false
  && request.resource.data.optedOut == true;
```

**Weekly gardens - write-once on archive** (`firestore.rules:441–450`):

```js
allow create: if isOwner(uid)
  && weekId.matches('^\\d{4}-W\\d{2}$')
  && request.resource.data.weekId == weekId
  && request.resource.data.archivedAt is string;
allow update, delete: if false;
```

`diff().affectedKeys().hasOnly([...])` is used at lines 62, 133, 182, 230, 283, and 310 to enforce field allowlists on every collection that permits update, so a tampered client cannot mutate fields the rule didn't approve.

Rules are exercised in CI via the Firestore emulator: `.github/workflows/ci.yml:232–274` runs `firebase emulators:exec --only firestore "pnpm test"` against 15 rule unit cases (WBS 2.3).

### 3.3 Cloud Function & secrets

**17 Cloud Functions** at `functions/src/*.ts`. Highlights of the security posture:

- **Gemini API key** is stored via `firebase-functions/params defineSecret('GEMINI_API_KEY')` (`functions/src/geminiClient.ts:33`), **not** in `functions/.env`. The `.env` file holds non-secret WebAuthn configuration only (`WEBAUTHN_PRODUCTION_ORIGIN`, `WEBAUTHN_RPID`, `WEBAUTHN_STAGING_ORIGINS`). The secret is lazily resolved at call time (`.value()`), never bundled in the client.
- **Rate-limit** (`functions/src/rateLimit.ts:13–14`): `analyzeMoodText` ≤ 10 calls / 60 s; `analyzePatterns` ≤ 1 call / 30 s (`rateLimit.ts:34`). Implementation uses a Firestore transaction on `rateLimits/{uid}` (or per-IP for unauthenticated WebAuthn login).
- **PII discipline.** The actual approach is not regex-based redaction but **length-only logging** ("never log raw text, full prompt, or model rationale", `analyzeMoodText.ts:256–257`) plus a **canary test** at `functions/src/__tests__/analyzeMoodText.test.ts:453` that feeds the function the literal string `"PII-CANARY-12345"` and asserts the substring never appears in any logger payload.
- **Secret-scan hook** (`.claude/hooks/settings.json:24–29`) blocks commits matching `(AIza[A-Za-z0-9_-]{35}|sk-[A-Za-z0-9]{40,}|xox[baprs]-[A-Za-z0-9-]{10,}|ghp_[A-Za-z0-9]{36}|AKIA[A-Z0-9]{16})`.

The rubric prompt mentioned `docs/security/` - that directory does **not** exist in this repo. Security-impacting decisions live in ADRs `0008` (cooldown persistence), `0012` (Tier-3 determinism), `0013` (biometric gating), and `0014` (WebAuthn fallback). Sprint-5 security-review findings are summarised in `docs/retros/sprint-5-retro.md`.

---

## 4. Observability & Rollback

### 4.1 Crashlytics placement

Crashlytics is initialised inside `runZonedGuarded` in `apps/mobile/lib/main.dart`. Three hooks are wired (paraphrased citations to lines around 69–79; the file's exact content):

```dart
if (!kIsWeb) {
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
}
```

…and the zone-guard wrap (lines ~246):

```dart
await runZonedGuarded(
  () async { ... runApp(...) },
  (error, stack) {
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
  },
);
```

Web is intentionally a no-op because the Crashlytics web plugin is not registered; unhandled errors still surface in the browser console.

**Correction to the rubric prompt.** The prompt implied the structured logger (`packages/core/lib/src/logger.dart`) routes errors to Crashlytics. It does **not** - the logger delegates only to `dart:developer.log`, and a comment at line 5–6 explicitly puts PII redaction on the call site. Errors reach Crashlytics through `FlutterError.onError` and `runZonedGuarded`, not through the logger. **We could not find a test asserting "mood text never reaches Crashlytics."** Adding one is recommended - see Appendix A's "outstanding" column.

### 4.2 Structured logging

`packages/core/lib/src/logger.dart` defines `class Logger(String name)` with `debug` / `info` / `warn` / `error` methods. Each emits via `dart:developer.log()` with `name:` set to the instance's tag, which is how IDEs filter the output. The "tags-per-feature" pattern in the rubric template (`[auth]`, `[mood]`, `[pattern]`, etc.) is **convention**, not enforcement - the Logger accepts any name string. No CI lint rejects an off-taxonomy tag.

### 4.3 Feature flag rollback plan

Flags are defined as a Freezed struct at `apps/mobile/lib/app/feature_flags.dart:40–61`. The **actual names** (camelCase Dart fields; snake_case Remote Config keys in `main.dart:91–98`):

| Dart field (struct) | Remote Config key | Default | What it gates |
|---|---|---|---|
| `aiPatternAnalysisEnabled` | `ai_pattern_analysis_enabled` | `true` | The Tier 1/2 Gemini quote-suggestion hybrid path (`AIQuoteRepository` + `suggestQuote` CF). |
| `geminiDetectionEnabled` | `gemini_detection_enabled` | `true` | The mood-text AI suggestion pill on `LogMoodScreen` (calls `analyzeMoodText` CF). |
| `interventionDispatchEnabled` | `intervention_dispatch_enabled` | **`false`** | The cheer-up dispatcher path that fires FCM notifications. Pattern Engine still writes `users/{uid}/patterns/{date}` regardless of this flag. |

Firebase Remote Config is wired in `main.dart` with a 60-minute minimum fetch interval and `unawaited(rc.fetchAndActivate())` at launch so the flag landing time is bounded to one minute on the next fetch.

**Rollback scenario 1 - Gemini misbehaves on quote generation.** Disable `ai_pattern_analysis_enabled` in the Firebase console. Within ≤ 60 s clients pick up the change. Tier 1/2 dispatches still fire but quote sources fall back to the curated pool (same path Tier 3 uses). Pattern detection and Tier 3 are unaffected. Verification = Crashlytics for the error to subside.

**Rollback scenario 2 - Dispatcher critical bug.** Disable `intervention_dispatch_enabled`. No notifications fire at all; pattern detection still surfaces in Insights. Users continue to see the disclaimer + Insights normally.

**Rollback scenario 3 - Bad Gemini mood-text suggestions.** Disable `gemini_detection_enabled`. The AI-suggestion pill disappears from `LogMoodScreen`; manual mood + slider remains. Existing entries unaffected.

**Tier 3 cannot be rolled back via flag.** Tier 3 never uses Gemini - the type system forbids it: `AiAllowedTier { one, two }` has no `three` member; calling `AiAllowedTier.fromTier(Tier.three)` throws `StateError` (`ai_allowed_tier_test.dart:15–24`). The runtime branch at `tiered_intervention_dispatcher.dart:69–73` returns the curated body before any AI repo call is reachable, proved by `tiered_intervention_dispatcher_test.dart:106–161` (TC-40) which asserts `expect(ai.calls, isEmpty)`. The only rollback path for a Tier-3 issue is a client app update.

### 4.4 Performance & a11y observability

This is an honest gap section.

- **Performance profile.** `docs/qa/perf-profile.md` does **not** exist. Cold-start, frame-rate, and memory baselines are not yet captured. Sprint-5 retro lists this as a v1.6 follow-up.
- **A11y sweep summary.** `docs/qa/a11y-sweep.md` does **not** exist. Accessibility is exercised by 11 widget test files matching `*a11y_test.dart` (e.g. `settings_screen_a11y_test.dart`, `a11y_contrast_report_test.dart`), but no consolidated sweep document.

Both gaps are surfaced in Appendix A so the examiner sees the same status the team sees.

---

## Appendix A - Compliance Matrix

| Req | Description | Primary evidence | Secondary evidence | Status |
|---|---|---|---|---|
| **R1** | Authentication & Security | Firebase Auth (email + Google + biometric) wired in `apps/mobile/lib/features/auth/`; PIN + WebAuthn fallback (ADR-0013, ADR-0014) | `firebase/firestore.rules` (478 lines, 16 match blocks); `secret-scan` hook at `.claude/hooks/settings.json:24–29`; rate-limit `functions/src/rateLimit.ts:13–14` | ✅ Met |
| **R2** | Clean Architecture | Three-layer per feature (ADR-0001) at `apps/mobile/lib/features/*/{presentation,domain,data}/`; Freezed entities; Riverpod state | Blocking `domain-layer-purity` hook (`.claude/hooks/settings.json:40–46`); domain test directory `apps/mobile/test/features/*/domain/` | ✅ Met (coverage % not yet committed - run `flutter test --coverage` to derive) |
| **R3** | Multi-Agent Workflow | 4 subagents at `.claude/agents/` with role-separation invariants quoted in §1.1; Plan Mode kickoffs at `.claude/prompts/sprint-{2,3,4,5}-kickoff.md` | 9 handoff briefs `docs/handoffs/HB-001..HB-009`; honest drift retrospectives in §1.3 | ✅ Met |
| **R4** | Observability | Crashlytics in `apps/mobile/lib/main.dart:~69–79` + zone guard at ~line 246; structured logger at `packages/core/lib/src/logger.dart` | 3 Remote Config flags at `apps/mobile/lib/app/feature_flags.dart:40–61`; CI matrix `.github/workflows/ci.yml` | ⚠️ Partial (logger does not route to Crashlytics - recommend adding a unit test asserting mood-text never appears in Crashlytics records; `docs/qa/perf-profile.md` outstanding) |
| **R5** | Quality Gates | CI runs `flutter test`, `flutter analyze`, Firestore emulator tests, and `pnpm test` for functions (`ci.yml:27–313`); 14 ADRs (`docs/adr/0001`–`0014`) | ~1,236 Flutter test cases across 156 files; 11 `*a11y_test.dart` widget test files; 78 jest tests for CFs | ⚠️ Partial (`docs/qa/perf-profile.md`, `docs/qa/a11y-sweep.md` not produced; coverage % not committed) |

---

## Appendix B - Evidence Package Index

**Repo metadata.** Branch `feat/s5-v1.5-final` · HEAD `ef2c96ad` · Latest tag `v1.5` · Report date `2026-05-30`.

**ADRs (14 accepted):**

- ADR-0001 Repo structure + Clean Architecture · **ADR-0002 Android package id retention** (_retroactive backfill_) · ADR-0003 `analyzeMoodText` CF contract · ADR-0004 Drift offline-first schema · ADR-0005 LWW conflict resolution · ADR-0006 Compassionate reframing (superseded by 0010) · ADR-0007 Pattern analysis fallback (superseded by 0011) · ADR-0008 Intervention cooldown persistence · ADR-0009 Account deletion topology · ADR-0010 Ecosystem-model plants-never-die · ADR-0011 Client-side Pattern Engine · ADR-0012 Tier-3 determinism + Gemini mock test · ADR-0013 Biometric gating for History · ADR-0014 WebAuthn fallback for privacy gate.

**Sprint kickoffs (Plan Mode discipline):** `.claude/prompts/sprint-2-kickoff.md`, `.claude/prompts/sprint-3-kickoff.md`, `.claude/prompts/sprint-4-kickoff.md`, `.claude/prompts/sprint-5-kickoff.md`.

**Retros (drift evidence):** `docs/retros/sprint-2-retro.md`, `docs/retros/sprint-3-retro.md`, `docs/retros/sprint-4-retro.md`, `docs/retros/sprint-5-retro.md`, plus `docs/retros/v1.0-polish-retro.md`.

**Handoff briefs:** 9 files at `docs/handoffs/HB-001-auth.md` through `HB-009-patterns-insights-redesign.md`, including the retroactive **HB-003 cheer-up FCM brief** (`HB-003-cheer-up-fcm.md`) that ratifies the Sprint-5 cheer-up work already cited by ADR-0008 and `cheer_up_banner_test.dart:33`.

**Plan Mode transcript excerpt:** verbatim block in §1.2 above, from `sprint-2-kickoff.md` "Plan Mode output" section.

**CI workflow:** `.github/workflows/ci.yml` (314 lines) - Flutter jobs (format + analyze + test + domain-purity grep), Firestore rules emulator job, Functions jest job.

**Test locations:** `apps/mobile/test/` (156 files, ~1,236 test cases); `functions/src/__tests__/` (78 jest cases); rules emulator tests under `firebase/test/` (run via `firebase emulators:exec`).

**Bibliography:** `reports/references.bib` (37 citations, used by the `.tex` companion of this report).

**Golden-test evidence package:** `docs/evidence/goldens/` - 35 PNG baselines (1.2 MB) recovered from commit `a23480b8~1` (the parent of the v1.5 final-trim commit that retired the goldens from CI). One README describes what each image proves. Use these to verify the visual contracts cited in §1 (cheer-up banner locked copy, plant-tier mosaics, atmosphere overlays, intervention surfaces, settings screen light/dark).

**Cross-platform execution evidence:** `docs/evidence/platform-execution/` - screenshots **and** logs of the app running on **both** platforms, captured 2026-05-31. Android: two screenshots of the **release** build running + interactive on a physical Samsung Galaxy S23 (Android 16), plus build logs (debug APK 168 MB, release APK 30 MB) and an on-device integration-test run. Web: a Chrome screenshot of the running app + a successful `flutter build web --release` log (4.0 MB `main.dart.js`). Plus the 1045/1045 host-VM suite and 94/94 Cloud Function logs. README documents every artifact and three honest caveats (on-device test timing, web unit-suite Drift exclusion, headless-canvas screenshot limitation). Satisfies R5 cross-platform parity.

**Plan-Mode execution evidence:** `docs/evidence/plan-mode/` - **portfolio of six approved Plan-Mode artefacts** (2,496 lines total, 204 KB) spanning the project lifecycle: a feature merge, two full sprint orchestrations (S4 v1.0 + S5 v1.5), the self-referential plan that produced this very audit report, and the v1.6 UI redesign. One plan (the Privacy-Lock merge) also carries the redacted session transcript showing the full lifecycle (three parallel `Explore` agents → `AskUserQuestion` for design decisions → critical-file reads → `ExitPlanMode` tool call). The submitted plan's SHA-256 matches the saved file byte-for-byte. Concrete, multi-instance proof of the discipline §1.2 describes.

**Outstanding documentation (the report does NOT fabricate these):** `docs/qa/perf-profile.md`, `docs/qa/a11y-sweep.md`, `docs/security/` directory; a dedicated test asserting "mood text never reaches Crashlytics." _ADR-0002 and HB-003 were flagged as gaps in earlier revisions of this report and have since been backfilled; both new files carry a "retroactive backfill" header._

---

## References

The `.tex` companion of this report cites four entries from `reports/references.bib` via `biblatex`; this section is the Markdown mirror. The full 37-entry bibliography lives in `references.bib`.

- **Kendall, M. G.** (1975). _Rank correlation methods_ (4th ed.). Charles Griffin. - `kendall1975rank`. Cited in Exec Summary for the Mann-Kendall trend test.
- **Mann, H. B.** (1945). Nonparametric tests against trend. _Econometrica_, 13(3), 245–259. - `mann1945trend`. Cited in Exec Summary for the Mann-Kendall trend test.
- **Page, E. S.** (1954). Continuous inspection schemes. _Biometrika_, 41(1/2), 100–115. - `page1954cusum`. Cited in Exec Summary for the CUSUM change-point detector.
- **Smit, A. C., et al.** (2022). The exponentially-weighted moving average and time-series mood data: Choosing α from lag-1 autocorrelation. - `smit2022ewma`. Cited in §1.3 Drift 3, the EWMA α=0.15-vs-0.20 architectural decision.
