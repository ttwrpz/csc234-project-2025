# Sprint 5 Retrospective — v1.5: Cheer-Up FCM + Account Deletion + Final Release

**Sprint window:** May 13 – May 19, 2026 (5 working days)
**Demo readiness:** May 19, 2026
**Release tag:** `v1.5` on `main` at <commit-sha-tbd> (post-demo)
**Authored:** Sprint 5 Day 5 evening (post-tag).

> **DRAFT** — This file is the post-tag finalization slot. Sections marked *(fill at demo close)* will populate from real demo + tag + CI evidence. Everything else is grounded in landed PRs and ships in the v1.5 evidence package.

## Goal

> Ship the cheer-up intervention end-to-end (FCM push + banner + breathing exercise + 10-day Hotline 1323 escalation), account deletion, complete the integration test matrix, run accessibility + performance sweeps, finalize the Enterprise Audit Report. By end-of-sprint MoodBloom is **v1.5 — final release**, ready to present and submit.

**Result: shipped.** *(fill at demo close — "shipped with N caveats" if any acceptance criterion slipped)*

## What landed (WBS reference)

24 commits between `v1.0` (`d1eaa1df`) and the v1.5 candidate. Squash-merged from 18 PRs; the per-feature breakdown:

| WBS | PRs | What landed |
|---|---|---|
| 2.4 | #34 + #36 + #37 | Account deletion: domain (`AuthCredentials` envelope + `DeleteAccountUseCase`) → CF (`deleteAccount` admin-SDK cascade per ADR-0009) → UI (Settings Danger zone + reauth-or-fallback modal). Biometric reauth documented as a v1.6 enhancement (S4's `local_auth` doesn't cache a Firebase credential). |
| 5.5 | #28 + #31 + #32 + #35 + #41 | Cheer-up loop closed end-to-end. PR #28 fixed the Semantics-label drop. PR #31 added `CheerUpController` + Firestore-primary `InterventionStateRepository` (ADR-0008). PR #32 verified the 10-day footer. PR #35 added `sendCheerUpPush` CF + `flutter_local_notifications` channel registration. PR #41 closed the audit follow-ups (R-001 schemaV mutation, R-004 PII canary on internal branch, R-005 dead-token survivor hygiene, R-006 channel-id static check). |
| 6.3 | #30 | FCM toggle + permission flow + `users/{uid}/settings/notifications` doc + 7 emulator rules cases. R-002 + R-003 audit fixes folded into the same PR. |
| 7.3 | #25 + #33 + #38 | Four real integration flows: auth, mood-log/history, ai-override, pattern-intervention. Closes the WBS row in full. |
| 7.4 | (deferred) | *(fill — Day 3 Android matrix + Day 4 web matrix + a11y sweep + perf profile)* |
| 8.1 | #24 + #26 | Architect docs (HB-003 + HB-004 + ADR-0008 + ADR-0009) + Audit Report sections 1-8 fully populated. |
| (carry) | #23 + #27 + #29 | S4 carry-over hygiene: AndroidManifest biometric + FCM perms + `MainActivity extends FlutterFragmentActivity`, ci.yml gh CLI smoke + coverage comment, PR template, DevOps follow-ups runbook (R-M01 + R-M02 IAM + R-3 + AC-PROV). |

Plus:
- **`v1.0` tag pushed retroactively Day 1** at `d1eaa1df` (S4 demo missed pushing the annotated tag; recovered before Day 2 starts).
- **Sprint 4 retro authored Day 1 background** (`docs/retros/sprint-4-retro.md`) — covers the v1.0 increment + the three S4 acceptance misses (goldens count, missing audit doc, untagged release).

## Test count delta

| | v1.0 | v1.5 candidate | Δ |
|---|---:|---:|---:|
| `flutter test` (apps/mobile) | 354 | *(fill)* | +N |
| `flutter test --tags=golden` (golden files) | 3 | *(fill — target ≥9)* | +6 |
| `pnpm test` (functions/) | 27 | 40 | +13 |
| `firebase/test` (rules emulator) | 17 | 38 | +21 |
| Domain coverage | 94.6% | *(fill)* | — |

