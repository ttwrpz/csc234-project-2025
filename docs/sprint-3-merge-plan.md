# Sprint 3 — merge-to-main playbook

**Status:** Recommended order, ready for execution.
**Tag target:** `v0.3-beta` after the final merge.
**Author:** orchestrator (architect), 2026-04-30.

---

## The 13 PRs at a glance

| # | Branch | Tip | Tests | WBS | Reviewer gate |
|---|---|---|---:|---|---|
| 1 | `feat/2.3-firestore-security-rules` | `8972963` | 17 emulator | 2.3 | security-reviewer ✅ |
| 2 | `chore/ci-integration` | `3609bcd` | YAML + 3 jobs | infra | — |
| 3 | `docs/sprint-3-adrs` | (this PR) | docs only | infra | — |
| 4 | `feat/1.4-crashlytics-remote-config` | `cb4f7f4` | 86 | 1.4 | — |
| 5 | `feat/3.3-image-video-picker-storage` | `44e5370` | 95 | 3.3 | — |
| 6 | `feat/4.1-garden-canvas` | `7f374d4` | 103 | 4.1 | — |
| 7 | `feat/3.4-gemini-detection` | `0b79322` | 14 fn + 106 flutter | 3.4 | security-reviewer ✅ (R-M01 fixed at `e5146cb`; R-M02 deferred to S4) |
| 8 | `feat/3.5a-drift-schema` | `fdad550` | 102 | 3.5 PR-1 | — |
| 9 | `feat/3.5b-sync-manager` | `a45eb45` | 124 | 3.5 PR-2 | — |
| 10 | `feat/3.5c-repo-cutover` | `1cba951e` | 147 | 3.5 PR-3 | security-reviewer ✅ (R-1, R-2, R-7 fixed at `313ec7bb`) |
| 11 | `feat/5.2-fl-chart-analytics` | `9d9e0712` | 87 | 5.2 | — |
| 12 | `feat/2.2-biometric-persistent-session` | `612fede3` | 107 | 2.2 | — |
| 13 | `feat/5.1-calendar-view` | `3ac92842` | 102 | 5.1 | — |

Every branch is locally green (`flutter analyze` + `flutter test`). Every feature's `domain/` folder is ≥80% line coverage per CLAUDE.md "Quality gates" #1; verify post-merge with `dart run apps/mobile/tool/check_domain_coverage.dart`.

---

## Recommended merge order

Squash merge to `main` per CLAUDE.md "Branching & PR rules". Order matters because some branches modify shared files; merging in this sequence minimises conflicts.

### Phase 1 — Infra (rules, CI, docs)

These are independent of feature code and should land first so subsequent merges run against the strict rules + CI.

1. **`feat/2.3-firestore-security-rules`** — hardened rules + emulator harness. Ships the `rateLimits/{uid}` admin-only rule that the Cloud Function depends on (R-3 from the Drift-chain audit). **Critical: this PR must merge before any production deploy of the Cloud Function or the Drift cutover.**
2. **`chore/ci-integration`** — 3-job CI (`flutter` / `firestore-rules` / `functions` stub). Depends on `firebase/test/` from PR #1.
3. **`docs/sprint-3-adrs`** — ADR-0003 / 0004 / 0005 + this merge plan. No code dependencies.

After Phase 1: CI runs on every subsequent PR.

### Phase 2 — Independent features

These don't depend on each other and don't conflict on shared files.

4. **`feat/1.4-crashlytics-remote-config`** — `featureFlagsProvider` + Crashlytics binding. Lands the `gemini_detection_enabled` and `ai_pattern_analysis_enabled` flags the AI work expects.
5. **`feat/3.3-image-video-picker-storage`** — image/video picker + Storage upload. `MoodEntry.mediaRefs` already exists from S2; this PR just populates it.
6. **`feat/4.1-garden-canvas`** — Garden tab swap-in. Replaces the home-tab placeholder. Read-only consumer.
7. **`feat/3.4-gemini-detection`** — Cloud Function + Dart AI repository + `AISuggestionPill`. Server side first by commit order on the branch.

### Phase 3 — Drift offline-first chain

Sequential. Each PR depends on the previous.

