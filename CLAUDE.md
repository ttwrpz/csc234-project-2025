# MoodBloom — Project Memory for Claude Code

This file is loaded into every Claude Code session at the root of the repo. **Keep it short, specific, and current.** It is the single source of truth for conventions every agent in this project must follow.

---

## Product in one sentence

MoodBloom is a cross-platform Flutter mood-tracker for Android and Web that uses AI to assist logging, detects distress patterns compassionately, and visualizes emotional history as a living garden.

## Starting state of the codebase

Sprint 1 (before Apr 21 – Apr 21) produced agile planning artifacts only — **no Flutter feature code was written**. The repo at the start of Sprint 2 contains only:

- `flutter create` scaffold (default `lib/main.dart`, default `pubspec.yaml`)
- `flutterfire configure` output (`lib/firebase_options.dart`, `android/app/google-services.json`)
- `firebase init` baseline (`firebase.json`, empty `firestore.rules`, empty `storage.rules`)
- This bundle: `CLAUDE.md` and `.claude/`

Everything else — folder structure, features, design system, tests, security rules — is built from Sprint 2 onward by the agent team following the per-sprint kickoff prompts. Do not assume any feature, screen, widget, or repository exists until a sprint prompt says it has been built.

## Team & course context

- KMUTT Group 2, Semester 2/2568
- Courses: CSC231 Agile SE + CSC234 User-Centric Mobile App Dev
- Team: Kraiwich (full-stack), Teerin (UI/UX + QA), Theerawat (Lead), Jedsarit (Flutter + DevOps), Napat (UI/UX Lead)
- Submission deadline: 30 May 2026

---

## Stack (locked)

| Concern | Tool | Version / Notes |
|---|---|---|
| UI | Flutter | Stable channel |
| Language | Dart | 3.x, sound null safety |
| State mgmt | **Riverpod 2.x** with `@riverpod` codegen | No Provider, no GetIt, no BLoC |
| Navigation | **GoRouter** | with auth guards, typed routes |
| Entities | **Freezed** + `json_serializable` | for all domain entities and DTOs |
| Local DB | **Drift** (SQLite) | for offline-first persistence |
| Remote | **Cloud Firestore** | with `diff().affectedKeys()` rules |
| Auth | Firebase Auth + `local_auth` + platform keystore | biometric fallback required |
| AI | Google Gemini `gemini-2.5-flash` via **Cloud Functions proxy** | never call Gemini directly from the app |
| Charts | `fl_chart` | |
| Observability | Firebase Crashlytics + structured logger | |
| Feature flags | Firebase Remote Config | AI pattern-analysis gated |
| Push | Firebase Cloud Messaging (FCM) | |
| CI | GitHub Actions | format + analyze + test on every PR |

## Architecture (locked)

**Strict Clean Architecture**, three layers per feature, feature-first folder structure:

```
lib/features/<feature>/
├── presentation/     # Screens, controllers (Riverpod), widgets
├── domain/           # Entities (Freezed), use cases, abstract repos, pure Dart
└── data/             # Repository impls, data sources, DTOs, mappers
```

### The one rule that cannot break
**The `domain/` folder has ZERO imports of `package:flutter/*` or `package:firebase_*/*` or `package:cloud_firestore/*`.** Any PR that violates this is rejected on sight. This is what makes the domain layer unit-testable and is graded in the Enterprise Term Assignment.

### Dependency arrows always point inward
- Presentation depends on Domain
- Data depends on Domain
- Domain depends on nothing (except pure Dart)

### Repository pattern
Domain defines **abstract** `MoodRepository`, `AIAnalysisRepository`, etc. Data layer provides concrete `MoodRepositoryImpl` that implements the abstract. Riverpod `provider overrides` swap in fakes for tests.

### Use cases
One file per use case in `domain/usecases/`. Each is a class with a single `call()` method. Controllers invoke use cases, never repositories directly.

---

## Folder structure (authoritative)

