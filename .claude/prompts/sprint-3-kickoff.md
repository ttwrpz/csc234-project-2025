# Sprint 3 Kickoff — v0.2 Beta: AI Detection + Offline-First + Security

**Sprint window:** April 29 – May 5, 2026 (5 working days)
**Sprint goal:** Ship the Gemini-powered AI mood detection, offline-first persistence with Drift + 24-hour immutability, Firestore security rules with field-level validation, biometric fallback, Crashlytics, and the analytics dashboard foundation. By end-of-sprint the app is a **v0.2 Beta candidate**: it does the AI magic, works offline, enforces security, and has the line chart visible.

**Release target:** v0.2-beta tag after Sprint 3 presentation on May 5.

---

## Paste this prompt into the main Claude Code session at the start of Sprint 3

Orchestrator, your Sprint 3 plan is below. Enter Plan Mode. Produce the decomposition, then wait for my approval before delegating.

### Context recap from Sprint 2

At the Sprint 2 presentation we tagged `v0.2-walking-skeleton`. Starting from a bare Flutter + Firebase template, we built up: Clean Architecture folder structure scaffolded, CI green on every PR, user can sign up with email or Google, log a mood with intensity 1–5, view it in a basic history list. Design system tokens are defined and consumed across every screen. Walking skeleton, not feature-complete.

What does NOT exist yet (to manage your expectations going into S3): no offline-first storage, no AI, no analytics charts, no garden visualization, no security rules beyond defaults, no Crashlytics, no biometric, no 24h immutability enforcement, no calendar view.

Sprint 3 is where the **app becomes AI-assisted**. Before this sprint, MoodBloom is just a well-architected mood tracker with a single-line Firestore write. After this sprint, it has Gemini detection, offline reliability, hardened security rules, and a working analytics line chart.

### Sprint 3 committed backlog (WBS IDs)

**Bucket 1 — Observability:**
- 1.4 Crashlytics + Remote Config feature flag infrastructure

**Bucket 2 — Security:**
- 2.2 Persistent session + biometric fallback (`local_auth` + platform keystore)
- 2.3 Firestore security rules with `diff().affectedKeys()` + per-user RBAC

**Bucket 3 — Mood logging completion:**
- 3.3 Image/video picker + Firebase Storage upload
- 3.4 Gemini AI mood detection via Cloud Function proxy + confidence + override UX (highest-risk task)
- 3.5 Drift offline-first + sync manager + 24h immutability guard

**Bucket 4 — Garden foundation:**
- 4.1 Garden canvas + positive moods → flowers + streak counter + weekly bloom bar

**Bucket 5 — Analytics & history:**
- 5.1 Calendar view (completes the S2 history work)
- 5.2 fl_chart integration + mood-over-time line chart (7/30/90-day windows)

**Bucket 7 — Testing:**
- 7.1 Domain unit tests ≥80% coverage (MoodEntry, intensity validation, immutability guard, pattern detector stub)

### Sprint 3 critical path (from PDM)

G (Firestore Security Rules, 1.5d) → I (Drift offline-first, 2.0d) → L (Line chart, 2.0d) → [carries into S4]

Other high-risk activities:
- J (Gemini Detection, 2.5d) — wide PERT spread; spike on day 1
- I (Drift offline-first, 2.0d) — wide PERT spread; spike on day 1

**Required: a 0.5-day technical spike at the start of Sprint 3** — one spike on the Gemini Cloud Function contract (request/response JSON, PII filter, rate-limit) and one spike on the Drift schema design. `architect` owns both. Output: ADR-0003 (Gemini contract) and ADR-0004 (Drift schema).

### Your orchestration plan

**Day 1 (Apr 29)** —
- `architect` runs the two spikes in the morning. Output: ADR-0003 (Gemini contract — request JSON, response JSON, error taxonomy, PII filter, rate-limit) and ADR-0004 (Drift schema + sync queue table).
- `architect` writes a handoff brief for Firestore Security Rules (2.3).
- `flutter-engineer` starts Crashlytics + Remote Config scaffolding (1.4) — low-risk, unblocks S4+ observability.
- In parallel, `flutter-engineer` starts Firestore security rules (2.3) — depends on Auth (done in S2) and MoodEntry schema (done in S2).

