# Sprint 4 Demo & Retrospective — v1.0

**Sprint window:** May 6 – May 12, 2026 (5 working days)
**Demo date:** May 12, 2026
**Release tag:** `v1.0` (`feat/s4-redesign-foundation` tip `c26d9716`); polish carryover tagged `v1.0-polish` at `716b6f81`
**Team:** Kraiwich Jaiton, Teerin Kittichaicharoen, Theerawat Patthawee (Lead), Jedsarit Fanpimiy, Napat Chang-ekwong

---

## 1. What we shipped (v1.0)

Sprint 4 implemented the ecosystem redesign that resolved the professor's post-Sprint-3 feedback (the user-driven pivot from "wilting plants for negative moods" to "plants never die, every mood is weather"). Twelve in-scope work breakdown items landed, each mapped to a single PR:

| WBS | Feature | Branch |
|---|---|---|
| 3.6 | Mood Score `S_t = v × i/5` (pure-Dart domain function, range `[-1, +1]`) | `feat/3.6-mood-score` |
| 4.2 | Garden Health EWMA `H_t = 0.15 S_t + 0.85 H_{t-1}` with weekly reset to `H_0 = 0` | `feat/4.2-ewma` |
| 4.3 | Daily Atmosphere (sunny / calm / light-rain / storm) driven by `avg_S_today`, resets midnight | `feat/4.3-atmosphere` |
| 4.4 | Day/Night theme — follow-device-theme + follow-device-time strategies | `feat/4.4-day-night` |
| 5.3 | Pattern Engine — five pure-Dart algorithms (Mann–Kendall, sliding 5-of-7, three-consecutive, z-score, CUSUM) firing internally on every entry | `feat/5.3-pattern-engine` |
| 6.1 | Weekly Harvest cycle — every seven days the garden archives to History with copy "harvest / complete / new chapter" (never "delete / reset / lost") | `feat/6.1-harvest` |
| 6.2 | Token economy — mood-agnostic earning, 5–10 tokens/day cap, no streak punishment, cosmetic-only spending | `feat/6.2-tokens` |
| 7.2 | Dark mode polish across S2–S4 surfaces | `feat/7.2-dark-mode` |
| 8.2 | Widget + golden test top-up — 24 golden tests under a 4% pixel-tolerance window | `feat/8.2-widget-tests` |

The Pattern Engine fires triggers internally but no notification surfaces yet — that is Sprint 5's safety-net wiring, gated in v1.0 by `interventionDispatchEnabled = false`.

ADR-0010 ("Ecosystem model — plants never die") and ADR-0011 ("Client-side Pattern Engine") accompany the redesign; both are accepted on 2026-05-12.

## 2. Demo flow on May 12

1. Open a clean install on a Pixel 6 emulator. Log a Joy entry at intensity 4 → see flower bloom on Garden bed → see Mood Score `+0.8` reflected in the Patterns chart.
2. Log a Sad entry at intensity 5 → Garden Health drops `|ΔH| ≤ 0.15` (TC-23 invariant — one bad day cannot crash the canvas); Daily Atmosphere shifts from sunny to overcast.
3. Switch to the Patterns tab → line chart re-renders with the new entry; the placeholder Pattern Insight card displays the most recent algorithm trigger ("Mann–Kendall: gradual decline detected").
4. Cycle Garden Health through all five plant tiers via Settings → Debug → "Cycle plant tier" (`debugPlantTierOverrideProvider`) — Flourishing / Thriving / Resting / Weathering / Storm Season. Every tier shows **alive** plants (TC-24).
5. Toggle dark mode → all five tiers render with WCAG 2.2 AA contrast in dark theme.
6. Trigger the weekly harvest via Settings → Debug → "Force harvest now" → the active week archives to History; new week starts with `H_0 = 0`; banner reads "A fresh canvas for your story." (TC-15 copy rule).

## 3. Test results

Tip-of-branch verification at `c26d9716`:

- `flutter test`: **664 / 664 passed.** Domain coverage 94.6% overall; every feature ≥80% (Enterprise R1 gate).
- `flutter test --tags=golden`: **24 / 24 passed.** Pixel deltas all within the declared 4% tolerance.
- `flutter analyze`: clean (one pre-existing unrelated info-level lint, untouched).
- `dart format --set-exit-if-changed`: clean.
- Domain-purity grep on `apps/mobile/lib/features/*/domain/`: 1 documented exception (`features/settings/domain/services/day_night_strategy.dart`, ADR-0010 whitelist).
- Mood-agnostic grep on `apps/mobile/lib/features/tokens/`: empty — the load-bearing invariant holds.