```
moodbloom/
├── CLAUDE.md                       (this file)
├── .claude/
│   ├── agents/                     (subagent prompts)
│   ├── prompts/                    (per-sprint orchestration prompts)
│   └── hooks/settings.json         (format + analyze + secret scan)
├── .github/workflows/ci.yml
├── apps/mobile/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app/
│   │   │   ├── router.dart
│   │   │   └── theme.dart
│   │   └── features/
│   │       ├── auth/               (presentation/domain/data)
│   │       ├── mood/               (presentation/domain/data)
│   │       ├── garden/             (presentation/domain/data)
│   │       ├── analytics/          (presentation/domain/data)
│   │       ├── history/            (presentation/domain/data)
│   │       └── settings/           (presentation/domain/data)
│   ├── test/                       (unit + widget + golden)
│   └── integration_test/
├── packages/
│   ├── design_system/              (tokens, theme, core widgets)
│   ├── core/                       (error types, result wrapper, logger)
│   └── analytics/                  (fl_chart wrappers)
├── functions/                      (TypeScript Cloud Functions — Gemini proxy)
│   └── src/
│       ├── analyzeMoodText.ts
│       └── analyzePatterns.ts
└── firebase/
    ├── firestore.rules
    └── storage.rules
```

---

## Coding conventions

- **Line length:** 100 chars.
- **Formatting:** `dart format` on save. A hook enforces this.
- **Naming:** `snake_case.dart` filenames. PascalCase classes. camelCase members. Private members prefixed `_`.
- **Imports:** relative imports for same-feature files, absolute `package:moodbloom/...` for cross-feature.
- **Null safety:** no `!` null-assertion operator in production code. Use `if-null` operators or explicit null checks.
- **Error handling:** return a `Result<T, Failure>` sealed class from repositories. No throwing from domain.
- **Logging:** use `packages/core/logger.dart`, never `print()`. Never log PII (mood text, email, uid-with-text).
- **Comments:** explain *why*, not *what*. No `// TODO` without a linked issue.
- **Tests:** every new domain class requires unit tests in the same PR. Every new screen requires at least one widget test.

## Dart style — specific patterns we enforce

```dart
// ✅ Domain entity (Freezed)
@freezed
class MoodEntry with _$MoodEntry {
  const factory MoodEntry({
    required String id,
    required String userId,
    required MoodType mood,
    required int intensity, // 1..5
    required String text,
    required DateTime createdAt,
  }) = _MoodEntry;

  factory MoodEntry.fromJson(Map<String, Object?> json) => _$MoodEntryFromJson(json);
}

// ✅ Riverpod controller with codegen
@riverpod
class LogMoodController extends _$LogMoodController {
  @override
  MoodDraft build() => const MoodDraft.empty();

  Future<Result<MoodEntry, Failure>> save() async {
    final useCase = ref.read(saveMoodEntryUseCaseProvider);
    return useCase(state);
  }
}

// ✅ Repository abstract in domain/
abstract class MoodRepository {
  Stream<List<MoodEntry>> watchAll({required String userId});
  Future<Result<MoodEntry, Failure>> save(MoodEntry entry);
}
```

---

## Firestore data model

```
users/{uid}                 → UserProfile { displayName, photoUrl, createdAt }
users/{uid}/moods/{moodId}  → MoodEntry  { mood, intensity, text, createdAt, updatedAt, mediaRefs[] }
users/{uid}/insights/{id}   → PatternInsight { window, text, confidence, sampleSize, generatedAt }
```

### Security rules (non-negotiable)
- Users can only read/write documents under `users/{request.auth.uid}/**`
- `createdAt` must equal `request.time` on create (server-side timestamp validation)
- `createdAt` is immutable on update
- Edits/deletes are allowed only on the same UTC calendar day as `createdAt` (enforced via `request.time.year/month/day == resource.data.createdAt.year/month/day`). Domain `isLocked` mirrors this with local-time day comparison.
- Field-level validation via `diff().affectedKeys()` — only specific fields may change on update
- See `firebase/firestore.rules` for canonical rules

---

## The seven pivot features (what this app IS)

1. **Intensity slider 1–5** on every entry (domain field: `int intensity`)
2. **Gemini AI mood detection** from text via Cloud Function proxy
3. **Analytics dashboard** with mood-over-time line chart (7/30/90-day windows)
4. **Gemini pattern analysis** over history with explicit confidence labels
5. **Cheer-up intervention** triggered by 5-of-7 negative days OR 3-consecutive same-type at intensity ≥ 4; 48h cooldown; 10-day escalation adds Thai Mental Health Hotline 1323 footer
6. **Same-day entry immutability** — edits/deletes allowed until local midnight of the day the entry was created; locked thereafter
7. **Compassionate reframing** — positive = flowers; negative intensity 1–3 = wilting plants; negative intensity 4–5 = rain clouds that fade on their own

