# Sprint 5 Kickoff — v1.5: Tiered Intervention + Quote Library + Disclaimer + Final QA

**Sprint window:** May 13 – May 19, 2026 (5 working days)
**Sprint goal:** Wire the safety net live. Tiered Intervention dispatcher (Tier 1/2/3 with cooldown + opt-out), personalized Quote Library (Tier 3 = curated only, deterministic), Bipolar/medical disclaimer service, Insights screen with mandatory ack, FCM toggle, Skin system, account deletion, full cross-platform QA + accessibility + performance + final reports. v1.5 is the final release.

**Release target:** v1.5 tag after Sprint 5 presentation on May 19.

---

## Paste this prompt into Claude Code at start of Sprint 5

Orchestrator, your Sprint 5 plan is below. Enter Plan Mode. This is the highest-stakes sprint of the project — Tier 3 messages must be byte-for-byte deterministic. Read carefully.

### Required reading before you plan

1. `.claude/specs/sprint-4-5-spec.md` — sections 3 (Quote Library Architecture), 4 (Bipolar Disclaimer), 7 (Test Cases — items 31–41 are S5-critical).
2. `CLAUDE.md` — confirms Tier 3 NEVER calls Gemini and disclaimer placement (b)+(c) combined.
3. `docs/architecture/` — implementation diagram showing the Tier 3 → Quote Library DIRECT path and the Quote Safety Filter as a fail-closed chokepoint for Tier 1/2.

### Context recap from Sprint 4

We tagged `v1.0` at the Sprint 4 demo. Mood Score formula works. Garden Health EWMA shifts smoothly (≤0.15/day). Atmosphere weather-states render correctly with plants always alive. Pattern Engine fires triggers internally on every entry — but no notifications surface yet. Weekly Harvest cycle archives gardens with strict "harvest/complete/new chapter" copy. Token economy works mood-agnostic. Day/night theme + dark mode work.

**Sprint 5 wires the safety net live.** This is where the app becomes therapeutically functional.

### The Tier 3 absolute rule — read this carefully

**Tier 3 messages NEVER call Gemini. EVER.**

Tier 3 fires when the user is at their most vulnerable: 3 consecutive S ≤ -0.6, or a Z-score crash (z_day < -2.5), or a CUSUM change-point breach. At that moment, a wrong message could cause real harm. Determinism is non-negotiable.

Implementation rule: the `TieredInterventionDispatcher` has a hard branch on `tier == InterventionTier.tier3`. The tier-3 branch goes to `QuoteLibrary.curatedTier3Pool` directly — no `AIQuoteRepository`, no Cloud Function call, no Gemini. Test 40 in the spec asserts this with a Gemini-mock that fails the test if invoked from Tier 3.

Tier 1 and Tier 2 are different — they use the Gemini hybrid path, but every Gemini suggestion goes through the `QuoteSafetyFilter` first. Filter is fail-closed: any forbidden word, length over cap, or off-script phrasing → reject Gemini, fall back to curated phrase.

### Sprint 5 committed backlog (WBS IDs)

**Bucket 2 — Security cleanup:**
- 2.4 Account deletion with full Firestore + Storage cleanup

**Bucket 5 — Tiered Intervention + Quote Library + Insights:**
- 5.4 Tiered Intervention dispatcher (Tier 1 breathing / Tier 2 journaling / Tier 3 crisis) + cooldown + opt-out
- 5.5 Personalized quote library + Gemini hybrid for Tier 1/2 ONLY (Tier 3 = curated only, deterministic)
- 5.6 Insights screen with pattern visualizations + bipolar disclaimer ack-on-first-use

**Bucket 6 — Skin system:**
- 6.3 Flower skin system + per-flower modal + spend confirmation

**Bucket 7 — Notifications + Disclaimer:**
- 7.3 FCM notification toggle + permissions + per-tier opt-out
- 7.4 Bipolar/medical disclaimer service: notification footer + Insights ack dialog + Settings restate

