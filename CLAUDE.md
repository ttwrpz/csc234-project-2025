# MoodBloom - Project Memory for Claude Code

This file is loaded into every Claude Code session at the root of the repo. **Keep it short, specific, and current.** It is the single source of truth for conventions every agent in this project must follow.

---

## Product in one sentence

MoodBloom is a cross-platform Flutter mood-tracker for Android and Web that uses AI to assist logging, detects distress patterns compassionately, and visualizes emotional history as a living garden.

## Starting state of the codebase

Sprint 1 (before Apr 21 – Apr 21) produced agile planning artifacts only - **no Flutter feature code was written**. The repo at the start of Sprint 2 contains only:

- `flutter create` scaffold (default `lib/main.dart`, default `pubspec.yaml`)
- `flutterfire configure` output (`lib/firebase_options.dart`, `android/app/google-services.json`)
- `firebase init` baseline (`firebase.json`, empty `firestore.rules`, empty `storage.rules`)
- This bundle: `CLAUDE.md` and `.claude/`

Everything else - folder structure, features, design system, tests, security rules - is built from Sprint 2 onward by the agent team following the per-sprint kickoff prompts. Do not assume any feature, screen, widget, or repository exists until a sprint prompt says it has been built.

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
│   ├── specs/                      (Sprint 4–5 ecosystem spec - formulas, data model, test cases, citations)
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
│   │       ├── pattern_engine/     (S4 - pure-Dart 5-algorithm engine)
│   │       ├── intervention/       (S5 - Tiered Intervention + Quote Library)
│   │       ├── tokens/             (S4 - token economy)
│   │       ├── harvest/            (S4 - weekly harvest cycle)
│   │       ├── disclaimer/         (S5 - bipolar/medical disclaimer service)
│   │       ├── analytics/          (presentation/domain/data)
│   │       ├── insights/           (S5 - pattern insights screen w/ disclaimer ack)
│   │       ├── history/            (presentation/domain/data)
│   │       └── settings/           (presentation/domain/data)
│   ├── test/                       (unit + widget + golden)
│   └── integration_test/
├── packages/
│   ├── design_system/              (tokens, theme, core widgets)
│   ├── core/                       (error types, result wrapper, logger)
│   └── analytics/                  (fl_chart wrappers)
├── functions/                      (TypeScript Cloud Functions - Gemini proxy)
│   └── src/
│       ├── analyzeMoodText.ts
│       ├── analyzePatterns.ts      (S3 - original; superseded by client-side Pattern Engine in S4)
│       └── suggestQuote.ts         (S5 - Tier 1/2 ONLY; Tier 3 never calls this)
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

## Dart style - specific patterns we enforce

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
users/{uid}                          → UserProfile {
                                          displayName, photoUrl, createdAt,
                                          tokenBalance: int (default 0),
                                          tokensEarnedToday: int (resets midnight),
                                          lastTokenEarnedDate: date,
                                          unlockedSkins: map<emotion, [skinId]>,
                                          gardenSettings: { dayNightMode },
                                          insightsDisclaimerAcked: bool (default false)
                                       }