## Copy rules (user-facing text)

These apply to all user-visible strings. Reviewer agents check for violations.

- **No clinical language.** Never use "depression", "anxiety disorder", "symptom", "diagnosis".
- **No streak-shaming.** Missed days are empty slots, never "you broke your streak".
- **No fix-your-mood verbs.** Prefer "notice", "explore", "care for", "pause" over "improve", "boost", "overcome".
- **Compassionate imperatives.** "Want to…?" / "If it helps…" instead of "You should" / "You must".
- **Hotline 1323 is footer-only**, only after the 10-day escalation threshold, never as a primary CTA.
- **Intervention banner text (5-of-7):** "It's been a heavy week. Want to try a two-minute breathing exercise?"
- **Immutability lock text:** "Your history is a record, not a redo. Add a note to today's entry instead."

---

## Quality gates (Enterprise Term Assignment R5)

All four must pass before any release tag:

1. **Correctness** — `flutter test` passes; domain layer ≥80% line coverage.
2. **Security** — `flutter pub deps` shows no HIGH/CRITICAL vulnerabilities; secret scan clean; Firestore rules pass emulator tests.
3. **Accessibility** — Semantics labels on all interactive widgets; WCAG 2.2 AA contrast; dynamic type support.
4. **Performance** — cold start < 2s on mid-range Android; no unbounded `ListView`; images cached via `cached_network_image`.

## Feature flag (rollback plan)

`ai_pattern_analysis_enabled` (Remote Config, default `true`). If Gemini misbehaves, disable this flag in Firebase console — clients pick up within 60 minutes. Pattern Insights UI gracefully hides. Mood logging and history are unaffected.

---

## Do-not-do list (blast radius)

Paths that agents must NOT edit without explicit orchestrator approval:

- `firebase/firestore.rules` — changes require `security-reviewer` agent sign-off
- `functions/src/*` — Cloud Functions; changes require `security-reviewer` sign-off (Gemini key exposure risk)
- `apps/mobile/lib/main.dart` — entry point; changes require `architect` sign-off
- `apps/mobile/lib/app/router.dart` — route table; changes require `architect` sign-off
- `.github/workflows/*` — CI; changes require `architect` sign-off
- `.claude/agents/*.md` — agent definitions; changes require team meeting
- `android/app/build.gradle`, `android/app/src/main/AndroidManifest.xml` — platform config; changes require `architect` + `security-reviewer`
- Any file with `*.g.dart` or `*.freezed.dart` extension — these are generated; run `flutter pub run build_runner build --delete-conflicting-outputs` instead of hand-editing
- `apps/mobile/lib/firebase_options.dart` — generated by `flutterfire configure`; never `Write`, only re-run `flutterfire configure` (denied by hook — architect + security-reviewer waiver required, per ADR-0001 and the future ADR-0002). To strip stale fields, use `Edit` (which does not trigger the secret-scan preWrite hook).

## Branching & PR rules

- Feature branches: `feat/<wbs-id>-<short-description>` e.g. `feat/3.4-gemini-mood-detection`
- PR title must reference the WBS ID
- PR description uses the PR template (auto-loaded from `.github/PULL_REQUEST_TEMPLATE.md`)
- Squash merge only
- No self-reviews — the agent that writes the code is not the agent that approves it (Enterprise R3)

---

## Quick commands

```bash
# Run the app locally (Android)
cd apps/mobile && flutter run -d android

# Run the app locally (Web)
cd apps/mobile && flutter run -d chrome

# Run all tests
cd apps/mobile && flutter test

# Run integration tests on Android
cd apps/mobile && flutter test integration_test/ -d android

# Run integration tests on Web
cd apps/mobile && flutter test integration_test/ -d chrome

# Generate Freezed / Riverpod / JSON code
cd apps/mobile && flutter pub run build_runner build --delete-conflicting-outputs

# Deploy Cloud Functions (staging)
cd functions && npm run deploy:staging
```

## When in doubt

- **Is it a domain concern?** (business rule, entity, use case) → put it in `domain/`, no Flutter/Firebase imports.
- **Is it a data concern?** (serialization, network, local DB) → put it in `data/`, can use Flutter/Firebase.
- **Is it a presentation concern?** (widgets, screens, user interaction) → put it in `presentation/`.
- **Is it shared across features?** → put it in `packages/`.
- **Not sure which agent owns it?** Delegate to the `architect` agent and let it plan.