The +21 emulator-rules cases come from: 7 cases for `users/{uid}/settings/notifications` (PR #30, including the R-002 cross-user write regression), 12 cases for `cheerUpEvents` + `interventionState` (PR #35 cases 26-37), 1 case for the schemaV-mutation regression (PR #41 case 38), 1 case carried into the v1.5 supplement.

## What went well

- **Three-layer PII fence pattern reused twice without drift.** ADR-0003 + ADR-0007 established the pattern: client datasource projection + server Zod `.strict()` schema + server logger allowlist. v1.5 added `sendCheerUpPush` (PII canary case 6 of 8 covers token + body + title leakage) and `deleteAccount` (PII canary case 5 of 5 covers mood text + Storage paths + tokens) using the same shape. Audit-clean on both.
- **ADR-0008 + ADR-0009 pre-decided the v1.5 storage topology.** Cooldown anchors moved from SharedPreferences-only to Firestore-primary + SharedPrefs offline mirror. Account deletion uses an admin-SDK cascade. The decisions landed Day 1 morning so 5.5a + 5.5b + 2.4b never had to pause for design Q&A. ADR-0007's "statistical-primary, Gemini-supplementary, ≤0.7 confidence clamp" pattern continued to pay dividends — the v1.0.1 Gemini wire-in shipped without a regression because the ADR pre-committed the failure modes.
- **`isolation: "worktree"` adopted across every Day-2 file-mutating dispatch.** S5 Day 1 afternoon's collision (6.3 + 7.3a sharing `feat/6.3-fcm-toggle`'s working tree, 6.3 had to be discarded entirely) was the third occurrence of the failure mode in this project. The mitigation is now in `~/.claude/projects/.../memory/workflow_parallel_agent_dispatch.md` so future sessions adopt it without prompting. Day-2 dispatches all ran clean — five flutter-engineer agents in parallel, zero collisions, zero discarded work.
- **Real-Firestore E2E catches what mock-Map tests cannot.** PR #36's emulator E2E spec found a production-CF bug (`rateLimits/cheerUp/${uid}` was 3-segment when the actual collection is `rateLimits.cheerUp` flat) that the Jest mock missed because the mock used a `Map<string, ...>` accepting any string key. CI's emulator job blocked the merge; the orchestrator fixed both the production CF + the spec + the Jest mock in a single 4-site commit. Pattern: every CF that touches collection literals needs at least one emulator test in CI.
- **Audit findings get tighter as the system matures.** PR #23: 1 MEDIUM (R-001 channel registration). PR #30: 3 MEDIUM. PR #35: 1 MEDIUM + 5 LOW. The MEDIUM finding closed in the same PR every time; the LOW findings either deferred to next sprint or fixed in PR #41. No CRITICAL or HIGH findings in any S5 audit.

## What hurt

- **Anthropic rate-limit exhaustion on Day 1.** First parallel dispatch (architect + flutter-engineer 6.3 + qa-engineer 7.3a) all hit the limit at <10 tool uses each — zero usable output. Recovery: sequence file-mutating agents instead of parallelising on a shared rate-limit pool. ~2 hours wall-clock lost to the first attempt + the retry. Mitigation now in the agent-dispatch memory file.
- **Port-stuck local emulator stalled the HB-004 step 2 dispatch for 13 minutes** before the watchdog killed it. Port 8080 was held by a stray Firestore emulator on the dev host. Two of the planned eight commits salvaged (CF + Jest cases); the other six re-dispatched as HB-004 step 3. Day-3+ dispatch prompts now explicitly forbid local emulator runs on the dev host — CI Linux runners are the authoritative emulator surface.
- **HB-003 doc/code drift on field name (`enabled` vs `cheerUpEnabled`).** The architect's HB-003 brief used `enabled` for the toggle field; PR #30 implementation used `cheerUpEnabled` (more descriptive). PR #35 audit R-001 surfaced the drift. Reconciliation: the implementation shipped as canon; the brief was edited to match in commit `a41dc991` on `docs/s5-architecture`. **Lesson:** when an architect ADR + an implementer PR diverge on a name, the canonical form is whichever one shipped to `main` first. Update the doc, don't rename the code.
- **Banner Semantics label dropped half the locked CLAUDE.md sentence** until PR #28 caught it. The `Semantics(label: ...)` was `"It's been a heavy week. ${reasonCaption}"` — title + reason caption only; the breathing-exercise prompt never reached screen readers. Surfaced while authoring HB-003 §5.5a's parity test. **Lesson:** every CLAUDE.md-locked string needs a `startsWith` Semantics-label assertion as a separate test, not just a visible-Text assertion.
- **Day 3 Android matrix run was disk-blocked on the dev workstation.** The opportunistic Day-2-PM run on a real Samsung S24 Ultra failed at the Android Gradle build step — NDK 28.2.13676358 install failed because C: had 0.4 GB free. Documented in `docs/qa/android-matrix-20260515.md`. Mitigation: run on the team's other workstation OR on CI (the latter requires a v1.6 CI job). Not a v1.5 blocker; the matrix doc captures the gap explicitly.
- **Goldens regenerated on Windows for PR #30** (`settings_screen_{light,dark}.png`). Project convention is Linux-canonical with 4% tolerance; CI re-runs on Linux. The Windows-rendered goldens passed Linux CI within tolerance (lucky), but the convention exists for a reason. **Lesson:** if Day-3 qa-engineer regenerates goldens on Windows, run them through CI before merging to confirm they fall within the 4% tolerance band — don't blind-merge.

