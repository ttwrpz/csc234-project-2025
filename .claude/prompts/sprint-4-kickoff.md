# Sprint 4 Kickoff — v1.0: Compassionate Reframing + Pattern Detection + Test Suite

**Sprint window:** May 6 – May 12, 2026 (5 working days)
**Sprint goal:** Ship the compassionate reframing (wilting plants + rain clouds), Gemini-powered pattern analysis with confidence warnings, the repeat-pattern detector, the feature flag infrastructure, dark mode, and the full widget + golden + integration test suite. By end-of-sprint the app is the **v1.0 release**: all seven pivot features are feature-complete except the cheer-up intervention itself (Sprint 5).

**Release target:** v1.0 tag after Sprint 4 presentation on May 12.

---

## Paste this prompt into the main Claude Code session at the start of Sprint 4

Orchestrator, your Sprint 4 plan is below. Enter Plan Mode. Produce the decomposition, then wait for my approval before delegating.

### Context recap from Sprint 3

We tagged `v0.3-beta` at the Sprint 3 demo. Gemini mood detection works, offline-first is reliable, Firestore rules pass emulator tests, biometric fallback works on Android, analytics line chart is live, calendar view is live. Domain unit-test coverage ≥80% achieved. The team is tired — Kraiwich and Theerawat are near the top of their sprint capacity.

Sprint 4 is where the **app becomes compassionate**. Wilting plants and rain clouds replace any "neutral" negative-mood treatment. Pattern analysis arrives with explicit confidence labels. The full widget + golden + integration test suite catches up to the feature surface.

### Sprint 4 committed backlog (WBS IDs)

**Bucket 4 — Compassionate reframing:**
- 4.2 Wilting plants for negative intensity 1–3 (must, user-facing differentiator)
- 4.3 Rain clouds for negative intensity 4–5 + self-fade animation (must)

**Bucket 5 — Pattern detection:**
- 5.3 Gemini pattern analysis + confidence labels on dashboard (highest-risk of S4)
- 5.4 Repeat-pattern detector (5-of-7 OR 3-consecutive ≥ intensity 4) + 48h cooldown

**Bucket 6 — Settings polish:**
- 6.2 Dark mode toggle (system default)

**Bucket 7 — Test suite:**
- 7.2 Widget + golden tests for major screens (Auth, Garden, Log, Intensity Slider, History, Analytics)
- 7.3 Integration tests for critical flows (login→log→history→detail, AI override, pattern intervention stub) — starts S4, finishes S5

**Bucket 8 — Reporting:**
- 8.1 Enterprise Audit & Orchestration Report draft (parallel with tests, runs in background through to S5)

**Cross-cutting (Remote Config gate):**
- Wire `ai_pattern_analysis_enabled` Remote Config flag → `AIAnalysisRepository.isEnabled` getter → graceful UI fallback when disabled.

### Sprint 4 critical path (from PDM)

P (Pattern Analysis, 2.5d) → Q (Repeat-Pattern Detector, 1.5d) → [carries into S5 testing chain]

Calendar-paired parallel tracks:
- O (Wilting + Rain Clouds, 2.5d) on Napat
- R (Widget + Golden Tests, 2.5d) on Teerin

**Dependency warning:** P (Pattern Analysis) depends on J (Gemini Detection, done in S3) and L (Line Chart, done in S3). If either had defects from Sprint 3 review, address them day 1 before starting P.

### Your orchestration plan

**Day 1 (May 6)** —
- `architect` writes ADR-0006 on the reframing mechanism: why intensity-based split (not mood-type split), how the metaphor maps visually, how time-based fade works. Reference Som's Journey Map scenarios.
- `architect` writes a handoff brief for Pattern Detection (5.3, 5.4). Specify: 5-of-7 rule OR 3-consecutive rule, 48h cooldown, 10-day escalation trigger, confidence label thresholds (low <0.5, medium 0.5–0.8, high >0.8, plus sample-size floor).
- `flutter-engineer` starts wilting plant widget (4.2) — Napat's day.
- `qa-engineer` starts widget tests for existing screens (7.2) — 3-day task running through the sprint.

**Day 2 (May 7)** —
- `flutter-engineer` implements rain cloud widget (4.3) and fade animation. Animation uses `AnimatedPositioned` + `Opacity`, drifts 15–25s across the garden, no user action required.
- `flutter-engineer` wires the Remote Config flag `ai_pattern_analysis_enabled` (already scaffolded in S3) → `AIAnalysisRepository.isEnabled` getter → graceful UI fallback in the Insights area.
- `architect` reviews wilting plant + rain cloud against Som's acceptance criterion (no user action required to clean up a rain cloud).
- `qa-engineer` writes golden tests for: empty garden, garden with flowers, garden with wilting plants, garden with rain cloud.

