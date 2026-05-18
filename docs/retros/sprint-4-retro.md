# Sprint 4 Retrospective — Ecosystem Redesign (v1.0)

**Sprint window:** May 6 – May 9, 2026 (4 working days)
**Tag:** `v1.0` (the redesign supersedes the pre-redesign `v1.0` per the release-notes tag-collision notice)
**Tip:** `4213a6f9` on `feat/s4-redesign-foundation`
**Companion docs:** `docs/release-notes/v1.0-redesign.md`, `docs/audit/sprint-4-redesign-audit.md`, `docs/audit/sprint-4-v1.0-acceptance.md`, `docs/security/audit-2026-05-12-v1.0-redesign.md`, `docs/adr/0010-ecosystem-model-plants-never-die.md`, `docs/adr/0011-client-side-pattern-engine.md`, `docs/retros/v1.0-polish-retro.md` (the May 10 user-testing iteration on top of this sprint).

## Goal

> Replace the wilting-plants + rain-cloud visual taxonomy and the Cloud-Function-driven 2-rule trigger with an evidence-grounded ecosystem model in which plants are alive in every state, mood scoring is bounded and intensity-aware, and pattern detection runs entirely client-side as pure-Dart functions.

**Result: shipped v1.0 on schedule.** 664 / 664 Flutter tests + 24 / 24 goldens + 40 / 40 Cloud Function tests pass at tip. 25 in-scope acceptance test cases from spec §7 (TC-1..TC-30 minus the S5-out-of-scope) accepted by the architect. Two ADRs (0010 + 0011) and three handoff briefs (HB-004, HB-005, HB-006) front-loaded the work.

## What landed