## Action items entering v1.6

1. **Free disk space on the dev workstation** so the Android matrix can run end-to-end. Currently 0.4 GB free of 237 GB capacity.
2. **CI emulator job for integration tests** — the kickoff deferred this to v1.6. Add `reactivecircus/android-emulator-runner` to `.github/workflows/ci.yml` so `flutter test integration_test/` runs on every PR. This would have caught the path-shape bug in PR #36 before the merge instead of one push later.
3. **Biometric reauth for Settings Danger zone** — currently falls back to password reauth because S4's `local_auth` doesn't cache a Firebase credential. v1.6 brief: thread the cached credential through `BiometricCredentials` so the data-layer arm of `AuthRepositoryImpl.reauthenticate` can use it.
4. **Per-token shape validation as Firestore sub-collection** — HB-003 OQ-A flagged. Rules can't iterate list elements; the 25-cap + client-side validation is the v1.5 compromise. v1.6 alternative: model `tokens` as `users/{uid}/settings/notifications/tokens/{tokenId}` so per-token shape can be rule-validated.
5. **DevOps R-M01 + R-M02 IAM + R-3 + AC-PROV.** Documented in `docs/runbooks/devops-followups.md`. All four must close before any production deploy.
6. **Audit-driven test pattern for CLAUDE.md-locked strings.** Three S5 PRs caught locked-string drift (PR #28 banner Semantics, PR #41 channel-id literal, the HB-003 reconciliation). Codify the pattern: every locked string gets a `startsWith` (for partial-render contexts like Semantics labels) AND an `equals` (for the literal-render context) test.

## What's NOT in v1.5 (out-of-scope per the kickoff)

These are deliberately deferred to v1.6 and beyond:

- iOS build (v2.0)
- Thai localization (v2.0)
- Event sourcing for mood history (v2.0)
- Therapist-facing shared mood export (v2.0)
- 30-day soft-delete with restore for account deletion (v2.0)
- Notification history / in-app notification center (v2.0)
- Web Google OAuth consent screen (v2.0 — per S5 plan O10)
- `drift_sqlcipher` encryption-at-rest (post-v1.5; was R-6 from S3 retro, never adopted)

## Reference

- Sprint 5 plan: `.claude/plans/refactored-growing-alpaca.md`
- Sprint 4 retro: `docs/retros/sprint-4-retro.md`
- v1.0 → v1.5 commit log: `git log v1.0..v1.5 --oneline`
- v1.5 security audit: *(fill — `docs/security/audit-2026-05-19-v1.5.md` Day 4 deliverable)*
- Enterprise Audit Report: `docs/audit/enterprise-audit-report.md` §6 (agent challenges) + §7 (worked HB-003 example) cite this retro
- ADRs ratified this sprint: `docs/adr/0008-intervention-cooldown-persistence.md`, `docs/adr/0009-account-deletion-topology.md`

## Document changelog

- **Day 5 evening** — Theerawat finalises *(at demo close)*
- **Day 2 PM** — orchestrator drafts skeleton; populates the landed-PRs table + the went-well / hurt sections from the actual sprint events. Test-count delta + final acceptance-status table tagged *(fill)* for Day 5 numbers.
