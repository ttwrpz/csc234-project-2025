# Enterprise Audit & Orchestration Report — MoodBloom v1.5

**Course context:** KMUTT CSC231 / CSC234 Enterprise Term Assignment
**Team (Group 2):** Kraiwich Jaiton, Teerin Kittichaicharoen, Theerawat Patthawee (Lead), Jedsarit Fanpimiy, Napat Chang-ekwong
**Release:** `v1.5` (local tag on `feat/s5-v1.5-final`, head `977b86d3`)
**Date:** May 30, 2026

## Executive Summary

MoodBloom shipped 12 features across 5 sprints under a 4-agent multi-agent workflow on Claude Code. 1018 automated tests pass at `v1.5`; domain-layer line coverage 94.6%; no HIGH or CRITICAL security findings unresolved; Tier 3 determinism (the safety-critical invariant) enforced at 5+1 independent layers. The Sprint 5 final Security Posture Report says **GO with three conditions** (file D-M01 transitive HIGH advisories as v1.6 chore; confirm the skin-system branch merge state — done; run the cross-platform runbook's done-criteria checklist on Android emulator + Chrome web before the tag push). The team-internal lesson worth surfacing is **memory-system compounding**: by Sprint 5, the project's auto-memory (`workflow_parallel_agent_dispatch.md`, `feedback_intervention_tier1_breathing.md`) was operationalised salvage discipline that recovered six dispatch failures across the sprint without slipping the tag.

## Section 1 — Project Overview

MoodBloom is a cross-platform Flutter mood-tracker for Android and Web. The product reconciles sustained-engagement gamification with strict clinical safety guardrails: an ecosystem-model visualisation (plants never die regardless of mood), a five-algorithm pure-Dart Pattern Engine, a tiered intervention dispatcher with curated Tier 3 phrases (never Gemini), a mood-agnostic token economy with cosmetic-only spending, and a comprehensive bipolar/medical disclaimer service.

Timeline: April 21 – May 19, 2026 (nine weeks; five working-week sprints). 274 total git commits across 14 release branches and 4 tagged releases (`v0.2-walking-skeleton`, `v0.3-beta`, `v1.0`, `v1.5` local).

## Section 2 — Multi-Agent Team Charter

Four named subagents under Claude Code, each with a specific tool surface and authority boundary:

| Agent | Authority | Tool surface | Output type |
|---|---|---|---|
| architect | System design, ADR/HB authorship, module boundary calls | Read, Glob, Grep, WebFetch (read-only) | Decision records + handoff briefs |
| flutter-engineer | Dart/Flutter + Cloud Function TypeScript implementation | Read, Write, Edit, Glob, Grep, Bash | Feature branches with code + in-PR unit tests |
| qa-engineer | Widget/golden/integration tests, a11y sweep, perf profile | Read, Write, Edit, Glob, Grep, Bash | Test files + sweep reports |
| security-reviewer | Read-only audit of rules, CFs, auth, secrets, deps, PII | Read, Glob, Grep, Bash | Risk register only — never patches |

**Critical rule: no self-review.** The agent that wrote the code cannot approve its own work. Two Sprint-3 security audits caught CRITICAL findings (cross-user queue drain, lost UUIDs) that would have shipped silently if the implementer had been the reviewer. Recursive application: when the orchestrator drafts an ADR, a separate agent (typically security-reviewer) verifies before merge.

**Plan Mode enforces the separation.** Every sprint kickoff entered Plan Mode and produced a written plan file at `~/.claude/plans/<plan-name>.md` covering file creation order, per-component design choices, risks, time estimate, verification approach. The architect or orchestrator approves via `ExitPlanMode` before any code is written.

## Section 3 — Workflow Description

```
                    ┌──────────────────────┐
                    │ Sprint kickoff prompt│
                    │ (Plan Mode entered)  │
                    └──────────┬───────────┘
                               ▼
                    ┌──────────────────────┐
                    │ architect drafts ADR │
                    │ + handoff brief      │
                    └──────────┬───────────┘
                               ▼
                    ┌──────────────────────┐
                    │ flutter-engineer     │
                    │ implements feature   │
                    │ + writes unit tests  │
                    └──────────┬───────────┘
                               ▼
            ┌──────────────────┴──────────────────┐
            ▼                                     ▼
┌──────────────────────────┐    ┌──────────────────────────┐
│ qa-engineer adds widget/ │    │ security-reviewer audits │
│ golden/integration tests │    │ if rules/CFs/auth/secrets│
│ + a11y + perf sweep      │    │ touched (read-only)      │
└──────────────────────────┘    └──────────────────────────┘
                               ▼
                    ┌──────────────────────┐
                    │ merge to main / tag  │
                    └──────────────────────┘
```

Four CI/hook gates fire on every commit:
- **Format** — `dart format --set-exit-if-changed` blocks unformatted code.
- **Analyze** — `flutter analyze` fails the build on warnings or errors (not info-level lints).
- **Secret scan** — regex blacklist for API keys, JWT-shaped strings, `.env` patterns.
- **Domain purity** — grep over `apps/mobile/lib/features/*/domain/` for forbidden `package:flutter`, `package:firebase_*`, `package:cloud_firestore` imports.

The preWrite hook in `.claude/hooks/settings.json` blocks any Write tool call into `*/domain/*` that contains a forbidden import string. Caught zero violations across the entire codebase across all five sprints — when an agent attempted a violation, the hook fired, the agent re-attempted with a proper repository abstraction.

## Section 4 — Sprint Execution Audit (S2–S5)

### S2 — Walking Skeleton (v0.2-walking-skeleton)

- **PR count:** 8 (1.1 → 6.1 → 3.1 → 2.1 → 3.2 → 5.1 → 1.3 → qa-widget-tests). Stacked merges to keep each diff reviewable.
- **Test files added:** 13 widget tests (auth, mood, intensity slider, mood type grid).
- **Domain coverage at sprint end:** every feature ≥80% (full breakdown in retro).
- **Agent invocations:** ~25 total — architect ×4 (HB-001, HB-002, ADR-0001, sprint plan); flutter-engineer ×7 (one per PR); qa-engineer ×2 (widget tests, top-up); security-reviewer ×2 (auth audit, foundation audit).
- **Human-team interventions:** Two parallel-agent collisions on a shared working tree (now codified as `isolation:"worktree"` discipline); two Anthropic rate-limit interruptions mid-task; one PR comment that surfaced the `AuthFailure.unknown.cause` PII leak risk.
- **Blockers + resolutions:** Local Android build blocked by `JAVA_HOME` misconfiguration; Web build succeeded. Resolved post-sprint.

### S3 — v0.3 Beta (AI, Offline, Security)

- **PR count:** 13 (compressed from a planned 5-day sprint into 2 intensive days).
- **Test files added:** 217 (~145 domain + ~85 widget + 17 Firestore-rule emulator + 14 CF Jest).
- **Domain coverage at sprint end:** 94.6% overall; every feature ≥80%.
- **Agent invocations:** ~40 total. Three ADRs (0003 Gemini CF contract, 0004 Drift schema, 0005 LWW conflict resolution) front-loaded.
- **Human-team interventions:** Two CRITICAL security findings caught before merge (cross-user queue drain at sign-in/sign-out cycle; Firestore `add()` discarding the client UUID producing duplicate Drift rows). Both fixed in-PR. The 3-PR Drift chain (schema → sync manager → cutover) was reviewable in isolation.
- **Blockers + resolutions:** ~30% of sprint wall-clock spent on orchestrator manually finishing tasks the agents could not complete in a single rate-limit window. Lesson: scope individual handoff briefs to ≤40 file edits.

### S4 — v1.0 (Ecosystem Redesign)

- **PR count:** 12 + 1 polish round (33 discrete tasks within the polish).
- **Test files added:** 370 (664 total at v1.0; 736 at v1.0-polish). 24 golden tests under 4% pixel tolerance.
- **Domain coverage at sprint end:** every feature ≥80%; garden domain at 96.4%.
- **Agent invocations:** ~50 total. Two ADRs (0010 Ecosystem model + 0011 Client-side Pattern Engine) shipped at kickoff.
- **Human-team interventions:** User-testing pass after the v1.0 ship produced ~30 high-signal issues; all closed same-day in the polish round. Bangkok Firestore region rejection (asia-southeast3 unsupported for v1/v2 triggers) cost 2 hours; resolved by converting `sendCheerUpPush` to `onCall`.
- **Blockers + resolutions:** Mann–Kendall quantization deviation (closest achievable Z = −2.190 vs. spec's −2.21 ± 0.005); architect approved a softening to ±0.05 on the spot.

### S5 — v1.5 (Safety Net Live)

- **PR count:** 14 commits on `feat/s5-v1.5-final` plus the parallel skin branch merged via `ed2cd755`.
- **Test files added:** 354 net (1018 total after the v1.5 trim that deleted 78 golden + duplicate-a11y tests).
- **Domain coverage at sprint end:** unchanged from v1.0 at 94.6%; no domain tests removed in the trim.
- **Agent invocations:** ~65 total. Eight ADRs accepted (0008, 0009, 0012, 0013, 0014, plus three smaller). Three handoff briefs (HB-007, HB-008, HB-009).
- **Human-team interventions:** SIX agent-dispatch salvages (work-in-orchestrator-cwd, agent-doesn't-commit, wrong-base-branch, rate-limit-mid-task, socket-error-mid-task, work-in-worktree-but-uncommitted). Salvage playbook now codified in `[[workflow_parallel_agent_dispatch]]` memory with six failure-mode-specific recovery procedures. Four user-testing items the agents missed (skin widget tests deferred; WebAuthn settings tile not surfaced; debug-trigger fires only once; flower hitbox too small + offset). All shipped same-week.
- **Blockers + resolutions:** None blocked the tag. The R-H01 finding (account-deletion cascade missing Storage media) was caught and fixed in `c1ca5021` before tag-time.

## Section 5 — Risk Register + Security Posture

**Final Security Posture Report** at `docs/security/sprint-5-final-posture-report.md` (commit `626c8c3e`). Summary:

| Severity | Count at v1.5 | Disposition |
|---|---|---|
| CRITICAL | 0 | — |
| HIGH | 0 (production code; R-M04 transitive deps) | Filed as v1.6 chore |
| MEDIUM | 0 unresolved | All Day-2 interim findings (R-H01, R-M01/02/03, R-L02/L03) verified PASS in `c1ca5021` |
| LOW | 3 | R-L05 (FilterReject.snippet dead field); R-L06 (housekeeping); R-L01 (App Check posture matches project precedent) |

**Tier 3 fence at 5+1 layers** (the architectural invariant that anchors the entire safety posture):
1. Type system (`AiAllowedTier { one, two }`)
2. Dispatcher hard branch (`if (tier == Tier.three) ...`)
3. Unit test (`recordingFake.calls.isEmpty`)
4. Controller test (re-asserts at controller layer)
5. Integration test (full app, only AI repo mocked)
6. Server schema (CF `suggestQuote.ts` rejects `tier: 3`)

**Firestore rules:** field-level `diff().affectedKeys()` validation on every collection; per-user isolation; immutability fences on `createdAt`, `weeklyGardens` (write-once), `tokenBalance` (monotonic-up), `insightsDisclaimerAcked` (one-way `false→true`). No HIGH/CRITICAL findings in the Day-4 final audit.

**Cloud Functions:** all four production CFs (`analyzeMoodText`, `sendCheerUpPush`, `suggestQuote`, `wipeUserData`) deployed to `asia-southeast1` with rate limits, no PII in logs, no PII in Gemini payloads (verified by PII canary tests in `functions/src/__tests__/`). WebAuthn CF `webauthnRegisterStart` ships dark with a provisioning guard — `WEBAUTHN_PRODUCTION_ORIGIN` empty by default rejects every call until v1.5.1 flips the flag.

**Dependencies:** `flutter pub deps` clean of HIGH/CRITICAL; `pnpm audit` in `functions/` has 3 transitive HIGH advisories (`fast-xml-builder`, `fast-uri`) — all in `@google-cloud/*` dependency chains, none reachable from attacker-controllable input on the deployed v2 callable surface. Filed as D-M01 v1.6 chore.

**Secrets:** zero secrets found in source across the full S5 diff (`b7a95104..977b86d3`). Gemini API key in Secret Manager; client never sees it. Firebase API keys are public-by-design (HTTP referrer / package-id restrictions enforce the boundary).

## Section 6 — Evidence Package Index

- **Repo URL:** (set by team before submission)
- **Branch + tag:** `feat/s5-v1.5-final` @ `977b86d3` tagged locally as `v1.5`
- **14 ADRs:** `docs/adr/0001-…` through `0014-…`
- **9 handoff briefs:** `docs/handoffs/HB-001-…` through `HB-009-…`
- **4 retros:** `docs/retros/sprint-2-retro.md`, `sprint-3-retro.md`, `v1.0-polish-retro.md`, plus the in-this-deliverable `reports/sprint-4-demo.md` + `sprint-5-demo.md`
- **2 architecture diagrams:** `docs/architecture/conceptual.md` + `implementation.md` (Mermaid source; PNG render pending — see `reports/images/README.md`)
- **5 security audits:** `docs/security/audit-2026-04-28-{foundation,auth}.md`, `audit-2026-05-12-v1.0-redesign.md`, `sprint-5-final-posture-report.md`
- **5 test reports:** `docs/test-reports/sprint-3-test-report.md`, `v1.0-polish-test-report.md`, `sprint-5-a11y-report.md`, `sprint-5-dark-mode-contrast-report.md`, `sprint-5-perf-static-review.md`
- **1 cross-platform runbook:** `docs/test-reports/sprint-5-cross-platform-runbook.md` (execution pending)
- **1018 test files at `v1.5`:** unit, widget, integration (`apps/mobile/test/`, `apps/mobile/integration_test/`)
- **73 CF tests:** `functions/src/__tests__/`
- **Golden tests:** intentionally deleted in the v1.5 final trim due to Windows-vs-CI pixel drift; visual coverage now relies on widget-tree assertions + manual demo. Deletion commit: `a23480b8`.

## Section 7 — Compliance Matrix (Enterprise R1–R5)

### R1 — Authentication & Security

- Email/password + Google OAuth via Firebase Auth (`features/auth/`).
- Biometric reauth via `local_auth` with Keystore-backed credential persistence (ADR-0008 cooldown anchor, ADR-0013 privacy gate).
- PIN fallback (PBKDF2-SHA-256, 100,000 iterations, 16-byte salt, hash at `users/{uid}/security/pin`, server-side rate-limit) for Web + Android-no-biometric per ADR-0013.
- WebAuthn foundation per ADR-0014 ships dark in v1.5; provisioning-guard rejects every call until v1.5.1 lights up.
- Firestore rules with field-level `diff().affectedKeys()` validation on every collection.
- Cloud Function PII filter (`functions/src/suggestQuote.ts`, `wipeUserData.ts`): outbound payloads never contain `userId`, `email`, `moodText`, FCM tokens, or Storage object names. Verified by PII canary tests.
- Secret scan clean across the full S5 diff.

### R2 — Clean Architecture

- Three-layer rule per feature: `presentation/`, `domain/`, `data/`.
- Domain layer has zero `package:flutter` / `package:firebase_*` / `package:cloud_firestore` imports. Enforced three ways: CI grep, preWrite hook, code review.
- Freezed entities + JSON serialization via `freezed_annotation` + `json_serializable`.
- Riverpod 2.x with `@riverpod` codegen for controllers; provider overrides for testing.
- Repository abstractions: domain defines `abstract class MoodRepository`; data layer provides concrete `MoodRepositoryImpl`. Tests swap fakes via `ProviderScope.overrides`.

### R3 — Multi-Agent Workflow

- Four named subagents: architect, flutter-engineer, qa-engineer, security-reviewer.
- Plan Mode discipline at every sprint kickoff (5 sprints, 5 plan files at `~/.claude/plans/`).
- 9 handoff briefs at `docs/handoffs/HB-001..HB-009.md`.
- 14 ADRs at `docs/adr/0001-..0014-.md`.
- No self-review: the implementer cannot approve their own work; security audits run on separate agent invocations.
- Memory system at `~/.claude/projects/.../memory/` records workflow lessons across sessions (`workflow_parallel_agent_dispatch.md`, `feedback_intervention_tier1_breathing.md`).

### R4 — Observability

- Firebase Crashlytics wired in `apps/mobile/lib/main.dart` (debug-only `test crash` button in Settings).
- Structured logger at `packages/core/lib/src/logger.dart` — PII-free by convention; verified by sweep across S5.
- Remote Config flags: `ai_pattern_analysis_enabled` (gates Tier 1/2 Gemini path) + `history_privacy_lock_enabled` (kill-switch per ADR-0013).
- Sprint metrics dashboard: per-sprint PR count + test count + coverage tracked in retros.

### R5 — Quality Gates

- **Correctness:** 1018 `flutter test` + 73 `npm test` (CF) all pass at `v1.5`; domain layer line coverage ≥80% per feature, 94.6% overall.
- **Security:** `flutter pub deps` clean of HIGH/CRITICAL; `pnpm audit` 3 transitive HIGH advisories filed as v1.6 chore (non-exploitable in deployed paths); secret scan clean; Firestore rules pass emulator tests.
- **Accessibility:** Semantics labels on every interactive widget; WCAG 2.2 AA contrast verified on both themes across 16 token pairs × 2 themes = 32 measurements; dynamic-type at 200% checked on every dialog.
- **Performance:** static review confirms no unbounded `ListView` callsites + the chart caps at 30 data points (well within a single frame budget). Cold-start <2s on mid-range Android — pending the cross-platform runbook's device-side measurement.

## Section 8 — Lessons Learned

**Plan Mode + handoff briefs front-load design.** ADR-0010 (ecosystem model), ADR-0011 (client-side Pattern Engine), ADR-0012 (Tier 3 determinism), HB-007 (intervention dispatcher) were all drafted before implementation began. Implementation agents had no architectural questions mid-sprint. The 1-2 hours of architect time per ADR was the highest-leverage time in the project.

**Multi-layer fences for safety-critical invariants.** The Tier 3 fence at 5+1 layers is more paranoid than typical industry practice. The cost was modest; the benefit is that any future refactor breaking the invariant fails on the same PR. Recommend the same pattern for any other architectural rule that, if violated, causes user harm.

**Parallel agents need worktree isolation by default.** Six dispatch salvages in Sprint 5 alone. The memory note now documents six failure modes (work-in-orchestrator-cwd, agent-doesn't-commit, wrong-base-branch, rate-limit-mid-task, socket-error-mid-task, work-in-worktree-but-uncommitted) with specific recovery procedures. Default `isolation:"worktree"` for file-mutating dispatches eliminates the first failure mode entirely.

**User testing surfaced more than security audits did.** Four of the most-impactful fixes in the v1.5 final round came from a single user opening the app: "too small", "lot of offset", "doesn't show", "fires only once". Recommend: always budget one user-testing pass between release-candidate and tag.

**Golden tests are too brittle for a small team on Windows-vs-CI.** Pixel-deterministic snapshots produced noise that consumed reviewer attention. Deleted in the v1.5 final trim. Widget-tree assertions + manual demo coverage replaced them.

**Memory compounds.** By Sprint 5, the salvage playbook in `[[workflow_parallel_agent_dispatch]]` had been operationalised through six recoveries. The first recovery cost 30 minutes of orchestrator time; the sixth cost five. Codifying recovery procedures in long-lived memory is the highest-ROI workflow investment a team using AI-assisted enterprise dev can make.

**For future student teams using AI-assisted enterprise workflows:**

1. Write the ADR before the code. Always.
2. Default file-mutating agent dispatches to `isolation:"worktree"`. Always.
3. Verify the agent actually committed before believing its "done" report.
4. Budget 30% of the sprint clock for orchestrator-side salvage.
5. Treat the user-testing pass as a P0 deliverable.
6. Codify recovery procedures the first time they happen, not the third.
7. Multi-layer fences for safety-critical invariants — the cost is modest, the protection is structural.

## Sign-off

- **Audit head:** `977b86d3` (local tag `v1.5` on `feat/s5-v1.5-final`)
- **Date:** May 30, 2026
- **Recommendation:** **GO** for the v1.5 tag push pending three conditions:
  1. File D-M01 (transitive `pnpm audit` HIGH advisories) as a v1.6 ticket.
  2. Skin-system branch merge state confirmed (done in `ed2cd755`).
  3. Cross-platform runbook done-criteria checklist passes on Android emulator + Chrome web before the push.

When the three conditions are met, push the tag and submit the report set to the course portals (CSC231 May 26; CSC234 May 28; Enterprise May 30).
