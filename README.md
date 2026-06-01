# MoodBloom

A compassionate, cross-platform mood tracker for Android and Web. Pick a feeling, slide an intensity, write as much (or as little) as you want - your entries grow into a living garden that gently reflects how the week has gone. AI-assisted text → mood detection runs through a Cloud Function proxy; a client-side pattern engine watches for heavier stretches and offers a 2-minute breathing exercise, a journaling prompt, or curated crisis resources before they become a crisis.

**Group 2 · CSC231 (Agile Software Engineering) + CSC234 (User-Centric Mobile App Development) · KMUTT · Semester 2 / 2568**

Team: Theerawat Patthawee (Lead), Kraiwich (full-stack), Teerin (UI/UX + QA), Jedsarit (Flutter + DevOps), Napat (UI/UX Lead).

---

## AI use disclosure

CSC234 explicitly **encourages students to use agentic AI tools** to build their applications. This project leans into that - MoodBloom was developed end-to-end with [Claude Code](https://claude.com/claude-code) (Anthropic's CLI agent) orchestrating a multi-agent workflow (architect → flutter-engineer → qa-engineer → security-reviewer). The orchestration setup lives in [`CLAUDE.md`](./CLAUDE.md), [`.claude/agents/`](./.claude/agents), and [`.claude/prompts/`](./.claude/prompts).

What that means in practice for any reader of this repository:

- Most of the Dart source, test files, ADRs, and security-rule iterations were drafted by agents and reviewed/edited by the human team.
- Every PR went through the four-role review chain documented below; **the engineer agent never approves its own work** (Enterprise R3).
- Architectural decisions are recorded as ADRs under [`docs/adr/`](./docs/adr) - those are the contract the agents were asked to honour.
- The human team owned: requirements, UX direction, sprint planning, retrospectives, security-rule sign-off, demo, and the final reports.

If you're a reviewer or a future student picking this up: the source code is the source of truth, but the agent prompts in `.claude/` are the closest thing to a development diary.

---

## Status

| Tag | Date | What landed |
|---|---|---|
| `v0.2-walking-skeleton` | Apr 28 | Auth + mood logging on Clean Architecture |
| `v0.3-beta` | May 5 | Gemini AI mood detection, offline-first Drift sync, security rules, fl_chart line chart |
| `v1.0` | May 12 | Compassionate reframing pass, client-side pattern engine, full test suite |
| `v1.5` | May 19 | Tiered intervention surfaces (breathing / journaling / crisis), token economy + flower skins, weekly harvest cycle, WebAuthn web fallback, dark-mode contrast sweep |
| `v1.6` polish (current branch) | - | Edit profile, sync recovery in Settings, per-platform notification + camera permissions, biometric-gate hardening, app rename to "MoodBloom" on Android |

The submission deadline is **30 May 2026**. See [`docs/release-notes/`](./docs/release-notes) for what shipped in each tag and [`docs/retros/`](./docs/retros) for sprint retrospectives.

---

## Tech stack

| Concern | Tool | Notes |
|---|---|---|
| UI | Flutter (stable channel) + Dart 3.x | Sound null safety; line length 100; `dart format` enforced by hook |
| State | Riverpod 2.x via `@riverpod` codegen | No Provider / GetIt / BLoC |
| Navigation | GoRouter | Auth + biometric + history-privacy gates as redirects |
| Entities | Freezed + `json_serializable` | Domain layer is pure Dart - see "the one rule" below |
| Local DB | Drift (SQLite via `sqlite3_flutter_libs 0.5.x`) | Offline-first; bumping to `sqlite3 ^3.x` is blocked on a Flutter SDK upgrade (see `pubspec.yaml` comment) |
| Remote | Cloud Firestore | Field-level rules via `diff().affectedKeys()` |
| Auth | Firebase Auth + `local_auth` + WebAuthn (web fallback per ADR-0014) | Biometric gate on cold boot |
| AI | Google Gemini `gemini-2.5-flash` via Cloud Functions proxy | Never called from the client directly |
| Charts | `fl_chart` | Tooltip + friendly tier labels |
| Observability | Firebase Crashlytics + structured logger | Native only; Web is a no-op |
| Feature flags | Firebase Remote Config | `ai_pattern_analysis_enabled` gates Tier 1/2 quote generation |
| Push | Firebase Cloud Messaging | Cheer-up channel registered in `main.dart` |
| CI | GitHub Actions | `format` + `analyze` + `test` on every PR |

### The one rule that can't break

`lib/features/<feature>/domain/` has **zero imports** of `package:flutter/*`, `package:firebase_*/*`, or `package:cloud_firestore/*`. Any PR that violates this is rejected on sight - that's what makes the domain layer unit-testable and is graded in the Enterprise Term Assignment.

---

## Quick start

Prerequisites: Flutter stable, `dart`, the Firebase CLI, Android SDK + an emulator or device, and a `flutterfire configure`'d Firebase project (this repo's `google-services.json` + `lib/firebase_options.dart` point at the group's project).

```bash
# Restore dependencies
cd apps/mobile
flutter pub get

# Regenerate Freezed / Riverpod / JSON / Drift code
flutter pub run build_runner build --delete-conflicting-outputs

# Run on Android
flutter run -d android

# Run on Web
flutter run -d chrome

# Run all tests
flutter test

# Run integration tests
flutter test integration_test/ -d android
```

Deploy Cloud Functions:

```bash
cd functions
pnpm install
pnpm run deploy:staging
```

Or use the orchestrated script: [`scripts/deploy_firebase.ps1`](./scripts/deploy_firebase.ps1) (Windows) / [`scripts/deploy_firebase.sh`](./scripts/deploy_firebase.sh) (POSIX) - handles `pnpm install` + project-scoped deploy in one command.

---

## Repository layout

```
csc234-project-2025/
├── CLAUDE.md                     ← project memory, loaded on every Claude Code session
├── .claude/
│   ├── agents/                   ← agent role definitions (architect, flutter-engineer, qa-engineer, security-reviewer)
│   ├── prompts/                  ← per-sprint kickoff prompts
│   ├── specs/                    ← Sprint 4–5 ecosystem spec (formulas, test cases, citations)
│   └── hooks/                    ← format + analyze + secret-scan + domain-purity hooks
├── apps/mobile/                  ← Flutter app
│   ├── lib/features/             ← Clean Architecture per feature (presentation / domain / data)
│   ├── test/                     ← unit + widget + golden tests
│   ├── integration_test/         ← end-to-end flows
│   ├── android/, web/            ← platform shells
│   └── assets/                   ← icon + fonts
├── packages/
│   ├── design_system/            ← MbCard, MbPrimaryButton, MbColors, tokens, theme
│   ├── core/                     ← Result<T,F>, Logger, Failure base class
│   └── analytics/                ← fl_chart wrappers
├── functions/                    ← TypeScript Cloud Functions (Gemini proxy, wipeUserData, sendCheerUpPush, ...)
├── firebase/
│   ├── firestore.rules           ← canonical rules
│   ├── storage.rules
│   └── test/                     ← rules emulator tests
├── docs/
│   ├── adr/                      ← architecture decision records
│   ├── handoffs/                 ← architect → engineer briefs
│   ├── retros/                   ← per-sprint retrospectives
│   ├── release-notes/
│   └── report/                   ← Enterprise Term Assignment report
└── scripts/                      ← deploy + tooling
```

---

## Development workflow

The four-role workflow Claude Code uses on this repo:

| Role | Owns | Tools |
|---|---|---|
| **architect** | ADRs, handoff briefs, cross-cutting decisions. Never implements. | Read, Glob, Grep, WebFetch |
| **flutter-engineer** | Feature code + domain unit tests in the same PR. | Read, Write, Edit, Glob, Grep, Bash |
| **qa-engineer** | Widget / golden / integration tests, accessibility sweeps, performance profiles. Reviews PRs. | Read, Write, Edit, Glob, Grep, Bash |
| **security-reviewer** | Read-only audit of Firestore rules, Cloud Functions, auth flows, secrets. Produces a risk register. | Read, Glob, Grep, Bash |

Per-PR flow:

```
architect → handoff brief
flutter-engineer → feature branch + code + domain tests + open PR
CI → format + analyze + test (blocking)
qa-engineer → widget/golden tests + review comment
security-reviewer → risk register comment (if rules/functions/auth touched)
human team → merge (squash only) after both reviews land
```

The engineer that writes the code is **never** the agent that approves it - Enterprise R3.

### Hooks

`.claude/hooks/settings.json` runs four checks on every Dart edit:

1. **Secret scan** - blocks writes matching common API-key patterns.
2. **Domain-purity** - blocks writes to `domain/` files that import Flutter / Firebase.
3. **Auto-format** - runs `dart format` on the edited file.
4. **Analyze** - runs `flutter analyze` on the touched feature folder.

Hooks 1 and 2 are blocking. Hooks 3 and 4 are advisory.

---

## Skills + spec

Domain logic and copy rules live in two reference documents the agents must read before working on Sprint 4–5 features:

- [`CLAUDE.md`](./CLAUDE.md) - coding conventions, copy rules ("never use 'delete'/'wilt'/'dead'"), folder layout, Firestore schema, security-rule invariants, branching rules.
- [`.claude/specs/sprint-4-5-spec.md`](./.claude/specs/sprint-4-5-spec.md) - Mood Score formula, Garden Health EWMA derivation (α=0.15), all 5 pattern detection algorithms (Mann-Kendall, sliding 5-of-7, 3-consecutive negative, Z-score, CUSUM), Tiered Intervention dosing + cooldown rules, Tier 3 curated-only safety guarantee, bipolar/medical disclaimer placement, token economy guardrails, 35 acceptance test cases.

---

## Quality gates

All four must pass before any release tag (Enterprise R5):

1. **Correctness** - `flutter test` passes; domain layer ≥80 % line coverage.
2. **Security** - `flutter pub deps` shows no HIGH/CRITICAL vulnerabilities; secret scan clean; Firestore rules pass emulator tests.
3. **Accessibility** - Semantics labels on every interactive widget; WCAG 2.2 AA contrast; dynamic type support.
4. **Performance** - Cold start < 2 s on mid-range Android; no unbounded `ListView`; images cached via `cached_network_image`.

---

## Where to find what

- **ADRs** - [`docs/adr/NNNN-*.md`](./docs/adr)
- **Sprint retrospectives** - [`docs/retros/`](./docs/retros)
- **Release notes** - [`docs/release-notes/`](./docs/release-notes)
- **Test reports** - [`docs/test-reports/`](./docs/test-reports)
- **Enterprise Term Assignment report** - [`docs/report/enterprise-audit.md`](./docs/report)
- **Sprint 4–5 ecosystem spec** - [`.claude/specs/sprint-4-5-spec.md`](./.claude/specs/sprint-4-5-spec.md)
- **Agent prompts** - [`.claude/agents/`](./.claude/agents) and [`.claude/prompts/`](./.claude/prompts)

---

## License

Coursework. Not licensed for redistribution; not a medical device.

> MoodBloom is not a medical device. It cannot diagnose conditions like bipolar disorder, depression, or anxiety. Consult a qualified professional.