**Day 3 (May 8)** —
- `flutter-engineer` starts Gemini pattern-analysis Cloud Function (5.3). Function accepts 30/90-day mood history, returns `PatternInsight[]` with explicit confidence + sample size.
- `security-reviewer` audits the new Cloud Function: rate limiting, input validation (reject if history > 500 entries), PII stripping (mood text not sent to Gemini, only numeric mood codes + dates).
- `flutter-engineer` starts the client-side repeat-pattern detector (5.4). Pure domain function in `features/garden/domain/pattern_detector.dart` — no Flutter imports, easy to unit-test.
- `flutter-engineer` implements dark mode (6.2) in parallel — Teerin's day.

**Day 4 (May 11)** —
- `flutter-engineer` implements Pattern Insights UI on the Analytics dashboard. Confidence badge visible on every insight; sample size shown.
- `flutter-engineer` completes the repeat-pattern detector and wires it into the Garden screen — detector returns `InterventionState { triggered, escalated, reason }`. Garden watches this state via Riverpod but does NOT show any UI yet (banner + notification are S5).
- `qa-engineer` starts integration tests (7.3) — login flow, mood log + history + detail flow.
- `Theerawat` starts drafting the Enterprise Audit Report (8.1) in parallel — this parallelism keeps the project on the 20-day envelope.

**Day 5 (May 12 — presentation day)** —
- `flutter-engineer` completes any remaining integration-test scaffolding to unblock qa-engineer's S5 work.
- `security-reviewer` produces a Security Posture Report for v1.0: Cloud Functions hardened, Firestore rules cover all collections, no HIGH/CRITICAL deps, no secrets in source, no PII in logs.
- Merge everything green. Tag `v1.0`.
- Sprint 4 demo: log a sad mood at intensity 3 → wilting plant. Log an anxious mood at intensity 5 → rain cloud drifts away. Open analytics → see "Your Monday mood averages 1.8 lower than Thursday — high confidence, 42 Monday samples". Flip the feature flag → Insights card hides gracefully. Dark mode toggle works.

### High-risk items requiring your attention

1. **Pattern Detection Cloud Function (5.3)** — wide PERT spread (O=2.0, M=3.0, P=4.5). If Gemini's pattern output is inconsistent (hallucinated insights), fall back to statistical patterns computed server-side (e.g., z-scores over weekdays) and document in ADR-0007. The user sees confidence labels either way.

2. **Reframing test coverage (4.2, 4.3)** — these are the pivot's most visible features. Ensure golden tests capture every intensity × mood-type combination. If the wilting plant looks identical to a flower in grayscale, the design is wrong — bring it back to Napat.

3. **Feature flag rollback rehearsal** — before the S4 demo, rehearse the kill-switch live. Flip the flag during the demo, show the graceful degradation, flip it back. This is required Enterprise Term Assignment evidence.

### Acceptance criteria for Sprint 4 presentation

- [ ] Negative mood intensity 1–3 renders as a wilting plant; intensity 4–5 renders as a rain cloud
- [ ] Rain clouds fade on their own within 15–25s (no user action required) — Som's US-Som-1 acceptance criterion
- [ ] Analytics dashboard shows at least one Pattern Insight with visible confidence label and sample size
- [ ] Flipping `ai_pattern_analysis_enabled` to `false` in Firebase Console hides the Insights card within 60s; mood logging and history are unaffected
- [ ] Feature flag rollback plan documented in `docs/runbooks/feature-flag-rollback.md`
- [ ] Dark mode toggle works; every screen respects it; tokens correctly swap
- [ ] Widget tests pass for Auth, Log Mood, Intensity Slider, History, Analytics, Settings (≥ 6 widget test files)
- [ ] Golden tests committed for: empty garden, flower garden, wilting-plant garden, rain-cloud garden, analytics dashboard, insights card (low/med/high confidence) — ≥ 6 golden files
- [ ] Integration test for login flow passes on both Android emulator and Chrome web
- [ ] Enterprise Audit Report draft started (covers Sections 1–4)
- [ ] Tag `v1.0` pushed after demo

### Out of scope for Sprint 4 (do not start these)

- Cheer-up intervention UI banner / FCM notification (S5)
- Hotline 1323 escalation footer (S5)
- FCM notification toggle (S5)
- Breathing exercise screen (S5)
- Account deletion (S5)
- Cross-platform Android + Web test execution documentation (S5)
- Accessibility sweep (S5)
- Performance profile (S5)
- Final reports (S5)

### Copy rule reminder

All new user-facing text goes through the copy rules in CLAUDE.md:
- No clinical language
- No streak-shaming
- Compassionate imperatives only

Specifically for this sprint: the Pattern Insights copy must surface "explicit confidence + sample size + nothing dramatic". Never say "We detected a concerning pattern" — say "Your Monday mood averages 1.8 lower than Thursday (87 Monday samples, high confidence)". Let the user draw the conclusion.

### Now enter Plan Mode

Produce the plan, ADR-0006 (reframing mechanism), ADR-0007 (pattern analysis fallback strategy), and the handoff brief for Pattern Detection. Wait for my approval. Do not write production code until I approve.