8. **`feat/3.5a-drift-schema`** — schema + DAOs + `databaseProvider`. No behavior change.
9. **`feat/3.5b-sync-manager`** — `MoodSyncManager` + connectivity wrapper. Manager writes to Drift; UI doesn't read from it yet.
10. **`feat/3.5c-repo-cutover`** — `MoodRepositoryImpl` rewired to Drift; `delete()` lock guard added (the long-standing gap from S2); R-1/R-2/R-7 security fixes.

### Phase 4 — Late features

11. **`feat/5.2-fl-chart-analytics`** — analytics line chart with 7/30/90-day window selector.
12. **`feat/2.2-biometric-persistent-session`** — biometric Settings toggle + cold-boot gate. Modifies `router.dart` (`ref.listen` augmentation only — single-block change).
13. **`feat/5.1-calendar-view`** — calendar tab in History.

---

## Pre-merge readiness checklist (per PR)

For each PR, before merging:

- [ ] CI green on the PR (all 3 jobs).
- [ ] Branch is up-to-date with `main` (rebase or merge if needed; conflicts on `pubspec.yaml` / `apps/mobile/lib/features/mood/data/providers.dart` / `firebase.json` are common — resolve additively).
- [ ] At least one approving reviewer (no self-reviews per CLAUDE.md R3).
- [ ] Security-reviewer sign-off where flagged in the table above.
- [ ] PR title references the WBS ID per CLAUDE.md.
- [ ] Squash merge.

After each merge:

- [ ] Pull main locally.
- [ ] `cd apps/mobile && flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs && flutter analyze && flutter test` clean.
- [ ] If a Drift-chain or analytics merge: `dart run tool/check_domain_coverage.dart` shows all features ≥80%.
- [ ] If `feat/2.3` or any rules-touching merge: `firebase emulators:exec --only firestore,storage,auth --project moodbloom-rules-test "npm --prefix firebase/test test"` shows 17/17 emulator tests green.

---

## Conflict expectations during the merge train

The most-likely conflict surfaces (observed during the qa-engineer integration audit on `qa/sprint-3-coverage-audit`):

- **`apps/mobile/pubspec.yaml`** — multiple branches add deps. Resolution: **keep all unique entries, alphabetised**.
- **`apps/mobile/pubspec.lock`** — auto-resolved by `flutter pub get` after merge. Don't hand-resolve.
- **`apps/mobile/lib/features/mood/data/providers.dart`** — multiple branches append providers. Resolution: **keep all imports + all provider declarations**; both `MoodMediaRepository` and `AIAnalysisRepository` providers coexist.
- **`apps/mobile/lib/app/providers.dart`** — additive: `firebaseStorageProvider` (3.3), `crashlyticsProvider`+`remoteConfigProvider`+`featureFlagsProvider` (1.4), `databaseProvider`+`deviceIdProvider`+`sharedPreferencesProvider` (3.5a/b).
- **`apps/mobile/lib/app/router.dart`** — additive routes + `ref.listen` augmentations. Resolution: **merge the listener bodies**; the biometric branch adds an additional clause to the same `ref.listen` block; the garden branch swaps the home-tab `_PlaceholderScreen` for `GardenScreen`.
- **`apps/mobile/lib/features/mood/presentation/log_mood_screen.dart`** — 3.3 adds the `MediaPickerButton` + `MediaThumbnailStrip`; 3.4 adds the `AISuggestionPill` and wraps `MoodTextField.onChanged`. Resolution: **both** layouts coexist (pill above the picker; verified pattern at the qa branch tip).
- **`firebase.json`** — 2.3 adds the `firestore`/`storage`/`auth`/`ui` emulators; 3.4 adds the top-level `functions` block + the `functions` emulator. Resolution: keep all emulator entries.
- **`*.g.dart` and `*.freezed.dart`** — regenerate post-merge with `flutter pub run build_runner build --delete-conflicting-outputs`. Don't hand-resolve.

If a conflict requires choosing between divergent rewrites of the SAME function (not just additive coexistence), STOP and consult the architect.

---

## Final tag (`v0.3-beta`)

After all 13 PRs are merged into `main`:

```bash
git checkout main
git pull
cd apps/mobile && flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze                    # must be clean
flutter test                       # must be all-green
dart run tool/check_domain_coverage.dart   # must show all features ≥80%
firebase emulators:exec --only firestore,storage,auth \
  --project moodbloom-rules-test "npm --prefix firebase/test test"
                                   # must show 17/17 emulator tests green

# tag and push
cd ../..
git tag -a v0.3-beta -m 'Sprint 3 — v0.2-beta candidate (AI detection + offline-first + security)'
git push origin v0.3-beta
```

---

## Demo flow (Sprint 3 acceptance criteria, all satisfied locally)

User-facing demo for the May 5 presentation:

1. Sign up / sign in (S2 functionality).
2. Settings → toggle "Use biometric to unlock" ON. Confirm the test prompt.
3. Type "ugh today was so long" in Log Mood → AI suggestion pill appears (mood + confidence + rationale) → tap "Use this" → mood selected.
4. Tap Save → entry appears in History (list and calendar tabs).
5. Toggle airplane mode ON → log a second mood → save succeeds immediately.
6. Toggle airplane mode OFF → entry syncs to Firestore within ~10s (queue drains).
7. Edit today's entry → succeeds. Try to edit a 25h-old entry → "Your history is a record, not a redo" lock copy.
8. Open Analytics → toggle 7d/30d/90d window → mood-over-time chart updates.
9. Open Calendar tab → today's mood shows as a colored dot → tap → opens detail.
10. Settings → Crash now (debug) → Crashlytics receives the test event.
11. Cold-boot the app → biometric prompt appears before /home.

---

## Known follow-ups (S4 issues — open before merge)

From the security-reviewer audits:

- **R-M01 (Cloud Function rate-limit TTL)** — confirm Firestore TTL policy on `rateLimits/{uid}.expireAt` is configured in the Firebase console. Cannot be verified from source; add to the deploy checklist.
- **R-M02 (App Check + Secret Manager IAM)** — pre-deploy checklist for production: flip `enforceAppCheck: true`, restrict Secret Manager IAM to the function's runtime service account only, verify with `gcloud secrets versions access` from a non-runtime principal returns 403. **Block the production deploy if any check fails.**
- **R-3 (firestore.rules deployment alignment)** — the hardened rules from `feat/2.3-firestore-security-rules` MUST be deployed before the Cloud Function or the Drift cutover reaches production users. Already covered by Phase 1 of this merge order; flagged here as a deploy gate.
- **R-4 through R-12** — MEDIUM/LOW findings from the Drift-chain audit. None block S3; track in S4 backlog.

From the orchestrator's working notes:

- Drift `schema_v1.json` snapshot dump (`drift_dev schema dump`) for diffability of v2 migrations — S4.
- Widget tests for `BiometricGateScreen` + `BiometricSettingsTile` — S4 (use case + entity tests cover the high-value properties for S3).
- Golden tests for the calendar grid + a11y/Semantics audit + integration test for log-mood→detail — S4.
- AndroidManifest changes (`USE_BIOMETRIC` + `FlutterFragmentActivity`) — required for manual on-device biometric demo. Architect + security-reviewer per CLAUDE.md "do-not-do list". Defer unless the team needs the demo.
- Firebase project console: configure Crashlytics + Remote Config defaults; flag-flip `gemini_detection_enabled` to `true` for the demo, leave `ai_pattern_analysis_enabled` for S4's pattern-analysis work.

---

## Retrospective placeholder

After the demo, drop a one-pager at `docs/retros/sprint-3-retro.md` matching the format of `docs/retros/sprint-2-retro.md`. Topics worth capturing:

- Parallel-agent collisions on a shared working tree (lesson: serialise OR isolate via worktrees).
- The audit pattern (security-reviewer ↔ flutter-engineer round-trip) — caught R-1 (cross-user queue drain), R-2 (id-discarding `.add()`), R-7 (default-online boot). Worth keeping for S4.
- The PR train: 13 PRs queued is large for one sprint; consider whether stacked PRs vs. a single integration branch fits the team better next time.
- The Drift chain in three sequential PRs (PR-1 schema → PR-2 sync → PR-3 cutover) was deliberately reviewable. Keep the pattern for future risky migrations.
