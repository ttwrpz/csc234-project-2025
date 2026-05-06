# Sprint 4 Retrospective — v1.0: Compassionate Reframing + Pattern Detection + Test Suite

**Sprint window:** May 6 – May 12, 2026 (5 working days)
**Demo readiness:** May 12, 2026
**Release tag:** `v1.0` on `main` at `d1eaa1df` (post-v1.0.1 hardening close — App Check enforcement on `analyzeMoodText` + restoration of the 60-min Remote Config `minimumFetchInterval`)
**Tag pushed:** Sprint 5 Day 1 (2026-05-13), retroactive — see §"What hurt" below.
**Authored:** Sprint 5 Day 1 background (per S5 plan §3 — finalized Day 3).

## Goal

> Ship the compassionate reframing (wilting plants + rain clouds), Gemini-powered pattern analysis with confidence labels, the repeat-pattern detector + 48h cooldown + 10-day escalation gate, the feature flag rollback rehearsal, dark mode, and the widget + golden + integration test suite. By end-of-sprint the app is the **v1.0 release**: every pivot feature except the cheer-up intervention itself is feature-complete.

**Result: shipped, with two notable gaps.** The compassionate reframing landed in full (wilting plants for negativeMild, rain clouds with self-fade for negativeStrong). Gemini pattern analysis, the repeat-pattern detector, dark mode, and the `feature-flag-rollback.md` runbook all landed. **Two acceptance criteria slipped:** the goldens-≥6 bar (only 3 golden test files committed; 7 PNG baselines), and the `v1.0` tag was never pushed at the demo (recovered retroactively at Sprint 5 Day 1).

## What landed (WBS reference)

24 commits on `main` between `v0.3-beta` and `d1eaa1df`. 141 files changed, +17,794 / -13,436 lines. Test count grew from 294 (S3) to **354** on the v1.0 head — domain coverage retained at ≥80% per `tool/check_domain_coverage.dart`.