users/{uid}/moods/{moodId}           → MoodEntry { mood, intensity, text, score, createdAt, updatedAt, mediaRefs[], selectedSkinId, weekId }
users/{uid}/weeklyGardens/{weekId}   → WeeklyGarden { weekStart, weekEnd, entries[], healthHistory[], summary, archivedAt }
users/{uid}/patterns/{date}          → PatternResult { mannKendallZ, slidingNegCount, consecutiveHighIntensity, zScoreToday, cusumC, triggeredTier }
users/{uid}/interventions/{id}       → InterventionRecord { tier, dispatchedAt, cooldownUntil, optedOut, quoteId }
users/{uid}/cooldowns/{type}         → { lastDispatchedAt, cooldownUntil }
```

### Security rules (non-negotiable)
- Users can only read/write documents under `users/{request.auth.uid}/**`
- `createdAt` must equal `request.time` on create (server-side timestamp validation)
- `createdAt` is immutable on update
- `updatedAt` must be within 24h of `createdAt` on any update (enforces 24h immutability at the rules level, in addition to the domain guard)
- `tokenBalance` may only increase (or decrease via skin purchase atomic write); never reset on missed days
- `weeklyGardens/{weekId}` is write-once-on-archive, then read-only (history is a record, not a redo)
- Field-level validation via `diff().affectedKeys()` - only specific fields may change on update
- See `firebase/firestore.rules` for canonical rules

---

## The pivot features (what this app IS - Sprint 4–5 ecosystem model)

**Core philosophy:** Plants are NEVER destroyed/wilting/dying in any state. Every mood is weather; the ecosystem holds. This redesign is grounded in self-compassion (Neff 2003), DBT validation (Linehan 1993), ACT "emotions as weather" (Hayes 1999), and narrative externalization (White & Epston 1990). For full citations and formula derivations see `.claude/specs/sprint-4-5-spec.md`.

1. **Intensity slider 1–5** on every entry (domain field: `int intensity`).
2. **Mood Score `S_t = v × i/5`** - pure-Dart domain function, range [-1, +1]. Joy/Calm/Okay are positive; Sadness/Anger/Anxiety are negative.
3. **Gemini AI mood detection** from text via Cloud Function proxy (S3, unchanged).
4. **Garden Health EWMA** - `H_t = 0.15·S_t + 0.85·H_{t-1}`, H_0 = 0 (resets weekly). Maps to 5 plant tiers: Flourishing / Thriving / Resting / Weathering / Storm Season - all alive in every tier.
5. **Daily Atmosphere** - `avg_S_today` drives weather (sunny / calm / light-rain / storm). Resets midnight. Plants stay sheltered in storm.
6. **Pattern Engine - 5 algorithms running on every entry:**
   - **Mann-Kendall trend test** (14-day window) - Z_trend < -1.96 → Tier 1.
   - **Sliding 5-of-7** - 5+ negative days in last 7 → Tier 2.
   - **3-consecutive S ≤ -0.6** → Tier 3.
   - **Z-score** (today vs personal 30-day baseline) - `z_day < -2.5` → Tier 3.
   - **CUSUM** change-point - sustained drops → Tier 3.
7. **Tiered Intervention** - Tier 1 = 2-min breathing; Tier 2 = journaling prompt; Tier 3 = crisis resources + Hotline 1323. **Strict cooldown:** max 1 notification/day, 48h between notifications, opt-out always available.
8. **Personalized quote library** - Tier 1/2 use Gemini hybrid (Gemini suggests, but the Quote Safety Filter only allows pre-approved phrases through; if Gemini output contains anything off-script, fall back to the curated phrase pool). **Tier 3 NEVER calls Gemini** - quotes are CURATED ONLY for deterministic safety.
9. **Bipolar/medical disclaimer** - onboarding slide + mandatory ack-on-first-use of Insights screen + footer line on every intervention notification + Settings restate. Wording: "MoodBloom is not a medical device. It cannot diagnose conditions like bipolar disorder, depression, or anxiety. Consult a qualified professional."
10. **Token economy** - 5–10/day cap, mood-agnostic (logging "Sad intensity 5" earns same as "Joy intensity 5"), never lost on missed days, cosmetic-only (flower skins), never unlocks therapeutic features.
11. **Weekly Harvest cycle** - garden archives every 7 days to History. H_0 resets to 0. Past weeks fully preserved and browsable.
12. **24-hour entry immutability** - same-day edit/delete allowed; locked thereafter (S3, unchanged).

## Copy rules (user-facing text - non-negotiable, reviewer agents check)

### NEVER use these words for the garden:
- "delete," "clear," "reset," "lost," "destroyed," "wilted," "wilting," "dead," "dying"

### ALWAYS use these instead:
- "harvest," "complete," "new chapter," "fresh week," "sheltered," "resting"

### Other rules:
- **No clinical language.** Never use "depression," "anxiety disorder," "symptom," "diagnosis," "bipolar" *as a label for the user*. Use "bipolar" only in the disclaimer.
- **No streak-shaming.** Missed days are empty slots, never "you broke your streak."
- **No fix-your-mood verbs.** Prefer "notice," "explore," "care for," "pause" over "improve," "boost," "overcome."
- **No mood-contingent rewards.** Never "earn by feeling better." Tokens are for showing up, not for mood content.
- **Compassionate imperatives.** "Want to…?" / "If it helps…" instead of "You should" / "You must."
- **Hotline 1323 footer** appears on Tier 3 only, never as a primary CTA. (Keeps the Sprint 1–3 wording for backward compatibility - but now triggered by Tier 3, not by 10-day escalation.)

### Pre-approved intervention phrasing (Tier copy):
- **Tier 1:** "It looks like your garden has had some rainy days. Would you like a 2-minute breathing exercise?"
- **Tier 2:** "Would you like to write about what's been on your mind?"
- **Tier 3:** "We care about you. Here are some resources that might help." + crisis line links + Hotline 1323.
- **Storm atmosphere captions:** "Storms pass. The roots hold." / "Rain helps the soil."
- **Weekly harvest banner:** "Your garden this week has been harvested and saved to your history. A new week begins - a fresh canvas for your story."
- **Disclaimer footer (every notification):** "MoodBloom is not a medical device. Not a substitute for professional care."
- **Disclaimer ack dialog (first Insights view):** "MoodBloom is not a medical device. It cannot diagnose conditions like bipolar disorder, depression, or anxiety. Consult a qualified professional. [I understand]"

---

## Quality gates (Enterprise Term Assignment R5)

All four must pass before any release tag:

1. **Correctness** - `flutter test` passes; domain layer ≥80% line coverage.
2. **Security** - `flutter pub deps` shows no HIGH/CRITICAL vulnerabilities; secret scan clean; Firestore rules pass emulator tests.
3. **Accessibility** - Semantics labels on all interactive widgets; WCAG 2.2 AA contrast; dynamic type support.
4. **Performance** - cold start < 2s on mid-range Android; no unbounded `ListView`; images cached via `cached_network_image`.

## Feature flag (rollback plan)

`ai_pattern_analysis_enabled` (Remote Config, default `true`). Originally for the S3 Gemini pattern-analysis function. In S4–S5 the Pattern Engine moved to client-side pure-Dart code (5 algorithms), so this flag now gates **the Tier 1/2 Gemini quote suggestion path** (S5 feature 8). If Gemini misbehaves on quote generation, disable this flag - Tier 1/2 falls back to curated phrases. Mood logging, history, pattern detection, and Tier 3 are unaffected (Tier 3 was never Gemini-driven).

## Sprint 4–5 ecosystem spec

The full Sprint 4–5 specification - formulas with worked examples, data model, all 35 test cases, copy guidelines, and academic citations - lives at `.claude/specs/sprint-4-5-spec.md`. **All agents must read this spec before working on any S4–S5 task.** It is the authoritative source for:

- Mood Score formula and intensity sign mapping
- Garden Health EWMA derivation (why α=0.15)
- All 5 pattern detection algorithms with worked examples
- Tiered Intervention dosing rules and cooldown logic
- Quote Library tier-3-curated-only safety rule
- Bipolar/medical disclaimer placement and exact wording
- Token economy guardrails
- Weekly Harvest cycle copy rules
- 35 acceptance test cases (Part 7 of the spec)

---

## Do-not-do list (blast radius)

Paths that agents must NOT edit without explicit orchestrator approval:

- `firebase/firestore.rules` - changes require `security-reviewer` agent sign-off
- `functions/src/*` - Cloud Functions; changes require `security-reviewer` sign-off (Gemini key exposure risk)
- `apps/mobile/lib/main.dart` - entry point; changes require `architect` sign-off
- `apps/mobile/lib/app/router.dart` - route table; changes require `architect` sign-off
- `.github/workflows/*` - CI; changes require `architect` sign-off
- `.claude/agents/*.md` - agent definitions; changes require team meeting
- `android/app/build.gradle`, `android/app/src/main/AndroidManifest.xml` - platform config; changes require `architect` + `security-reviewer`
- Any file with `*.g.dart` or `*.freezed.dart` extension - these are generated; run `flutter pub run build_runner build --delete-conflicting-outputs` instead of hand-editing

## Branching & PR rules

- Feature branches: `feat/<wbs-id>-<short-description>` e.g. `feat/3.4-gemini-mood-detection`
- PR title must reference the WBS ID
- PR description uses the PR template (auto-loaded from `.github/PULL_REQUEST_TEMPLATE.md`)
- Squash merge only
- No self-reviews - the agent that writes the code is not the agent that approves it (Enterprise R3)

---

## Testing during iteration (READ BEFORE RUNNING TESTS)

The full test suite takes ~5 minutes. Running it after every edit is the single biggest source of wasted wall-clock time in this project. The harness MUST follow these rules:

### When to run tests

- **DO NOT** run `flutter test` after every edit.
- Run `flutter analyze` after every batch of edits - it is fast (~30s warm, ~70s cold) and catches the same class of breakage for most refactors.
- Run tests ONLY when:
  - (a) the user explicitly asks ("run the tests", "check tests pass", etc.)
  - (b) you are about to mark a TaskCreate/TaskUpdate task as `completed`
  - (c) you are about to commit, push, or open a PR
  - (d) you just changed a domain algorithm, a Firestore rule, a Riverpod provider graph, or anything in `lib/app/` (router, theme, providers)

### How to run tests (scope-first)

Always run the **narrowest** scope that exercises the touched code:

```bash
# Single file - fastest, use when you changed exactly one widget/service
cd apps/mobile && flutter test test/features/<feature>/path/to/specific_test.dart

# Feature directory - use when you changed multiple files in one feature
cd apps/mobile && flutter test test/features/<feature>/

# Name regex - use when iterating on one test
cd apps/mobile && flutter test --name "<regex>"

# Parallel + skip slow shader-bound + golden tests
cd apps/mobile && flutter test --concurrency=8 --exclude-tags=golden,shader

# Full suite - ONLY for (b) or (c) above
cd apps/mobile && flutter test --concurrency=8 --exclude-tags=golden,shader
```

Scope heuristics:
- **Domain-only edit** (`lib/features/<x>/domain/`) → `flutter test test/features/<x>/domain/`. Skip widget tests entirely.
- **UI-only edit** (`lib/features/<x>/presentation/`) → `flutter test test/features/<x>/presentation/`. Skip domain tests.
- **Color/copy edit** (one or two lines, no logic) → `flutter analyze` only. Do not run tests.
- **Router or provider graph edit** → `flutter test test/app/`.
- **Pattern engine threshold edit** → `flutter test test/features/pattern_engine/`.

### Other speed rules

- **Never** run `flutter clean` between iterations - it cold-starts the build cache and adds 2-3 minutes.
- **Never** pass `--coverage` during iteration - it roughly doubles test time. Reserve it for end-of-task verification (rule (c)).
- The `ink_sparkle.frag` shader-version mismatch on this machine causes ~25 widget tests to fail with `Unsupported runtime stages format version. Expected 2, got 1`. This is an environment issue, NOT a regression. If only those tests fail, the suite is green - verify by running `flutter test --exclude-tags=shader`.
- If a test you just modified hangs, kill it and rerun with `--reporter=expanded` to see which case is stuck. Do not retry the full suite in a loop.

---

## Quick commands

```bash
# Run the app locally (Android)
cd apps/mobile && flutter run -d android

# Run the app locally (Web) - pinned to port 5173 so the dev origin
# matches functions/.env's WEBAUTHN_STAGING_ORIGINS (required for the
# WebAuthn "Use security key" flow to verify). Pick one:
./scripts/run_web.ps1                                     # Windows
./scripts/run_web.sh                                      # macOS / Linux
cd apps/mobile && flutter run -d chrome --web-port=5173   # raw form
# Or press F5 in VS Code - .vscode/launch.json ships a pinned config.

# Run all tests
cd apps/mobile && flutter test

# Run integration tests on Android
cd apps/mobile && flutter test integration_test/ -d android

# Run integration tests on Web
cd apps/mobile && flutter test integration_test/ -d chrome

# Generate Freezed / Riverpod / JSON code
cd apps/mobile && flutter pub run build_runner build --delete-conflicting-outputs

# Deploy Cloud Functions (builds then `firebase deploy --only functions`
# against the default project - there is no separate staging project).
cd functions && pnpm run deploy
```

## When in doubt

- **Is it a domain concern?** (business rule, entity, use case) → put it in `domain/`, no Flutter/Firebase imports.
- **Is it a data concern?** (serialization, network, local DB) → put it in `data/`, can use Flutter/Firebase.
- **Is it a presentation concern?** (widgets, screens, user interaction) → put it in `presentation/`.
- **Is it shared across features?** → put it in `packages/`.
- **Not sure which agent owns it?** Delegate to the `architect` agent and let it plan.