Per-spec acceptance (`.claude/specs/sprint-4-5-spec.md` §7):

| Group | TCs | Result |
|---|---|---|
| Token System | TC-1 .. TC-5 | 5 / 5 pass |
| Weekly Harvest | TC-11 .. TC-15 | 5 / 5 pass |
| Atmosphere | TC-16 .. TC-20 | 5 / 5 pass |
| Garden Health EWMA | TC-21 .. TC-24 | 4 / 4 pass |
| Pattern Detection | TC-25 .. TC-30 | 6 / 6 pass (TC-27's Mann–Kendall quantization deviation approved by architect; see acceptance audit §"Mann–Kendall quantization") |

**Out of scope for v1.0 (deferred to Sprint 5):** TC-6..TC-10 (Skin system), TC-31..TC-39 (Intervention notifications + Bipolar disclaimer), TC-40..TC-41 (Tier 3 determinism).

## 4. What went well

- **Architect-front-loaded ADRs paid off again.** ADR-0010 + ADR-0011 were drafted at sprint kickoff; the five Pattern Engine algorithms each got a worked-example test in the same PR as the algorithm, with zero design-question round-trips between agent and architect mid-sprint.
- **The ecosystem-model pivot was finishable in five days because the formulas were precise.** `S_t = v × i/5` and `H_t = 0.15 S_t + 0.85 H_{t-1}` are unambiguous; the team did not waste time arguing about thresholds or normalization choices — the spec made them.
- **Golden-test discipline scaled.** Twenty-four goldens across the five plant tiers, four atmospheres, and shared `daily_score_strip` + `cheer_up_banner` widgets all passed within 4% tolerance even after the polish-round animation pass. The deterministic-phase trick (`animate: false` in tests) is repeatable for future visual work.

## 5. What was hard

- **Mann–Kendall's quantization deviation.** The spec said Z ≈ −2.21 for the declining 14-day series. The integer-valued `S` makes Z quantized; the closest reachable values were −2.190 and −2.2445, both outside the spec's ±0.005 tolerance. The team approved a deviation: ±0.05 instead. **Lesson for future spec authors:** if the algorithm is integer-valued, write the tolerance accordingly.
- **The Bangkok Firestore region surprise.** `sendCheerUpPush` could not deploy to `asia-southeast3` as a Firestore v1 or v2 trigger; the validator rejected both. The polish round converted it to `onCall` so the client invokes explicitly after writing the audit doc. **Lesson:** read the region availability matrix at the architecture-decision stage, not 24 hours after the v1.0 push.
- **Parallel agents on a shared working tree collided.** Two background agents on Day 2 (3.3 image picker + 4.1 garden canvas) hit the same checkout. Recovery cost 30 minutes. **Lesson** (since adopted as memory `[[workflow_parallel_agent_dispatch]]`): file-mutating Agent dispatches default to `isolation:"worktree"`; sequence them on a shared rate-limit pool.

## 6. What the human team caught that the agents missed

This section feeds the Enterprise audit report.

- **"After wipe the data the garden still shows 3 flowers."** The old `PlantTierGroup` painted 3 buds unconditionally on the Resting state. Empty `entries` should paint ground+grass only; the user-test pass surfaced the ghost flowers on first wipe. Fix: new `GardenBed` widget. No agent caught this; the user did.
- **"Rain only fills half the canvas."** The `AtmosphereOverlay` was wrapped around the 140 dp bed instead of `Positioned.fill` over the 320–420 dp SkyHeader. The agent had correctly implemented the formula but composited the overlay to the wrong slot.
- **"5 stray yellow-orange ray lines on the canvas."** A `_paintSunRays` helper from a prototype committed by mistake. The sky gradient + sun circle already carry the brightness signal; the rays were noise.
- **"AI text analyze fires on 2–3 char drafts."** `aiSuggestionMinCharsProvider` added (default 12) to gate the Cloud Function call. The agent had no concept of input-debounce; only user testing surfaced the wasted Gemini call.

## 7. Going into Sprint 5

The pivot is shipped; the safety net is not yet wired. Sprint 5 will surface the Pattern Engine triggers as Tiered Intervention notifications (Tier 1 breathing / Tier 2 journaling / Tier 3 crisis), build the Quote Library with the Safety Filter + curated Tier 3 pool, and ship the Bipolar/medical disclaimer service. The cooldown infrastructure (`cheer_up_events` collection + `sendCheerUpPush` CF) ships in v1.0 but is gated off via the `interventionDispatchEnabled` flag.