**Bucket 8 — QA:**
- 8.3 Integration tests (login, mood, AI override, harvest, all 3 intervention tiers)
- 8.4 Cross-platform QA (Android+Web) + a11y + performance

**Bucket 9 — Reports:**
- 9.1 Enterprise Audit Report finalize
- 9.2 CSC231 + CSC234 reports + evidence package

### Sprint 5 critical path (from PDM)

W (Tiered Intervention, 1.5d) → X (Quote Library, 1.0d) → Y (Disclaimer + FCM, 1.0d) → AC (Integration tests, 2.0d) → AD (Cross-platform QA, 1.5d) → AE (Reports, 1.0d) → [day 19.5 of 20]

Parallel tracks:
- AA (Skin system, 1.5d) on Napat in parallel with W/X/Y.
- AB (Account deletion + Audit draft) carries over from S4.

### Day-by-day plan

**Day 1 (May 13) — Tiered Intervention dispatcher**
- `architect` writes the canonical handoff brief for Tiered Intervention (5.4). Specify: dispatcher state machine, cooldown persistence (`users/{uid}/cooldowns/{type}` Firestore), opt-out flow, "I'm okay" button, three tier paths.
- `flutter-engineer` implements `TieredInterventionDispatcher` in `features/intervention/domain/`. Must be pure-Dart. Hard branch on `tier == tier3 → curated path`.
- `flutter-engineer` implements `CooldownGuard` — 48h between dispatches, max 1/day. Persist to Firestore.
- `flutter-engineer` (Napat) implements Skin system (6.3) in parallel — token spending, modal UI.

**Day 2 (May 14) — Quote Library + Disclaimer + FCM**
- `flutter-engineer` implements `QuoteLibrary` with curated Tier 3 pool (8–12 entries, team-reviewed). Tier 1 + Tier 2 curated pools (12 entries each).
- `flutter-engineer` implements `QuoteSafetyFilter`: whitelist-based + forbidden-word blacklist + length cap. Fail-closed.
- `flutter-engineer` implements `AIQuoteRepository` for Tier 1/2 hybrid path. Calls Cloud Function `suggestQuote.ts`. Routes Gemini output through Safety Filter before returning.
- `flutter-engineer` implements Bipolar Disclaimer Service (7.4): footer attachment, ack dialog component, Settings restate page.
- `flutter-engineer` implements FCM toggle (7.3): permission request, per-tier opt-out switches in Settings.
- `flutter-engineer` implements Insights screen (5.6): pattern visualizations + mandatory disclaimer ack on first view.
- `flutter-engineer` implements account deletion (2.4) in parallel.
- `security-reviewer` audits the Cloud Function `suggestQuote.ts`: rate limiting, input validation, no PII to Gemini. Audits account deletion flow.

**Day 3 (May 15) — Integration tests + a11y sweep**
- `qa-engineer` runs integration tests (8.3): all 3 intervention tiers seeded with synthetic mood histories. Critical: TC-40 (Tier 3 determinism — Gemini-mock asserts no call) and TC-41 (Quote Safety Filter rejection rate = 100%).
- `qa-engineer` starts a11y sweep — every screen, WCAG 2.2 AA contrast, dynamic type. Disclaimer dialog must be readable at 200% type.
- `flutter-engineer` addresses a11y findings same-day.
- `Theerawat` continues Audit Report draft.

**Day 4 (May 18) — Cross-platform + performance**
- `qa-engineer` runs Chrome web matrix + Android matrix. Document with screenshots.
- `qa-engineer` runs performance profile: cold start, frame rate on Insights scroll, memory.
- `flutter-engineer` addresses regressions.
- `security-reviewer` final Security Posture Report.

**Day 5 (May 19 — presentation day)**
- Final smoke pass on both platforms.
- `Theerawat` finalizes Audit Report with test results, a11y findings, perf numbers, screenshots, Plan Mode transcripts.
- Merge everything. Tag `v1.5`.
- Demo: switch to Som's seeded data → Pattern Engine fires Tier 1 → notification appears with disclaimer footer + safe Gemini-suggested quote (filtered) → user opts out, no further alerts for 48h. Continue to seeded Tier 2 day → journaling prompt. Continue to seeded Tier 3 day → curated message + Hotline 1323 + disclaimer (verify byte-for-byte from curated pool, no Gemini). First Insights view → mandatory ack dialog. Account deletion → all data goes.

