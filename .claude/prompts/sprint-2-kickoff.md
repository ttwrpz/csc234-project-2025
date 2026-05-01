# Sprint 2 Kickoff — Foundation: Agent Scaffold + Clean Architecture + Walking Skeleton

**Sprint window:** April 22 – April 28, 2026 (5 working days)
**Sprint goal:** Build the foundation from a bare Flutter + Firebase template up to a walking skeleton on Clean Architecture. By end-of-sprint the app runs on Android and Web and a user can sign in, see the nav shell, and log a mood with intensity 1–5. No AI yet, no analytics, no compassionate reframing — those come in Sprints 3–5.

**Release target:** v0.2-walking-skeleton tag after Sprint 2 presentation on April 28.

---

## Paste this prompt into the main Claude Code session at the start of Sprint 2

Orchestrator, your Sprint 2 plan is below. Enter Plan Mode. Do not execute yet — produce the decomposition, then ask me to approve before delegating to subagents.

### Starting state

Sprint 1 (before Apr 21 through Apr 21) produced **agile planning artifacts only** — no Flutter feature code, no v0.1 Alpha demo. See `CLAUDE.md` for what the repo contains right now: the `flutter create` scaffold, `flutterfire configure` output, an empty `firebase.json` baseline, and this bundle (`CLAUDE.md` + `.claude/`). Everything else is built starting today.

This is **not a rewrite or pivot from prior code**. Sprint 2 is the foundation sprint. Build greenfield, follow the architecture diagrams in `docs/architecture/`, follow the journey-map acceptance criteria for each persona's needs.

### Sprint 2 committed backlog (WBS IDs)

All Sprint 2 work is greenfield. Items in this sprint:

**Bucket 1 — Setup & agent orchestration:**
- 1.1 Set up Flutter project structure, Firebase wiring, and Clean Architecture folder tree across all feature modules
- 1.2 Author CLAUDE.md and 4 subagent prompts (architect, flutter-engineer, qa-engineer, security-reviewer) — already in place; verify and extend if needed
- 1.3 Configure GitHub Actions CI/CD + Claude Code hooks (format, analyze, secret scan)

**Bucket 2 — Auth:**
- 2.1 Email/password + Google OAuth + GoRouter auth guards (Riverpod)

**Bucket 3 — Mood logging foundation:**
- 3.1 MoodEntry domain model (Freezed) + Firestore schema with intensity 1–5 + immutability flag
- 3.2 Mood selector UI grid + intensity slider 1–5 + multi-line text entry

**Bucket 5 — History foundation (starts S2, completes in S3):**
- 5.1 Scrollable mood list + filter chips + entry detail screen scaffold

**Bucket 6 — UI foundation:**
- 6.1 Design system tokens + GoRouter typed routes + bottom nav + onboarding carousel

### Sprint 2 critical path (from PDM)

A (Setup + agent scaffold + CI/CD, 1.5d) → B (Design tokens + GoRouter + nav + onboarding, 1.5d) → C (Auth, 2.0d) → [end of S2]

Parallel tracks:
- D (MoodEntry domain + Firestore schema, 1.0d) starts after A
- E (Mood logging UI, 2.0d) starts after B + D
- F (History list + filter + entry detail, 2.0d) starts after E (likely finishes day 1 of Sprint 3)

### Your orchestration plan

1. **Day 1 (Apr 22)** — invoke `architect` to produce ADR-0001 on Clean Architecture folder structure. Invoke `flutter-engineer` to scaffold the folder tree, Riverpod codegen setup, GoRouter shell, Firebase initialization. End of day: PR opens for review; `security-reviewer` audits the hooks config and `firebase_options.dart` exposure.

2. **Day 2 (Apr 23)** — `flutter-engineer` implements design tokens + bottom nav + onboarding (6.1) and the `MoodEntry` domain model + Firestore schema (3.1) in parallel. `architect` writes a handoff brief for Auth (2.1) — must specify GoRouter guard pattern and Riverpod provider shape.

