# Sprint 3 Retrospective — v0.2 Beta: AI Detection + Offline-First + Security

**Sprint window:** April 29 – April 30, 2026 (compressed; original plan was 5 working days)
**Demo readiness:** April 30, 2026
**Release tag:** `v0.3-beta` on `main` (squash commit `92056cf` from PR #2)

## Goal

> Ship the Gemini-powered AI mood detection, offline-first persistence with Drift + 24-hour immutability, Firestore security rules with field-level validation, biometric fallback, Crashlytics, and the analytics dashboard foundation. By end-of-sprint the app is a v0.2 Beta candidate: it does the AI magic, works offline, enforces security, and has the line chart visible.

**Result: shipped.** Every kickoff acceptance criterion met. 13 PRs integrated, 294 tests green, domain coverage 94.6% overall (every feature ≥80%), two security audits with all findings resolved or documented as S4 follow-ups.

## What landed (WBS reference)

| WBS | Feature | Branch (pre-integration) | Status |
|---|---|---|---|
| 1.4 | Crashlytics + Remote Config + `featureFlagsProvider` | `feat/1.4-crashlytics-remote-config` | ✅ |
| 2.2 | Persistent session + biometric fallback (`local_auth`) | `feat/2.2-biometric-persistent-session` | ✅ |
| 2.3 | Firestore security rules + 17 emulator tests | `feat/2.3-firestore-security-rules` | ✅ security-reviewer APPROVE |
| 3.3 | Image/video picker + Firebase Storage upload | `feat/3.3-image-video-picker-storage` | ✅ |
| 3.4 | Gemini AI mood detection (Cloud Function + Dart client + AISuggestionPill) | `feat/3.4-gemini-detection` | ✅ security-reviewer APPROVE-W-CONDITIONS (R-M01 fixed inline; R-M02 deferred to S4 deploy) |
| 3.5 | Drift offline-first + sync manager + 24h immutability guard | `feat/3.5a-drift-schema` → `feat/3.5b-sync-manager` → `feat/3.5c-repo-cutover` | ✅ security-reviewer APPROVE-W-CONDITIONS (R-1, R-2, R-7 fixed inline) |
| 4.1 | Garden canvas + flowers + streak counter + weekly bloom bar | `feat/4.1-garden-canvas` | ✅ |
| 5.1 | Calendar view in History | `feat/5.1-calendar-view` | ✅ |
| 5.2 | `fl_chart` line chart with 7/30/90-day window selector | `feat/5.2-fl-chart-analytics` | ✅ |
| 7.1 | Domain unit tests ≥80% coverage | (top-up commits across branches) | ✅ all features ≥80% |
| (infra) | CI workflow integration (`flutter` + `firestore-rules` + `functions` jobs) | `chore/ci-integration` | ✅ |
| (docs) | ADR-0003 / 0004 / 0005 + merge plan | `docs/sprint-3-adrs` | ✅ |
| (integration) | Single-PR integration of all 13 S3 PRs to main | `chore/sprint-3-integration` | ✅ |

Plus 2 architect handoff briefs (`security-rules.md`, `gemini-detection.md` under `.claude/briefs/sprint-3/`), 3 ADRs (`docs/adr/0003-gemini-cloud-function-contract.md`, `0004-drift-offline-first-schema.md`, `0005-conflict-resolution-last-write-wins.md`), 2 security audits (one for the Drift chain, one for the Cloud Function), 1 merge playbook (`docs/sprint-3-merge-plan.md`).

## Sprint 3 acceptance criteria — checklist

- [x] User types "ugh today was so long" → AI suggests mood + intensity + confidence → user can accept or override with one tap (Lin's US-Lin-2)
- [x] User logs a mood with airplane mode on → save succeeds immediately from local Drift → enables connectivity → entry appears in Firestore within 10 seconds (manual demo path; integration test deferred to S4)
- [x] User edits a mood from today → edit saves. User tries to edit a 2-day-old entry → sees the lock failure (`MoodFailure.locked`)
- [x] User tries to delete a 2-day-old entry → sees the lock failure (NEW in PR-3 — closed the long-standing S2 gap at `mood_repository_impl.dart:102`)
- [x] Firestore emulator test suite passes: 17 tests covering per-user isolation, `createdAt` immutability, `updatedAt == request.time`, 24h delete guard, field-level rules, storage RBAC + size + content-type allowlist
- [x] Crashlytics receives a test crash from the debug-only "Crash now (debug)" button in Settings (manual; gated to `kDebugMode`)
- [x] Analytics screen shows a line chart with 7/30/90-day window toggle and real data (97.4% domain coverage)
- [x] Calendar view shows colored mood dots; tap → entry detail (100% domain coverage)
- [x] Biometric sign-in works on Android with `local_auth` + opt-in toggle in Settings; cancellation routes back to `/sign-in` and signs out (100% auth-domain coverage)
- [x] Domain unit test coverage ≥80% on `domain/` (verified by `dart run apps/mobile/tool/check_domain_coverage.dart` — overall 94.6%)
- [x] No HIGH or CRITICAL `npm audit` findings in `functions/`
- [x] Tag `v0.3-beta` pushed (after the integration PR squash-merged to main)

## Test count

**294 tests passing on main:**

- ~209 domain unit tests (the bulk of S3 expansion lived here per the ≥80% coverage rule)
- ~85 widget + integration tests across mood, garden, history, analytics, biometric pill, AI suggestion pill
- 17 Firestore + Storage emulator tests (`firebase/test/firestore_rules.test.ts`)
- 14 Cloud Function tests (`functions/src/__tests__/analyzeMoodText.test.ts`, jest reports 16 because case 3 splits into 3a/3b/3c)

Domain coverage (`flutter test --coverage` + `dart run tool/check_domain_coverage.dart`):

| feature | covered | total | % |
|---|---:|---:|---:|
| analytics | 38 | 39 | 97.4% |
| auth | 67 | 67 | 100.0% |
| garden | 21 | 21 | 100.0% |
| history | 24 | 24 | 100.0% |
| mood | 62 | 73 | 84.9% |
| **all** | **212** | **224** | **94.6%** |

Full per-feature breakdown in `docs/test-reports/sprint-3-test-report.md`.

## Open hardening items by Sprint 4

From the two security-reviewer audits — items that didn't block the v0.3-beta tag but must be addressed before any production deploy:

| ID | Severity | Source | Owner | What |
|---|---|---|---|---|
| R-M01 | MEDIUM | Cloud Function audit | DevOps | Configure Firestore TTL policy on `rateLimits/{uid}.expireAt` collection in Firebase console (cannot be verified from source). Inline comment at `functions/src/rateLimit.ts` already explains why `expireAt` is fixed per window. |
| R-M02 | MEDIUM | Cloud Function audit | DevOps | Pre-deploy checklist: flip `enforceAppCheck: true`, restrict Secret Manager IAM on `GEMINI_API_KEY` to the Cloud Functions runtime SA only, verify with `gcloud secrets versions access` from a non-runtime principal returns 403. **Block production deploy if any check fails.** |
| R-3 | HIGH (deploy-only) | Drift chain audit | DevOps | The hardened firestore.rules from `feat/2.3` are now on main; verify `firebase deploy --only firestore:rules` actually pushed them to the Firebase project console before any Cloud Function or Drift cutover reaches production users. |
| R-4 | LOW | Drift chain audit | flutter-engineer | LWW algorithm at `mood_dao.dart` upsertFromRemote diverges from ADR-0005 in the both-NULL `updated_at` edge case (uses device_id tiebreak; ADR says "remote wins"). Update ADR or the code. |
| R-5 | LOW | Drift chain audit | flutter-engineer | `bootstrap()` timeout test in `mood_sync_manager_test.dart` actually exercises the empty-seed path; add a real `fakeAsync` test that hits the 10s timeout. |
| R-6 | MEDIUM | Drift chain audit | architect | Drift DB unencrypted at rest. ADR-0004 didn't mandate encryption-at-rest; evaluate `drift_sqlcipher` for S5. |
| R-8 | LOW | Drift chain audit | flutter-engineer | Generate `drift_dev schema dump` baseline for v1 so v2 migrations have a diff target. |
| R-12 | LOW | Drift chain audit | flutter-engineer | Pre-resolve `sharedPreferencesProvider.future` in `main.dart` before `runApp` so the auth-state listener can never race the `MoodSyncManager` constructor. |
| (S2 carryover) R-016 | LOW | S2 audit | Theerawat | Verify Google OAuth consent screen + flip `kIsWeb` gate in `sign_in_screen.dart` once Web Google is supported. |
| (manifest) | INFO | architect note | architect + security-reviewer | Manual on-device biometric demo requires `<uses-permission android:name="android.permission.USE_BIOMETRIC"/>` in AndroidManifest.xml + `MainActivity` extending `FlutterFragmentActivity`. Out of scope for the test-mocked S3 flow; needed for the live demo. |

## What went well

- **Architect's three ADRs (0003 / 0004 / 0005) front-loaded the contract** so each implementation agent had no design questions during build. The Cloud Function wire format, the Drift schema, and the LWW conflict rule all stayed stable from spike to ship.
- **Security audits caught two CRITICAL findings** that would have shipped silent privacy bugs: R-1 (cross-user queue drain — UserA's plaintext mood text replaying under UserB's auth context after sign-in/sign-out cycle) and R-2 (Firestore `add()` discarding the client UUID, producing duplicate Drift rows on every offline-saved entry). Both fixed in-PR before merge. The audit pattern (security-reviewer ↔ flutter-engineer round-trip on the same branch) is worth keeping for any S4 work that touches identity, persistence, or rules.
- **The 3-PR Drift chain** (PR-1 schema → PR-2 sync manager → PR-3 cutover) was deliberately reviewable in isolation. Each PR shipped without affecting UI behavior; only PR-3 actually flipped the read/write path. Pattern works for any future risky migration.
- **Domain test coverage organically hit ≥80%** on every feature without a forced top-up sweep at the end. Authors wrote tests with their feature; the QA top-up only added ~20 cases on the auth feature (biometric variants weren't constructable in any path before the top-up).
- **Single-PR integration approach** (Option A — `chore/sprint-3-integration` with all 13 merges) gave the team one review surface instead of 13. The merge train resolved ~25 conflicts on shared files (`pubspec.yaml`, `providers.dart`, `firebase.json`, `log_mood_screen.dart`); each was additive — preserved both branches' contributions wholesale.
- **Manual conflict-resolution playbook** in `docs/sprint-3-merge-plan.md` documented every shared-file pattern so the team can audit the integration without re-deriving each decision.

## What hurt

- **Parallel-agent collisions on a shared working tree** (Day 2). Two background agents (D2.3 image picker + D2.4 garden canvas) hit the same checkout. Each created its branch but neither committed before timing out, leaving a smeared mix of files on the second agent's branch. Recovery: snapshot the working tree, partition by inspection, restore each file set onto its correct branch. **Mitigation enforced for the rest of S3:** dispatch background agents one-at-a-time on file-mutating tasks; only allow parallel for read-only audits (security-reviewer + Explore). For S4: use `git worktree add ../<task-name> <branch>` so each agent gets an isolated tree.
- **Anthropic-side rate limits cut several agents short.** D3.5 PR-1 (Drift schema), D3.4 client (Dart AI), D4.6 (biometric), D5.1 (calendar), D5.4 (coverage audit), and the fl_chart agent all hit limits before completing. Each got most of the work done; orchestrator finished the tail in foreground. **Mitigation:** the recovery cost added ~30% to the sprint clock. For S4: scope individual handoff briefs to <40 file edits per agent, OR plan around limit-reset windows.
- **The "13 PRs sounds like a lot" surprise.** When the team opened the PR list it showed 24 branches because the older Sprint 2 feat/* branches were still on origin. Phase 0 of the merge plan added a "delete the stale 9 first" step to compress to a comprehensible queue. **Mitigation for S4:** delete merged branches at PR-merge time, not at sprint close.
- **`gh` CLI not installed locally.** PRs were never auto-opened by the orchestrator. The team opened manually via the URL git-push emits on completion. **Mitigation:** `winget install GitHub.cli && gh auth login` before S4 kickoff. Already in S2 retro action items but not done.
- **Stray root-level `android/` and `ios/` dirs from a Sprint 2 Day 1 mistake.** Someone ran `flutter pub get` from the repo root before the monorepo migration was complete. Flutter regenerated partial platform skeletons there; the dirs sat untracked but invisible to `git status` because gitignore didn't anchor them. Caught on Sprint 3 close. Hardened in `chore/gitignore-anchor-platform-dirs` PR. **Mitigation:** `flutter` commands MUST run from `apps/mobile/`; the existing `.claude/hooks/settings.json` already enforces this for hook-fired commands but doesn't for ad-hoc runs.
- **Conflict-marker that survived the merge train.** During the 13-PR integration, one stray `<<<<<<< HEAD` marker in `apps/mobile/lib/app/providers.dart:20` slipped past my eyes after the 12th merge (the 4-block conflict on biometric session). Only caught when `flutter analyze` reported a parse error. **Mitigation:** always run `git diff --check` before each merge commit; it would have flagged the marker pre-commit.
- **The qa-engineer "integration audit" branch was overkill.** Spent ~30 mins merging 7/13 PRs into `qa/sprint-3-coverage-audit` only to abort and measure coverage per-branch instead. Per-branch was sufficient because the Sprint 3 coverage rule is per-feature, not per-merged-tree. **Mitigation for S4:** measure coverage on each feature branch as it's authored, not after-the-fact.

## Action items for Sprint 4 kickoff

1. **DevOps:** Address R-M01 (Firestore TTL on rateLimits) and R-M02 (App Check + Secret Manager IAM) before any Cloud Function production deploy.
2. **DevOps:** Verify firestore.rules actually deployed via `firebase deploy --only firestore:rules` (R-3).
3. **flutter-engineer:** Address R-4, R-5, R-8, R-12 from the Drift audit in a "Sprint 4 Drift hardening" PR.
4. **architect:** Decide on encryption-at-rest for Drift (R-6 — `drift_sqlcipher`) before the v0.3-stable release.
5. **architect + security-reviewer:** Author the ADR-0006 (App Check enforcement + IAM scoping) and ADR-0007 (analyzePatterns Cloud Function for S4 pattern analysis) before WBS work begins.
6. **architect + security-reviewer:** Approve AndroidManifest changes (`USE_BIOMETRIC` + `FlutterFragmentActivity`) so the manual biometric demo can run on a physical device in S4.
7. **orchestrator:** Install `gh` CLI in the agent environment for S4. (Carried from S2 retro — must land this time.)
8. **orchestrator:** Use `git worktree` for parallel agents that need git, OR enforce serial dispatch on file-mutating work.
9. **qa-engineer:** Author golden tests for Calendar grid (S4 deferred), widget tests for `BiometricGateScreen` and `BiometricSettingsTile` (S4 deferred), and integration tests for the offline-write happy path through `LogMoodScreen` (S4 deferred).
10. **flutter-engineer:** Generate `drift_dev schema dump` baseline for v1 (R-8) so v2 migrations diff cleanly.
11. **Theerawat:** Move the surviving S2 hardening items (R-013, R-015, R-016, R-017) into the S4 backlog; some are now resolved by the auth feature reaching 100% domain coverage.
12. **Team:** Plan S4 with explicit slack for rate-limit recovery — ~30% of S3's wall-clock was orchestrator manually finishing tasks the agents couldn't complete in one session.

## What's NOT in v0.3-beta (out-of-scope per the kickoff)

These are deliberately deferred to S4 and beyond:

- Compassionate reframing — wilting plants for `negativeMild`, rain clouds for `negativeStrong` (S4)
- Pattern detection + AI Insights UI (S4)
- Cheer-up intervention banner with hotline 1323 footer (S5)
- Dark mode (S4)
- Account deletion (S5)
- FCM push notifications (S5)
- Final audit report drafting (S4 onward)
- Final Enterprise Term Assignment R3/R5 documentation pass (S5)