### High-risk items requiring your attention

1. **TC-40: Tier 3 determinism** — most critical test in the entire project. Tier 3 path through Gemini = catastrophic failure mode. Implementation must have hard branch; test must mock Gemini and assert it was NEVER called when triggering Tier 3. Fail this test → fail the sprint.

2. **TC-41: Quote Safety Filter rejection** — feed 50 synthetic Gemini outputs containing forbidden terms (depression, bipolar, diagnosis, medication, urgency words "must/should/now"). Filter must reject 100%. Any pass-through is a blocker.

3. **Disclaimer placement (TC-36–39)** — every notification body MUST include the footer line. Test by mocking dispatcher and asserting all 3 tier outputs contain disclaimer string. Insights screen MUST require ack on first view (state in `users/{uid}.insightsDisclaimerAcked`).

4. **Curated phrase pool review** — before merge, the entire team reads aloud every Tier 1, 2, 3 curated phrase. If any phrase causes hesitation or feels off → revise. Tier 3 phrases especially: read aloud twice. The team is the last line of defense.

### Acceptance criteria (Sprint 5 demo + v1.5 release)

From `.claude/specs/sprint-4-5-spec.md` Part 7. All must pass:

**Skin System (TC 6–10):**
- [ ] TC-6: Unlock sunflower skin → ALL sunflowers display new skin.
- [ ] TC-7: Tap a flower → mood entry detail opens.
- [ ] TC-8: Skin modal shows locked skins with correct token cost.
- [ ] TC-9: Spending tokens reduces balance with confirmation dialog.
- [ ] TC-10: Default skin always available without purchase.

**Intervention Notifications (TC 31–35):**
- [ ] TC-31: Max 1 notification per 24h enforced.
- [ ] TC-32: 48h cooldown between alerts enforced.
- [ ] TC-33: Tier 3 always includes Hotline 1323 link + crisis resources.
- [ ] TC-34: All notifications include "I'm okay" opt-out.
- [ ] TC-35: Intervention features NEVER locked behind tokens.

**Bipolar Disclaimer (TC 36–39):**
- [ ] TC-36: First Insights view shows mandatory ack dialog.
- [ ] TC-37: Ack state persists across restarts.
- [ ] TC-38: Every Tier 1/2/3 notification body includes disclaimer footer.
- [ ] TC-39: Settings → About contains full disclaimer text.

**Tier 3 Determinism (TC 40–41) — CRITICAL:**
- [ ] TC-40: Tier 3 dispatch — Gemini-mock asserts NO call attempted; output byte-for-byte from curated pool.
- [ ] TC-41: Quote Safety Filter rejects 100% of test cases containing forbidden terms.

**Final release gates:**
- [ ] All integration tests pass on both Android emulator and Chrome web.
- [ ] Accessibility sweep documented; every screen ≥ WCAG 2.2 AA.
- [ ] Performance profile documented; cold start < 2s.
- [ ] Enterprise Audit Report complete (5–8 pages).
- [ ] Evidence package compiled.
- [ ] Tag `v1.5` pushed.
- [ ] Zero HIGH/CRITICAL security findings.

### Out of scope for Sprint 5

- Thai localization (v2.0)
- iOS build (v2.0)
- Therapist-shared exports (v2.0)
- Any new features not in the committed backlog

### Now enter Plan Mode

Produce the plan, ADR-0007 (Tier 3 determinism rationale + Gemini-mock test design), the handoff brief for Tiered Intervention (5.4), and the handoff brief for Quote Library + Safety Filter (5.5). Wait for my approval.

At the end of the sprint, produce a retrospective in `docs/retros/sprint-5-retro.md`. The Enterprise Audit Report's "agent challenges" section pulls from this.