3. **Day 3 (Apr 24)** — `flutter-engineer` starts Auth (2.1) — depends on GoRouter from previous day. `flutter-engineer` sets up GitHub Actions CI/CD (1.3) in parallel. `architect` writes a handoff brief for Mood Logging UI (3.2).

4. **Day 4 (Apr 27)** — `flutter-engineer` completes Auth and starts Mood Logging UI (3.2) — selector grid, intensity slider with haptic feedback (Lin's US-Lin-3 acceptance criterion: 48dp+ tall slider), text entry with 500-char counter. `security-reviewer` audits Auth: no password logging, Google OAuth scope minimal.

5. **Day 5 (Apr 28 — presentation day)** — `flutter-engineer` completes Mood Logging UI and starts History list + entry detail (5.1). `qa-engineer` writes widget tests for LogMoodScreen, IntensitySlider, and auth screens. Merge everything green. Tag `v0.2-walking-skeleton`. Sprint 2 demo: user signs up, completes onboarding, logs a mood with intensity 1–5, sees it in the (basic) History list.

### Plan Mode output

In Plan Mode, produce:
1. An ADR proposal (ADR-0001) for the Clean Architecture folder structure
2. A handoff brief for Auth that flutter-engineer will execute
3. A handoff brief for Mood Logging UI that flutter-engineer will execute
4. A day-by-day schedule with which agent runs when
5. A list of risks for this sprint and a mitigation for each

Do not start implementation until I approve the plan.

### Acceptance criteria for Sprint 2 presentation

- [ ] Repo has `CLAUDE.md`, `.claude/agents/*.md` (4 agents), `.claude/hooks/settings.json` — these were already in place at sprint start; verify they are unchanged or improved
- [ ] Folder tree matches the structure in CLAUDE.md (every feature module has presentation/domain/data subfolders)
- [ ] GitHub Actions CI runs on every PR and passes: `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test`
- [ ] App builds for both Android (debug APK) and Web (Chrome) from a clean checkout
- [ ] User can register with email/password and sign in with Google
- [ ] User can log a mood with intensity 1–5 and save it to Firestore (online write is fine for S2; offline-first comes in S3)
- [ ] User can view their mood list on the History screen
- [ ] Onboarding shows on first launch only
- [ ] Design system tokens defined and consumed by every screen
- [ ] At least 4 widget tests pass (auth, log mood, intensity slider, history list)
- [ ] Domain layer has zero Flutter/Firebase imports (verified by `grep -r "import 'package:flutter" lib/features/*/domain/` returning nothing)
- [ ] Tag `v0.2-walking-skeleton` pushed after demo

### Out of scope for Sprint 2 (do not start these — they belong to later sprints)

- Gemini AI integration (S3)
- Offline-first persistence with Drift (S3)
- Biometric fallback (S3)
- Firestore security rules with diff() (S3)
- Crashlytics + Remote Config (S3)
- Calendar view (starts S3)
- Garden visualization with flowers, wilting plants, rain clouds (S3 + S4)
- Analytics dashboard / line chart (S3)
- Pattern detection (S4)
- Cheer-up intervention (S5)
- 24-hour immutability **enforcement** (S3) — S2 ships only the `immutable` field on the model
- Dark mode (S4)
- Account deletion (S5)
- Image/video attachment (S3)

### Definition of Done for each PR this sprint

- `dart format` clean, `flutter analyze` clean, `flutter test` passing
- Domain layer has no Flutter/Firebase imports
- Unit tests for any new domain class in the same PR (flutter-engineer writes)
- No `print()`, no `!` null-assertion, no TODO without linked issue
- No secrets in source (security-reviewer verifies on merge of sensitive files)
- QA review by `qa-engineer` subagent before merge
- Security review by `security-reviewer` subagent if Firestore rules, Cloud Functions, or auth code is touched

### Now enter Plan Mode

Produce the plan. Wait for my approval. Do not write code yet.
