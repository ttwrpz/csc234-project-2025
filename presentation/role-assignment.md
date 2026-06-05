# Suggested Role Assignment

**Release:** v1.6 · commit `0e55021a` · generated 2026-06-02

The team has 5 members; the brief asks for 3 named orchestration roles. This is the recommended mapping — adopt it or document why you diverged (see the quality-gate checklist).

## Three roles, five members — the mapping

| Role | Members | Why |
|---|---|---|
| **Orchestrator** | Theerawat Patthawee (Lead) | The Lead's scope already covers sprint kickoffs, Plan Mode, and agent dispatch. One voice opens and closes for continuity. |
| **Architect / Reviewer** | Kraiwich Jaiton + Napat Chang-ekwong | Kraiwich owns the Pattern Engine + Quote Library architecture; Napat owns the UI/UX system + screen architecture. Together they cover technical *and* design review. |
| **QA / Release Engineer** | Teerin Kittichaicharoen + Jedsarit Fanpimiy | Teerin owns QA + accessibility; Jedsarit owns CI/CD + DevOps. Together they cover the test → release pipeline. |

## Section-to-speaker assignment (recommended)

| Section | Slides | Duration | Speaker(s) |
|---|---|---|---|
| 1. Title & Team | 1–2 | ~1:00 | Orchestrator (Theerawat) |
| 2. Problem & Business Solution | 3–6 | ~2:25 | Architect/Reviewer (Napat — design + business framing) |
| 3. Live Demo | 7–10 | ~2:30 | QA/Release (Jedsarit driving; Teerin narrates the a11y beat on Slide 9) |
| 4. Multi-Agent AI | 11–14 | ~2:35 | Orchestrator (Theerawat) |
| 5. Architecture & Data | 15–18 | ~2:25 | Architect/Reviewer (Kraiwich — incl. Slide 16 algorithm deep-dive) |
| 6. Reliability & Quality Gates | 19–22 | ~2:00 | QA/Release (Teerin) |
| 7. Conclusion | 23–24 | ~1:00 | Orchestrator (Theerawat) |
| **Total** | **24** | **~13:55** | — |

## Why this split

- **Theerawat (Orchestrator) bookends** — opens (1) and closes (7) for voice continuity, and owns Section 4 because the AI-orchestration story is the Lead's to tell.
- **Napat opens Section 2** because the problem/solution framing is UX-led; he then hands the *technical* architecture to Kraiwich in Section 5. The two Architect/Reviewers split on design-vs-technical, which is how they already divide the codebase.
- **Napat carries the new business arc** (Market & Opportunity, Competitive Positioning & Business Model) inside Section 2 — it's UX/market framing, and it sets up the technical story Kraiwich delivers in Section 5.
- **Kraiwich owns the algorithm deep-dive (Slide 16)** — the five-detector Pattern Engine is the densest technical slide and the one the commentators will probe hardest; it's his architecture. If the talk runs long, Slide 16 is the designated appendix cut (folds to A4; see `speaker-script.md` compression levers).
- **Jedsarit drives the demo (Section 3)** because he owns build/release and can recover fastest if a step fails. **Teerin narrates the a11y portion** (Slide 9) because she owns the accessibility work, then carries Section 6 (Reliability & Quality Gates) because she owns the test-suite story.

## Alternative split (one speaker per section)

If the team prefers each person owning one section solo:

- Theerawat → 1 + 7 (≈2:00)
- Napat → 2 (≈2:55 — includes the business arc)
- Jedsarit → 3 (≈2:30)
- Theerawat → 4 (≈2:55, doubles up)
- Kraiwich → 5 (≈2:25 — includes the algorithm deep-dive)
- Teerin → 6 (≈2:00)

This concentrates the Orchestrator's load on Sections 1, 4, 7 (≈4.5 min) — which mirrors the role's real weight in the workflow.

## Notes for whoever drives the demo

- Have **both** Android (real S23 or emulator) and Web (Chrome) builds running before the talk starts.
- **Pre-seed ≥5 mood entries** so Garden and History have content.
- **Pre-seed pattern history** so the Patterns chart is non-empty — but **do NOT trigger an intervention live** (use the backup video; a live Tier-1 needs 14 days of data and the global cooldown blocks repeats).
- Set **Privacy Lock to OFF** for the demo session (one less thing to fail).
- Disable demo-build analytics so Crashlytics stays clean during the talk.
- Keep the offline-first beat tight: airplane mode → log → reconnect → Firestore appears. Rehearse the reconnect timing; it's the crispest 30 seconds in the deck.

## Honest framing reminder (all speakers)

When the multi-agent story comes up (Section 4) and in Q&A, the truth is in the middle: **humans designed the system, AI implemented within tight scopes, humans verified every output.** Don't oversell ("the agents did everything") or undersell ("the AI was just autocomplete"). Slide 13's three catches are real and documented — lean on them.