1. **Mood Score `S_t = v × i/5`** — pure-Dart per-entry scalar in `[-1, +1]`. Joy/Calm/**Okay** = +1; Sadness/Anger/Anxiety = −1. The "Okay" sign flip is documented and accepted as a retroactive change (ADR-0010 §2 trade-off).
2. **5 plant tiers, all visibly alive** — Flourishing / Thriving / Resting / Weathering / Storm Season. Driven by EWMA `H_t = 0.15·S_day + 0.85·H_{t−1}`, weekly `H_0 = 0`. Storm Season renders rain falling *around* a sheltered garden — plants intact, lanterns brighter.
3. **4 daily atmosphere states** — calmSunny / brightSunny / lightRain / storm. Driven by `avg_S_today`. Resets at local midnight. Decoupled from plant tier in code and z-order.
4. **5-algorithm Pattern Engine** running client-side as pure-Dart: Mann-Kendall trend test (14-day window, Z < −1.96 → Tier 1), sliding 5-of-7 negative days (→ Tier 2), 3-consecutive S ≤ −0.6 (→ Tier 3), z-score vs personal 30-day baseline (z_day < −2.5 → Tier 3), CUSUM change-point (→ Tier 3).
5. **Pattern results document** at `users/{uid}/patterns/{date}` — numeric outputs + resolved tier only; no mood text (PII guard).
6. **Weekly Harvest cycle** — write-once archive to `users/{uid}/weeklyGardens/{weekId}` at the close of every 7-day window; H_0 resets to 0; past weeks browsable in a new History tab.
7. **Mood-agnostic token economy** — 5 for the day's first log + 1 per additional up to 10/day; missed days lose nothing; verified by a file-level grep test that `award_daily_tokens.dart` references no `MoodType` / `MoodEntry` / `MoodScore` symbol.
8. **Day/Night theme** — new fourth `ThemeModePreference.followDeviceTime` flips light/dark on local-clock cutoffs (07:00 / 19:00). Backward-compatible storage migration.

## What went well

- **Plan-first discipline scaled.** Two ADRs (0010 ecosystem model, 0011 client-side Pattern Engine) and three handoff briefs (HB-004 pattern-engine, HB-005 harvest-tokens-daynight, HB-006 day-3 follow-up) were authored before any code. Implementation agents had zero architectural questions mid-sprint.
- **Algorithm-as-pure-Dart was the right call.** ADR-0011's decision to pull pattern detection out of Cloud Functions and into pure-Dart `features/pattern_engine/domain/algorithms/` made every algorithm directly unit-testable, removed a latency layer, and eliminated a PII-leak surface. Mann-Kendall, sliding-5-of-7, three-consecutive, z-score, CUSUM each got their own focused test file (47 tests in `pattern_engine/`).
- **Daily atmosphere decoupled from plant tier in code.** Two separate pure-Dart services, two separate Riverpod providers, two independent paint layers. No state-leak between "this day's weather" and "this week's health." Future-proofs the next visual iteration.
- **Storm-without-wilting is enforced architecturally.** Storm atmosphere paints rain around plants, not on plants. Plants paint *first* in the canvas's paint order; rain is a sibling `Positioned.fill` overlay. The TC-24 banned-vocabulary grep over `features/garden/` runs in CI and is empty.
- **Mood-agnostic tokens are enforced by grep, not by convention.** `award_daily_tokens.dart` is forbidden from importing `MoodType`, `MoodEntry`, or `MoodScore`. The grep test fails the build if any of those symbols appear. This is the load-bearing invariant for the gamification-ethics chapter.

## What was hard

- **Mann-Kendall quantization** — spec §7.27 prescribes Z = −2.21 ± 0.005 on a steadily-declining 14-day window. The S statistic is integer-valued; the closest reachable values are −2.190 (S=−41) and −2.2445 (S=−42), neither inside the spec's tolerance. Architect amended the tolerance to ±0.05 in ADR-0011 Consequences. The user-facing tier-trigger semantics (Z < −1.96) are unchanged.
- **EWMA α choice was contested.** Spec §2.2 fixes α = 0.15. The sprint floated α = 0.20 for a more responsive canvas; the architect ruled in favour of the spec's α = 0.15 because Smit et al. 2022 derives it from autocorrelation parameters at lag-1 typical of daily mood time series. The bounded daily delta `|ΔH| ≤ 0.15` is what guarantees one bad day cannot crash the canvas.
- **Bangkok Firestore region restriction** — `sendCheerUpPush` initially deployed as `onDocumentCreated` to `asia-southeast3`. The region does not support Eventarc v2 triggers. Cost 2 hours in the polish round (May 10); resolved by converting to `onCall` and invoking `httpsCallable('sendCheerUpPush')` after writing the audit doc.
- **Day/night theme storage migration** — the `ThemeModePreference` enum added a fourth value. Existing users on `system` / `light` / `dark` already had a string-encoded preference in `users/{uid}/settings/theme`. Migration is read-side: missing or unknown values default to `system`. Tested by re-running the auth-restore widget tests with synthetic legacy values.

## What the human team caught

- **The S statistic quantization on TC-27** would have shipped with a flaky-looking test pinned to spec values that the algorithm cannot mathematically reach. The architect's amendment closed the gap before tag.
- **A draft of HB-006 originally proposed merging the atmosphere and plant-tier providers** to "simplify" the Riverpod graph. The orchestrator flagged the cross-concern coupling; HB-006 was revised to keep them separate. The subsequent v1.0 polish round (May 10) gated rain on tier in a *presentation*-layer helper `_atmosphereForTier`, exactly because the domain-layer decoupling was preserved.
- **The "Okay" sign flip** (Okay reclassified as +1 in the redesign, was −1 in S1–3 implicitly) was originally a silent change. Architect inserted it explicitly into ADR-0010 §2 trade-off list so the migration-notes section of the release notes had something to point at.

## Going into Sprint 5

The Sprint 5 kickoff inherits five concrete handoffs from this sprint:

1. The Pattern Engine writes `patterns/{date}.triggeredTier` on every mood log; the dispatcher path is gated behind `interventionDispatchEnabled = false`. **S5 flips the flag** and points the dispatcher at the new tier field.
2. `users/{uid}/interventions/{id}` and `users/{uid}/cooldowns/{type}` collections are pre-allowlisted in Firestore rules with deny-all writes in v1.0. **S5 lights up writes** with field-level `diff().affectedKeys()` validation.
3. `users/{uid}/insightsDisclaimerAcked: bool` (default `false`) is on the user profile. **S5 wires the ack dialog** on first Insights view, with the one-way `false→true` immutability fence in rules.
4. **TC-31..TC-41 are deliberately out of scope** for v1.0. S5 owns: Skin system (TC-6..TC-10), Intervention Notification surface (TC-31..TC-35), Bipolar Disclaimer (TC-36..TC-39), Tier 3 Determinism (TC-40..TC-41).
5. **TC-27 tolerance amendment** is the only spec deviation; spec §2.4 + §7.27 should be amended in the next spec revision.

## Sprint metrics

- **Working days:** 4
- **Commits on `feat/s4-redesign-foundation`:** 15 between `52f98a65` and `4213a6f9`
- **PRs:** 12 (one per WBS task) + 1 polish round (33 discrete tasks on May 10, see `v1.0-polish-retro.md`)
- **Tests added:** 370 (664 total at v1.0; 736 at v1.0-polish)
- **Golden tests:** 24 (4% pixel tolerance)
- **Domain coverage:** every feature ≥80%; garden/domain at 96.4%; mood/domain at 95.4%
- **ADRs:** 2 (0010 ecosystem model, 0011 client-side Pattern Engine)
- **Handoff briefs:** 3 (HB-004, HB-005, HB-006)
- **Agent invocations:** ~50 total (architect ×6, flutter-engineer ×30, qa-engineer ×8, security-reviewer ×6)
- **Human-team interventions:** Bangkok region rejection (2 h, polish round), the S-quantization deviation (15 min architect ruling)

## Lessons carried forward to Sprint 5

- Always write the ADR before the code. ADR-0010 + ADR-0011 paid for themselves the first time an agent asked "should Storm Season use a separate atmosphere or piggy-back on the tier?" — the answer was already written.
- File-level grep tests for cross-cutting invariants (mood-agnostic tokens, banned-vocabulary, plants-never-die). The cost is trivial, the protection is structural.
- Pure-Dart algorithms over CF where latency + PII + testability all argue for client-side. Tier 3 determinism in S5 will follow the same pattern.
- Budget a user-testing pass between every release-candidate and tag. The May 10 polish round closed ~30 issues that the agent team did not surface on their own.