**Day 2 (Apr 30)** —
- `flutter-engineer` completes Firestore rules (2.3); writes emulator tests covering per-user isolation, `createdAt` immutability, and the `diff().affectedKeys()` field-level allowlist.
- `security-reviewer` audits rules + emulator tests before merge — critical sign-off.
- `flutter-engineer` starts image/video picker (3.3) in parallel.
- `flutter-engineer` starts Garden canvas + flowers + streak + weekly bloom bar (4.1) in parallel (Napat's day).
- `architect` writes a handoff brief for Gemini Mood Detection (3.4). Specify: Cloud Function structure, confidence surfacing, override UX (Lin's US-Lin-2 acceptance criterion).

**Day 3 (May 1)** —
- `flutter-engineer` starts Gemini integration (3.4) — Cloud Function scaffold in TypeScript, Dart client `AIAnalysisRepositoryImpl`, Riverpod provider wiring.
- `security-reviewer` audits the Cloud Function as it's written: Gemini key via `functions.config()` never in source; input length cap; rate limiter; PII filter; structured logger that does not log mood text.
- `flutter-engineer` starts offline-first persistence (3.5) in parallel — Drift schema, local data source, sync manager, 24h immutability guard.

**Day 4 (May 4)** —
- `flutter-engineer` completes Gemini detection UX — `AISuggestionPill` widget with confidence badge, override on single tap.
- `flutter-engineer` completes offline-first (3.5) including the immutability guard.
- `qa-engineer` writes widget tests for Log Mood including the AI suggestion pill.
- `flutter-engineer` starts analytics: `fl_chart` integration + mood-over-time line chart (5.2).
- `flutter-engineer` starts persistent session + biometric fallback (2.2) in parallel.

**Day 5 (May 5 — presentation day)** —
- `flutter-engineer` completes analytics line chart with 7/30/90-day window selector.
- `flutter-engineer` completes Calendar view (5.1).
- `flutter-engineer` completes biometric fallback (2.2).
- `qa-engineer` runs the domain unit test pass — targets ≥80% coverage on MoodEntry, intensity validation, ImmutabilityGuard, PatternDetector stub.
- Merge everything green. Tag `v0.3-beta`.
- Sprint 3 demo: user types text → AI suggests mood + intensity + confidence → user overrides if wrong → saves offline (airplane mode demo) → reconnects → entry syncs → user sees mood on 30-day line chart. Calendar view shows colored mood dots.

### High-risk items requiring your attention

1. **Gemini Cloud Function (3.4)** — widest PERT spread in the backlog (O=2.0, M=3.0, P=4.5). Spike on day 1 mandatory. If the contract is unclear by end-of-day-1, escalate to the team meeting before implementation starts.

2. **Offline-first sync (3.5)** — wide spread (O=1.5, M=2.5, P=4.0). Trickiest part is conflict resolution when a user edits a mood within 24h on device A then on device B before A syncs. Decision: last-write-wins by `updatedAt` timestamp, documented in ADR-0005.

3. **Firestore security rules (2.3)** — single highest-value security artifact in the project. Get it right; emulator-test every path. Do not merge without `security-reviewer` approval.

### Acceptance criteria for Sprint 3 presentation

- [ ] User types "ugh today was so long" → AI suggests mood + intensity + confidence → user can accept or override with one tap (Lin's US-Lin-2)
- [ ] User logs a mood with airplane mode on → save succeeds immediately from local Drift → enables connectivity → entry appears in Firestore within 10 seconds
- [ ] User edits a mood from today → edit saves. User tries to edit a mood from 2 days ago → sees the lock tooltip
- [ ] Firestore emulator test suite passes: ≥10 tests covering per-user isolation, `createdAt` immutability, `updatedAt` within 24h, field-level rules
- [ ] Crashlytics receives a test crash from a debug-only "crash now" button in Settings
- [ ] Analytics screen shows a line chart with 7/30/90-day window toggle and real data
- [ ] Calendar view shows colored mood dots
- [ ] Biometric sign-in works on Android emulator (fingerprint simulated)
- [ ] Domain unit test coverage ≥80% on `domain/` folders (verified by `flutter test --coverage`)
- [ ] No HIGH or CRITICAL `npm audit` findings in `functions/`
- [ ] Tag `v0.3-beta` pushed after demo

### Out of scope for Sprint 3 (do not start these)

- Compassionate reframing / wilting plants / rain clouds (S4)
- Pattern detection and AI Insights UI (S4)
- Cheer-up intervention banner / FCM notification (S5)
- Widget + golden + integration tests beyond what's already scheduled (S4)
- Dark mode (S4)
- Account deletion (S5)
- FCM notification toggle (S5)
- Final audit report drafting (S4 onward)

### Now enter Plan Mode

Produce the plan, the three ADRs (ADR-0003 Gemini contract, ADR-0004 Drift schema, ADR-0005 conflict resolution), and the two handoff briefs (Security Rules, Gemini Detection). Wait for my approval. Do not write production code until I approve.