| WBS | Feature | Branch | Status |
|---|---|---|---|
| 4.2 | Wilting plant + DayBloomKind extension for wilting/rain bucketing | `feat/4.2-wilting-plants` (PR #10) | ✅ |
| 4.3 | RainCloud widget + per-entry garden canvas + drift fade | `feat/4.3-rain-clouds` (PR #11) | ✅ Som's US-Som-1 acceptance met |
| 5.3 | `analyzePatterns` Cloud Function + `PatternInsightCard` + statistical-primary insights | `feat/5.3-5.4-pattern-detection` (PR #16) | ✅ ADR-0007 |
| 5.4 | Repeat-pattern detector (5-of-7 OR 3-consecutive ≥4) + 48h cooldown anchor + 10-day escalation flag | `feat/5.4-intervention-storage` (PR #17) | ✅ Pure-Dart; SharedPreferences anchor (S5 will Firestore-mirror per ADR-0008) |
| 6.2 | Dark-mode tokens + `buildDarkTheme` + theme controller + Settings extraction | `feat/6.2-dark-theme-day1` + `feat/6.2-dark-theme-day2` (PRs #12, #13) | ✅ |
| 7.2 | Test foundation — `golden_toolkit` + `pumpApp` helper + `@Tags(['golden'])` | `feat/7.2-test-foundation-rebased` (PR #14) | ✅ |
| 7.2 | Garden glyph goldens — wilting + rain + flower silhouettes | `feat/7.2-garden-goldens-day2` (PR #15) | ✅ |
| 7.3 | `integration_test/` scaffold + `PatternInsightCard` widget tests + 4 PatternInsight goldens | `feat/7.3-integration-tests` (PR #19) | ⚠️ scaffold only — auth_flow partially real, 3 stubs `skip: true` (S5 carry-over) |
| (d5) | Settings widget tests + light/dark goldens | `feat/d5-settings-tests` (PR #20) | ✅ |
| (d5) | CI golden test step + design_system test step | `feat/d5-ci-golden-step` (PR #21) | ✅ |
| (d5) | v1.0 Security Posture Report | `feat/d5-security-audit` (PR #22) | ✅ all HIGH/MEDIUM mitigated; v1.0.1 follow-ups tracked |
| (s4) | ADR-0006 (compassionate reframing) + ADR-0007 (statistical-primary patterns) + handoff brief | `feat/s4-adr-0006-0007` (PR #9) | ✅ |
| (s4) | Feature flag rollback runbook + 60-second `minimumFetchInterval` for v1.0 demo | `feat/5.3-runbook-and-demo-rc` (PR #18) | ✅ runbook landed; 60s interval restored to 60min in v1.0.1 |
| (v1.0.1) | App Check enforcement on `analyzeMoodText` + RC interval restoration | post-PR-22 hardening (commit `d1eaa1df`) | ✅ closes the v1.0 audit's open follow-ups |
| (deps) | Functions migrated to `@google/genai`; `pnpm` via corepack | (3 chore commits) | ✅ |

Plus 2 ADRs (`docs/adr/0006-compassionate-reframing.md`, `0007-pattern-analysis-fallback.md`), 1 handoff brief (`.claude/briefs/sprint-4/pattern-detection.md`), 1 security audit (`docs/security/audit-2026-05-12-v1.0.md`), 1 runbook (`docs/runbooks/feature-flag-rollback.md`).

## Sprint 4 acceptance criteria — checklist (with corrections)

- [x] Negative mood intensity 1–3 renders as wilting plant; intensity 4–5 renders as rain cloud — `flora_sprite.dart`, `rain_cloud.dart`
- [x] Rain clouds fade on their own within 15–25s with no user action — Som's US-Som-1 met
- [x] Analytics dashboard shows ≥1 Pattern Insight with visible confidence label and sample size — `PatternInsightCard` rendered by `analytics_screen.dart`
- [x] Flipping `ai_pattern_analysis_enabled` to `false` hides Insights within 60s; mood logging + history unaffected — verified at demo
- [x] `docs/runbooks/feature-flag-rollback.md` documented and rehearsed
- [x] Dark mode toggle works; every screen respects it; tokens swap correctly — verified across Garden, Log, History, Analytics, Settings
- [x] ≥6 widget test files — **EXCEEDED at 12** (`sign_in`, `sign_up`, `log_mood`, `intensity_slider`, `mood_type_grid`, `history`, `calendar_view`, `garden`, `weekly_bloom_bar`, `pattern_insight_card`, `settings`, `rain_cloud`)
- [ ] **Goldens for: empty garden, flower garden, wilting-plant garden, rain-cloud garden, analytics dashboard, insights card (low/med/high confidence) — ≥6 golden files**: ❌ **MISSED**. Only 3 golden test files (`pattern_insight_card_golden_test`, `rain_cloud_golden_test`, `settings_screen_golden_test`) with 7 PNG baselines total. Empty garden, flower garden, wilting-plant garden, and analytics dashboard goldens never landed. Carried into Sprint 5 plan §3a.2 — qa-engineer Day 3 closes this.
- [ ] **Integration test for login flow passes on Android emulator AND Chrome web**: ⚠️ partial. `auth_flow_test.dart` is partially real and runs locally on a connected device, but the cross-platform matrix doc (Android + Chrome) was deferred to the Sprint 5 7.4 QA track per the v1.0 audit §5.2. The four-flow integration suite remains scaffold + stubs.
- [ ] **Enterprise Audit Report draft started (covers Sections 1–4)**: ❌ **MISSED**. No `docs/audit/` directory exists at v1.0 head. The v1.0 security audit at `docs/security/audit-2026-05-12-v1.0.md` covers the security posture only; the broader Enterprise Audit Report — orchestration workflow, agent challenges, Plan Mode transcripts — was never authored. Carried into Sprint 5 plan §3a.1 — Theerawat begins Day 1 background, finalize Day 5.
- [ ] **Tag `v1.0` pushed after demo**: ❌ **MISSED**. The S4 demo ran on the candidate at commit `d1eaa1df` and was approved, but no annotated tag was pushed to origin. Recovered Sprint 5 Day 1 morning via `git tag -a v1.0 d1eaa1df -m "MoodBloom v1.0 — S4 release (post-audit, post-v1.0.1 hardening)" && git push origin v1.0`. Documented in S5 plan §3a.4.

## Test count at v1.0

**354 tests passing on `main`** (verified `flutter test` on 2026-05-13):

Bumped from S3's 294 by the v1.0 increment:
- `+pattern_detector_test.dart` — pure-Dart cooldown + escalation gates (PR #17)
- `+intervention_state_storage_test.dart` — SharedPreferences round-trip (PR #17)
- `+wilting_plant_test.dart` + `+rain_cloud_test.dart` — widget render assertions (PRs #10, #11)
- `+settings_screen_test.dart` + `+settings_screen_golden_test.dart` (PR #20)
- `+pattern_insight_card_golden_test.dart` (4 PNG variants) (PR #16)
- `+analyzePatterns.test.ts` — 11 server cases mirroring the analyzeMoodText pattern (PR #16)
- `+analyze_patterns_functions_datasource_test.dart` — 7 cases including the PII canary that asserts `text` and `mediaRefs` keys never leave the client (PR #16)

Domain coverage held: **≥80% on every feature**, ≥94.6% repo-wide per the v1.0 security audit §1. The pattern-detector add did not regress coverage — its 100% domain coverage was authored alongside the implementation.

## Open hardening items entering Sprint 5

Carried from the v1.0 security audit and the S3 → S4 unaddressed list:

| ID | Severity | Source | Owner | Status entering S5 |
|---|---|---|---|---|
| R-M01 | MEDIUM | v1.0 audit §1.3 + S3 retro | DevOps | Configure Firestore TTL on `rateLimits.expireAt` AND `rateLimits.patterns.expireAt` (the second collection landed in S4). Ops-only. |
| R-M02 | MEDIUM (closed in code) | S3 retro | DevOps | App Check enforcement: closed in code by the v1.0.1 commit `d1eaa1df`. IAM half — `gcloud secrets versions access GEMINI_API_KEY` from non-runtime principal must return 403 — remains DevOps. |
| R-3 | HIGH (deploy-only) | S3 retro | DevOps | `firebase deploy --only firestore:rules` confirmation. Ops-only. |
| R-4 | LOW | Drift audit (S3) | flutter-engineer | LWW `deviceId` tiebreak vs ADR-0005 in `mood_dao.dart` — never re-audited in S4. **Status verified Sprint 5 Day 1**: 48 Drift + sync tests pass at v1.0 head; the ADR-0005 alignment was effectively addressed by the Drift schema cleanup in PR #16's drive-by. Closed. |
| R-5 | LOW | Drift audit (S3) | flutter-engineer | `fakeAsync` test for `bootstrap()` 10s timeout — verified Sprint 5 Day 1: `mood_sync_manager_test.dart` includes a `bootstrap timeout` case. Closed. |
| R-6 | MEDIUM | Drift audit (S3) | architect | `drift_sqlcipher` encryption-at-rest decision. Out-of-scope for v1.5 per S5 plan §12; deferred to v2.0. |
| R-8 | LOW | Drift audit (S3) | flutter-engineer | `drift_dev schema dump` baseline for v1. Verified Sprint 5 Day 1: schema_v1 baseline present in `apps/mobile/lib/features/mood/data/local/`. Closed. |
| R-12 | LOW | Drift audit (S3) | flutter-engineer | Pre-resolve `sharedPreferencesProvider.future` in `main.dart`. Verified Sprint 5 Day 1: `main.dart` resolves SharedPreferences before `runApp` since the v1.0.1 commit. Closed. |
| R-016 | LOW | S2 audit | Theerawat | Web Google OAuth consent screen + `kIsWeb` gate. **Out-of-scope for v1.5** per S5 plan O10; deferred to v2.0. |
| R-001 | MEDIUM | Sprint 5 Day 1 PR #23 audit | flutter-engineer | FCM channel `cheer_up` declared in manifest but no `AndroidNotificationChannel` registered yet. Lands with the 5.5b PR (S5 plan §11 risk register). |

## What went well

- **Statistical-primary pattern analysis (ADR-0007).** The kickoff §High-risk #1 flagged Gemini hallucination risk on pattern output. Architect's Day-1 ADR-0007 pre-decided the fallback: `analyzePatterns` ships as statistical-primary (z-scores over weekdays, frequency over windows), and Gemini is a supplementary call clamped to confidence ≤0.7 with a 5s `AbortController` budget. When the v1.0.1 commit wired the Gemini supplementary call (per audit §1), the test suite already had 11 cases covering the failure modes (`gemini_unavailable`, `parse_error`, `sample_too_small`, `timeout`) — all non-fatal, all logged with `geminiSkipped: true`. The pattern that worked: pre-decide the rollback path before the integration risk surfaces.
- **Three-layer PII fence on `analyzePatterns`.** Client datasource projection (`projectEntry()` keeps only `{date, moodCode, intensity}`) + server Zod `.strict()` schema + server logger allowlist — verified by 18 unit tests including a substring canary against the original mood text. The PR-author + security-reviewer round-trip on `feat/5.3-5.4-pattern-detection` (PR #16) caught the second-layer regression early; the canary tests caught a third-layer drift in code review. **Pattern reusable for any S5 work touching personal text.**
- **Single-PR-per-feature integration approach.** S4 shipped 13 numbered PRs (`#8` through `#22`, plus the v1.0.1 follow-up commit) instead of a single integration PR à la S3. This worked because each feature's blast radius was narrow (`feat/4.2-wilting-plants` only touched `garden/presentation/widgets/`; `feat/6.2-dark-theme` only touched `design_system/` + `settings/`). No merge-conflict resolution playbook needed.
- **Feature flag rollback rehearsal as part of the demo.** `docs/runbooks/feature-flag-rollback.md` was authored alongside the lowered `minimumFetchInterval` (60s for the demo, restored to 60min in v1.0.1). The kickoff §High-risk #3 asked for the rehearsal to be live on stage; it was, and the v1.0.1 patch ticket was filed on the same day so the production-safe interval restoration didn't slip.
- **Domain-purity CI grep caught one drift early.** During PR #16 the analyze-patterns datasource was originally placed under `domain/`, which would have imported `cloud_functions`. The CI `Domain purity check` step at `ci.yml:157-165` failed the build with the expected error message. Author moved the file to `data/datasources/`, the import resolved, and the lesson stuck — no further drift across the rest of the sprint.

## What hurt

- **Goldens-≥6 acceptance bar missed.** The kickoff named six required golden scenarios (empty garden, flower garden, wilting-plant garden, rain-cloud garden, analytics dashboard, insights card low/med/high). PRs #15 and #16 landed `pattern_insight_card_golden_test.dart` (4 variants) and `rain_cloud_golden_test.dart` (1 variant); PR #20 added `settings_screen_golden_test.dart` (2 variants light/dark — not on the required list). Net: 4 of 6 required scenarios missing, plus 2 bonus scenarios. The miss was not flagged in the demo prep because the count-vs-coverage distinction wasn't checklisted. **Mitigation for S5:** plan §3a.2 spells out the four missing scenarios by file path + screen size matrix (360, 800, 1280) so qa-engineer Day 3 closes the bar without re-deriving the list.
- **`v1.0` tag never pushed.** The demo ran on `d1eaa1df`. Verbal "we're v1.0" was understood, but the annotated tag never reached origin. Discovered Sprint 5 Day 1 morning when the orchestrator ran `git tag -l` and saw only `v0.2-walking-skeleton` and `v0.3-beta`. **Recovery:** `git tag -a v1.0 d1eaa1df -m "..." && git push origin v1.0` on Sprint 5 Day 1, before any S5 commit. The v1.0 → v1.5 audit-report narrative now has a real anchor. **Mitigation for S5:** plan §11 risk #12 captures the tag commit choice; demo-day checklist will explicitly list `git tag -l` verification post-demo.
- **No `docs/audit/` directory at v1.0 head.** The kickoff acceptance bar listed "Enterprise Audit Report draft started (covers Sections 1–4)" but the artifact never landed. The v1.0 security audit at `docs/security/audit-2026-05-12-v1.0.md` is comprehensive on the security posture (8 findings, all mitigated) but is not the broader Enterprise Audit Report (orchestration workflow, agent challenges, Plan Mode transcripts) that the Enterprise Term Assignment R5 requires. **Mitigation for S5:** plan §3a.1 + §9 — Theerawat opens `docs/audit/enterprise-audit-report.md` Day 1 background; Day 5 finalize.
- **Integration test scaffold left three flows as `skip: true` stubs.** PR #19 landed the `integration_test/` scaffold with `auth_flow_test.dart` partially real, but `mood_log_history_flow_test.dart`, `ai_override_flow_test.dart`, and `pattern_intervention_stub_test.dart` shipped with empty bodies and `skip: true`. The v1.0 audit §5.2 explicitly noted "Sprint 4's local-only verification satisfies the acceptance bar; the device matrix lives in Sprint 5's CI track." That deferral was correct, but the in-doc note didn't propagate to the demo-day acceptance checklist — the integration-test row read as "passing" rather than "passing with three stubbed flows". **Mitigation for S5:** plan §3a.1 acceptance table marks the row as ⚠️ explicitly; plan §7 sequences the four flows across Day 1 (qa-engineer 7.3a — auth + mood-log/history) and Day 2 (qa-engineer 7.3b — ai-override + pattern-intervention).
- **Background-agent rate-limit exhaustion (continuing pattern from S3).** Several PRs (the d5 cluster especially — PR #20 + #21 + #22 landed back-to-back) hit Anthropic rate limits mid-flight, requiring orchestrator-foreground recovery. Estimated impact: ~25% of S4's wall-clock was orchestrator manually completing tasks the dispatched agent couldn't finish in one window. The S3 retro action item to "use `git worktree add ../<task-name> <branch>` for parallel agents" was not adopted in S4. **Mitigation for S5:** observed AGAIN in S5 Day 1 afternoon — both qa-engineer 7.3a and flutter-engineer 6.3 hit limits in the same window, with 6.3 producing partial work that had to be discarded. S5 plan §11 risk #9 + S5 retro will document; immediate corrective action: sequence agents instead of parallelizing on the same rate-limit pool.

## Action items entering Sprint 5

1. **flutter-engineer (S5 5.5b PR)** — register `AndroidNotificationChannel('cheer_up', ...)` client-side in the same change set that lands `sendCheerUpPush.ts`. Without this, Android 8+ silently drops the cheer-up push (R-001 from PR #23 audit).
2. **qa-engineer (S5 Day 3)** — author the four missing goldens (empty garden, flower garden, wilting-plant garden, analytics dashboard) at 360/800/1280 widths × light/dark. S5 plan §3a.2 has the exact file paths.
3. **Theerawat (S5 Day 1 background)** — author `docs/audit/enterprise-audit-report.md` skeleton with §1–8 headings; draft §1 Context and §2 Stack + architecture from CLAUDE.md and the ADRs. Day 5 finalize. Pre-decided fallback: Kraiwich writes §3 (Security Matrix), Jedsarit writes §4 (Observability + Rollback) if Theerawat slips.
4. **DevOps** — close R-M01 (Firestore TTL on both `rateLimits.expireAt` collections), R-M02 IAM (`gcloud secrets versions access` from non-runtime principal returns 403), R-3 (`firebase deploy --only firestore:rules` push confirmation). Documented in S5 plan §3a.5; not blocking code work.
5. **orchestrator** — adopt `git worktree add ../<task-name> <branch>` for any S5 dispatch that runs in parallel with another agent on a file-mutating task. The S5 Day 1 afternoon collision (both 6.3 + 7.3a writing to `feat/6.3-fcm-toggle`'s working tree) was the third occurrence of this failure mode (S3 D2.3+D2.4 collision; S4 d5 cluster rate-limit overruns; S5 D1 afternoon). The mitigation is no longer optional.
6. **orchestrator** — Sprint-5 demo checklist must explicitly include `git tag -l v1.5` verification after the tag step. The `v1.0` tag-was-not-pushed surprise must not repeat.

## What's NOT in v1.0 (out-of-scope per the kickoff)

These are deliberately deferred to S5 and beyond:

- **Cheer-up intervention loop** — banner widget + breathing overlay + hotline footer all SHIPPED as static UI in S4, but the cooldown-write, FCM push, and 10-day escalation anchor are S5 work (HB-003)
- **FCM notification toggle + permission flow** (S5 — WBS 6.3, HB-003)
- **Account deletion** (S5 — WBS 2.4, HB-004)
- **Cross-platform Android + Web QA matrix** (S5 — WBS 7.4)
- **Accessibility sweep** (S5 — WBS 7.4)
- **Performance profile** (S5 — WBS 7.4)
- **Final reports** — Enterprise Audit Report finalize, CSC231 Project Report, CSC234 UX/UI Report (S5 + post-sprint)
- **iOS build, Thai localization, event sourcing, therapist-facing export** (v2.0)
- **`drift_sqlcipher` encryption-at-rest** (v2.0 — R-6)
- **Web Google OAuth consent screen** (v2.0 — R-016)

## Reference

- v1.0 security audit: `docs/security/audit-2026-05-12-v1.0.md`
- ADR-0006 (compassionate reframing): `docs/adr/0006-compassionate-reframing.md`
- ADR-0007 (pattern analysis fallback): `docs/adr/0007-pattern-analysis-fallback.md`
- Feature flag rollback runbook: `docs/runbooks/feature-flag-rollback.md`
- Sprint 5 plan: `.claude/plans/refactored-growing-alpaca.md`
- v1.0 commit: `d1eaa1df` (`chore(v1.0.1): close v1.0.1 follow-ups — App Check + RC interval restoration`)
- v1.0 tag: pushed retroactively Sprint 5 Day 1 (2026-05-13) at `d1eaa1df`
