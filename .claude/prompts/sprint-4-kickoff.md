# Sprint 4 Kickoff — v1.0: Mood Score + Garden Ecosystem + Pattern Engine + Tokens

**Sprint window:** May 6 – May 12, 2026 (5 working days)
**Sprint goal:** Ship the ecosystem redesign foundation. Mood Score formula, Garden Health EWMA, Daily Atmosphere, Day/Night theme, Pattern Engine (5 algorithms), Weekly Harvest cycle, Token economy. By end-of-sprint the app is **v1.0**: pattern detection runs on every entry but does NOT fire interventions yet (that's S5). Plants NEVER die; harvest cycle works; tokens earned per log.

**Release target:** v1.0 tag after Sprint 4 presentation on May 12.

---

## Paste this prompt into Claude Code at start of Sprint 4

Orchestrator, your Sprint 4 plan is below. Enter Plan Mode. Produce the decomposition, then wait for my approval.

### Required reading before you plan

1. `CLAUDE.md` (root) — confirms the new ecosystem philosophy and copy rules.
2. `.claude/specs/sprint-4-5-spec.md` — the authoritative source for all formulas, data model, copy rules, and 41 test cases. **Read this in full before producing any plan.**
3. `docs/architecture/` — the updated conceptual + implementation diagrams showing the new Domain Engines layer.

### Context recap from Sprint 3

We tagged `v0.3-beta` at the Sprint 3 demo. Gemini mood detection works, offline-first reliable, Firestore rules pass emulator tests, biometric works on Android, line chart and calendar live. The OLD Sprint 3 design used "wilting plants for negative intensity 1–3 / rain clouds 4–5" — **this is replaced by the ecosystem model in S4–S5**.

**You (the team) already implemented most of Sprint 4 with Claude Code before the professor approved this redesign.** Your day-1 task is therefore: re-audit the existing S4 work against this new spec, identify what conforms and what needs revision, and triage the delta. Many bits of code may be reusable; the visual treatment is what changes most.

Sprint 4 is where the **ecosystem foundation lands**. Pattern Engine fires triggers internally but the user sees no notifications yet — Sprint 5 wires the Tiered Intervention dispatcher to FCM.

### Sprint 4 committed backlog (WBS IDs)

**Bucket 3 — Mood scoring:**
- 3.6 Mood Score formula `S_t = v × i/5` (pure-Dart domain function + unit tests)

**Bucket 4 — Garden ecosystem:**
- 4.2 Garden Health EWMA + 5 plant-state tiers (NEVER dead) — H_t = 0.15·S_t + 0.85·H_{t-1}
- 4.3 Daily Atmosphere system (avg_S_today → sunny/calm/light-rain/storm — plants always sheltered)
- 4.4 Day/Night theme setting (Follow device theme / Follow device time)

**Bucket 5 — Pattern detection:**
- 5.3 Pattern Engine: 5 algorithms (Mann-Kendall, sliding 5-of-7, 3-consecutive, Z-score, CUSUM)

**Bucket 6 — Garden mechanics:**
- 6.1 Weekly Harvest cycle: archive garden, weekly summary screen, history page
- 6.2 Token system (5–10/day cap, mood-agnostic, never lost, cosmetic-only)

**Bucket 7 — UI:**
- 7.2 Dark mode toggle (system default)

**Bucket 8 — Testing:**
- 8.2 Widget + golden tests for major screens (incl. all atmosphere states, plant tiers)

**Bucket 9 — Reporting:**
- 9.1 Enterprise Audit Report draft (Theerawat, parallel)

### Sprint 4 critical path (from PDM)

O (Mood Score, 0.5d) → R (Pattern Engine, 2.5d) → [carries into S5]

Parallel tracks:
- P (Garden Health EWMA, 1.5d) and Q (Atmosphere, 1.5d) both depend on O and run in parallel.
- S (Weekly Harvest, 2.0d) depends on P + Q.
- T (Tokens, 1.0d) depends on S.
- U (Day/Night + Dark mode, 1.0d) is independent.

### Day-by-day plan

**Day 1 (May 6) — re-audit + Mood Score**
- Day-0 0.5-day spike: `architect` audits existing S4 code against `.claude/specs/sprint-4-5-spec.md`. Output: triage list (keep / revise / delete).
- `architect` writes ADR-0006 on the ecosystem model decision (cite Neff 2003, Linehan 1993, Hayes 1999, White 1990).
- `flutter-engineer` implements Mood Score `S_t = v × i/5` (3.6) — pure-Dart in `features/mood/domain/`. Write 4 unit tests covering examples in spec section 2.1.
- `architect` writes handoff brief for Pattern Engine (5.3) — must cover all 5 algorithms with formulas from spec section 2.4.

**Day 2 (May 7) — EWMA + Atmosphere**
- `flutter-engineer` implements Garden Health EWMA (4.2): pure-Dart in `features/garden/domain/`, α=0.15, weekly H_0 reset. Maps H_t to 5 plant tiers (Flourishing/Thriving/Resting/Weathering/Storm Season — ALL alive).
- `flutter-engineer` implements Atmosphere engine (4.3) in parallel: pure-Dart, computes avg_S_today, maps to weather. Resets midnight.
- `flutter-engineer` writes widget tests for plant tier rendering — golden tests for all 5 tiers showing plants visibly alive in every one.
- `flutter-engineer` starts Pattern Engine algorithms 1–2 (Mann-Kendall + Sliding 5-of-7).

**Day 3 (May 8) — Pattern Engine completion**
- `flutter-engineer` finishes Pattern Engine: 3-consecutive, Z-score, CUSUM (algorithms 3–5).
- `qa-engineer` writes unit tests for all 5 algorithms — must cover the worked examples in spec section 2.4. Critical: assert algorithm outputs match expected Z values to 2 decimal places.
- `flutter-engineer` implements Daily Atmosphere visual (4.3) — 4 weather states. Plants always sheltered in storm.

**Day 4 (May 11) — Harvest + Tokens + Day/Night**
- `flutter-engineer` implements Weekly Harvest cycle (6.1): archive logic, weekly summary screen, history page. **Strict copy review:** never use "delete," "clear," "reset" — only "harvest," "complete," "new chapter."
- `flutter-engineer` implements Token system (6.2) in parallel: 5–10/day cap, mood-agnostic earning, never-lost. Test: logging "Sad intensity 5" earns same as "Joy intensity 5."
- `flutter-engineer` implements Day/Night theme + Dark mode (4.4, 7.2).
- `Theerawat` (Project Lead) starts Enterprise Audit Report draft (9.1) in parallel.

**Day 5 (May 12 — presentation day)**
- `qa-engineer` runs the Sprint 4 test suite. All 25 of the Token/Harvest/Atmosphere/EWMA/Pattern test cases (spec section 7, items 1–5 + 11–30) must pass.
- `security-reviewer` audits: no Gemini calls in pattern-detection path (algorithms run client-side); Firestore rules updated for new collections (`weeklyGardens`, `patterns`, `cooldowns`).
- Merge everything green. Tag `v1.0`.
- Demo: log a sad mood at intensity 4 → S_t = -0.8 → atmosphere becomes light rain → plants stay sheltered. Day 5 of week → tap History → see week's harvest archive. Token balance shows accumulated. Pattern Engine has fired internal triggers (logged but not surfaced — Tier 1 ready to dispatch in S5).

### High-risk items requiring your attention

1. **Pattern Engine (5.3)** — widest PERT spread. 5 algorithms with academic-grade math. Errors here cascade into wrong intervention triggers. Mitigation: pair Kraiwich + Theerawat day-1 spike to validate each formula's output against spec section 2.4 worked examples.

2. **Plants-never-die compliance** — every visual asset and animation must be reviewed. If anything in any tier looks wilting, dying, or destroyed → reject and redesign. The "Storm Season" tier especially: rain falls, but plants are sheltered — lanterns brighter, leaves intact.

3. **Copy rule enforcement on Harvest** — `qa-engineer` greps every user-facing string in `features/harvest/` before merge. Any occurrence of "delete," "clear," "reset" is a blocker.

### Acceptance criteria (Sprint 4 demo)

From `.claude/specs/sprint-4-5-spec.md` Part 7. The following test cases must all pass before merging the v1.0 tag:

**Token System (TC 1–5):**
- [ ] TC-1: User logs mood → receives 5–10 tokens within daily cap.
- [ ] TC-2: "Joy intensity 5" earns same tokens as "Sad intensity 5" (mood-agnostic).
- [ ] TC-3: 10 tokens reached → additional logs earn no more.
- [ ] TC-4: Token counter resets at midnight.
- [ ] TC-5: Missed day → no tokens lost, no streak broken.

**Weekly Harvest (TC 11–15):**
- [ ] TC-11: After 7 days → garden archives, new garden starts H_0 = 0.
- [ ] TC-12: Archived garden viewable in History.
- [ ] TC-13: Tap a flower in archived garden → original mood entry shown.
- [ ] TC-14: Weekly Summary screen appears with correct stats.
- [ ] TC-15: User-facing copy NEVER says "delete/clear/reset."

**Atmosphere (TC 16–20):**
- [ ] TC-16: 1 positive (S=+0.8) + 1 negative (S=-0.4) → avg=+0.2 → positive atmosphere.
- [ ] TC-17: Atmosphere resets at midnight.
- [ ] TC-18: Storm shows plants sheltered, NEVER dead.
- [ ] TC-19: Day/night theme matches device when "Follow device theme" selected.
- [ ] TC-20: Day/night theme matches local time when "Follow device time" selected.

**Garden Health EWMA (TC 21–24):**
- [ ] TC-21: H starts at 0 for new week.
- [ ] TC-22: Joy intensity 4 → H = 0.12.
- [ ] TC-23: One bad day from H=+0.4 → H still +0.19, NOT crashed.
- [ ] TC-24: Plants alive in EVERY tier including Storm Season.

**Pattern Detection (TC 25–30):**
- [ ] TC-25: 5/7 negative days → Tier 2 trigger fires (logged, not surfaced this sprint).
- [ ] TC-26: 3 consecutive S ≤ -0.6 → Tier 3 trigger fires.
- [ ] TC-27: Mann-Kendall on declining 5-day window → Z = -2.21 → Tier 1 trigger.
- [ ] TC-28: Z-score: μ_30=+0.3, today=-0.9 → z_day flagged.
- [ ] TC-29: CUSUM crosses threshold → Tier 3 trigger.
- [ ] TC-30: Pattern detection works across week boundaries (sliding windows do NOT reset on harvest).

### Out of scope for Sprint 4 (do not start these)

- Tiered Intervention dispatcher (S5)
- FCM notification dispatch on triggers (S5)
- Quote Library (S5)
- Bipolar disclaimer service (S5)
- Insights screen (S5)
- Skin system (S5)
- Account deletion (S5)
- Cross-platform QA, a11y, performance (S5)
- Final reports (S5)

### Now enter Plan Mode

Produce the plan, ADR-0006 (ecosystem decision with citations), and the handoff brief for Pattern Engine. Wait for my approval. Do not write production code until I approve.
