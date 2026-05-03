# Handoff Brief — Mood Logging UI

**WBS:** 3.2
**Sprint:** S2 (Day 4 Apr 27 → Day 5 Apr 28)
**Target branch:** `feat/3.2-mood-logging-ui` (stacked on `feat/2.1-auth`)
**Depends on:** WBS 3.1 (`MoodEntry`, `MoodDraft`, `MoodRepository`, `MoodFailure`), WBS 2.1 (`currentUserStreamProvider`), WBS 6.1 (design-system tokens, GoRouter shell)

## Summary
A signed-in user taps the centre "Log" tab in the bottom nav, picks one of six mood types from a 3×2 grid, sets an intensity from 1 to 5 with a tall haptic slider, optionally writes up to 500 characters of context, and taps "Save". On success the entry is persisted to `users/{uid}/moods/{moodId}` via the existing `MoodRepositoryImpl.save`, and the user is routed to `/history` (still a placeholder this sprint — that's fine, the route already exists in the StatefulShellRoute). No AI, no garden, no immutability enforcement — those land in S3+.

## Domain shape

### NEW — `SaveMoodEntry` use case
`apps/mobile/lib/features/mood/domain/usecases/save_mood_entry.dart`. One file, one class, single `call()`. Co-locate the Riverpod provider in the same file (match the auth use-case pattern). Exact signature:

```dart
class SaveMoodEntryUseCase {
  const SaveMoodEntryUseCase({
    required MoodRepository repository,
    DateTime Function() now = DateTime.now,
  });

  Future<Result<MoodEntry, MoodFailure>> call({
    required String userId,
    required MoodDraft draft,
  });
}

@riverpod
SaveMoodEntryUseCase saveMoodEntryUseCase(SaveMoodEntryUseCaseRef ref) =>
    SaveMoodEntryUseCase(repository: ref.watch(moodRepositoryProvider));
```

Internal flow:
1. Reject if `draft.mood == null` → `Err(MoodFailure.malformed('mood is required'))`.
2. Build a transient `MoodEntry` via `MoodEntry.create(id: '', userId: userId, mood: draft.mood!, intensity: draft.intensity, text: draft.text, createdAt: now(), mediaRefs: draft.mediaRefs)`. The empty `id` is intentional — `MoodFirestoreDatasource.create` allocates the Firestore doc id and the mapper round-trips it back. (See `mood_repository_impl.dart` lines 61–77.) **Do not** change `MoodEntry.create`'s `id.isEmpty` guard; instead, pass a placeholder like `'pending'` and rely on the repo to overwrite it. Architect default: `'pending'`. Flutter-engineer may pass any non-empty sentinel.
3. Forward to `repository.save(entry)` and return its `Result` directly. The repo returns the populated `MoodEntry` (Firestore-allocated id + server timestamps already mapped) — controller can use it directly with no further transformation.

### Reused (no changes)
- `apps/mobile/lib/features/mood/domain/entities/mood_entry.dart` — `MoodEntry` + `MoodEntry.create` factory.
- `apps/mobile/lib/features/mood/domain/entities/mood_draft.dart` — `MoodDraft` controller state with `isReadyToSave` getter.
- `apps/mobile/lib/features/mood/domain/entities/mood_type.dart` — six-value enum.
- `apps/mobile/lib/features/mood/domain/mood_repository.dart` — abstract `MoodRepository`.
- `apps/mobile/lib/features/mood/domain/mood_failure.dart` — sealed failure type.

### Pure-Dart invariants (qa-engineer test targets)
1. `SaveMoodEntryUseCase` rejects `draft.mood == null` before touching the repo.
2. `SaveMoodEntryUseCase` propagates `MoodFailure.invalidIntensity` when `draft.intensity` is outside 1..5 (delegated to `MoodEntry.create`).
3. `SaveMoodEntryUseCase` propagates `MoodFailure.textTooLong` when `draft.text.length > 500`.
4. Happy path: returns `Ok(MoodEntry)` whose `id` is the Firestore-allocated id (verified via fake repo).

## Data shape
**No changes.** `MoodRepositoryImpl`, `MoodFirestoreDatasource`, mappers, DTOs, `moodRepositoryProvider` are all already in place from WBS 3.1. The Firestore collection at `users/{uid}/moods/{moodId}` is unchanged. The per-user-isolation rule stub at `firebase/firestore.rules` is sufficient for Day 5 demo (orchestrator deploys manually with `firebase deploy --only firestore:rules`; flutter-engineer does not deploy).

## Presentation shape

### `LogMoodScreen` layout
`apps/mobile/lib/features/mood/presentation/log_mood_screen.dart` — `ConsumerWidget`. Match `sign_in_screen.dart` structure: `Scaffold` → `AppBar(title: Text('How are you feeling?'))` → `SafeArea` → `Padding(EdgeInsets.symmetric(horizontal: MoodBloomSpacing.xl))` → `ListView`. Vertical order:
1. `SizedBox(height: MoodBloomSpacing.xl)`
2. Section label "Pick a mood" (`Theme.of(context).textTheme.titleMedium`).
3. `MoodTypeGrid`.
4. `SizedBox(height: MoodBloomSpacing.xl)`.
5. Section label "How intense?".
6. `IntensityDots` (5 dots, current intensity filled).
7. `IntensitySlider` (1..5 discrete, 48dp+ tall, haptic at each tick).
8. `SizedBox(height: MoodBloomSpacing.xl)`.
9. Section label "Want to add a note?" (compassionate copy per CLAUDE.md).
10. `MoodTextField` (multi-line, max 500, counter `{n}/500`).
11. Optional inline error (`state.errorMessage`) — same style as `sign_in_screen.dart` lines 49–57.
12. `SizedBox(height: MoodBloomSpacing.lg)`.
13. Full-width `FilledButton` "Save" — disabled when `state.mood == null` or `state.isSubmitting`. While `isSubmitting` show 20×20 `CircularProgressIndicator(strokeWidth: 2)` (same pattern as sign-in submit).
14. `SizedBox(height: MoodBloomSpacing.xl)`.

### Widgets

1. **`MoodTypeTile`** — `apps/mobile/lib/features/mood/presentation/widgets/mood_type_tile.dart`. Stateless. Inputs: `MoodType type`, `bool selected`, `VoidCallback onTap`. Renders an `InkWell` over an `AspectRatio(aspectRatio: 1)` card. When `selected`, fills the background with `MoodBloomColors.mood<Type>` (lookup table). When not, neutral surface. Label below uses the lowercased enum name (e.g. "happy"). Min height 64dp. Semantics label: `'<type>, intensity selector tile, ${selected ? "selected" : "not selected"}'`.

2. **`MoodTypeGrid`** — `apps/mobile/lib/features/mood/presentation/widgets/mood_type_grid.dart`. `GridView.count(crossAxisCount: 3, shrinkWrap: true, physics: NeverScrollableScrollPhysics(), mainAxisSpacing: MoodBloomSpacing.md, crossAxisSpacing: MoodBloomSpacing.md, children: MoodType.values.map(...))`. 3×2 layout for the six values. Inputs: `MoodType? selected`, `ValueChanged<MoodType> onSelect`.

3. **`IntensitySlider`** — `apps/mobile/lib/features/mood/presentation/widgets/intensity_slider.dart`. Wraps Material `Slider` with `min: 1, max: 5, divisions: 4, value: intensity.toDouble()`. Wrap in `SizedBox(height: MoodBloomSpacing.tapTargetMin)` (tapTargetMin must be ≥48 — verify in `MoodBloomSpacing`; if missing, add a constant in design tokens, otherwise use 56). Inputs: `int intensity`, `ValueChanged<int> onChanged`. On `onChangeStart` and on each integer step transition trigger `HapticFeedback.selectionClick()` from `package:flutter/services.dart` — but **gate on `defaultTargetPlatform == TargetPlatform.android` and `!kIsWeb`** (Web has no haptic; iOS not in scope this sprint). Semantics value: `'$intensity of 5'`.

4. **`IntensityDots`** — `apps/mobile/lib/features/mood/presentation/widgets/intensity_dots.dart`. `Row` of 5 `Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: i < intensity ? MoodBloomColors.seed : MoodBloomColors.outline))` separated by `SizedBox(width: MoodBloomSpacing.sm)`. Stateless; `intensity` is the only input. Excluded from semantics tree (`ExcludeSemantics`) — the slider already announces.

5. **`MoodTextField`** — `apps/mobile/lib/features/mood/presentation/widgets/mood_text_field.dart`. `TextField(maxLength: 500, maxLines: null, minLines: 3, keyboardType: TextInputType.multiline, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(hintText: 'A line about your day, if you like.', counterText: defaults))`. Default `TextField` `maxLength` already shows `{n}/500` counter — do not customise. Inputs: `String value`, `ValueChanged<String> onChanged`.

### Controller — `LogMoodController`
`apps/mobile/lib/features/mood/presentation/controllers/log_mood_controller.dart`. Match `sign_in_controller.dart` style (`@riverpod` codegen, controller delegates to use case, controller does NOT navigate). Two divergences from auth pattern, called out:

1. **State is `MoodDraft` directly, not a wrapper Freezed class.** `MoodDraft` already exists in domain and is the canonical in-progress shape; do not duplicate it. The transient UI fields (`isSubmitting`, `errorMessage`) ride on a sibling provider — see below.
2. The submission status lives in a separate `LogMoodSubmissionState` Freezed at `apps/mobile/lib/features/mood/presentation/controllers/log_mood_submission_state.dart` with `bool isSubmitting`, `String? errorMessage`. The screen watches both.

```dart
@riverpod
class LogMoodController extends _$LogMoodController {
  @override
  MoodDraft build() => MoodDraft.empty();

  void pickMood(MoodType m) => state = state.copyWith(mood: m);
  void setIntensity(int v) => state = state.copyWith(intensity: v);
  void setText(String t) => state = state.copyWith(text: t);

  Future<MoodEntry?> save() async {
    final submission = ref.read(logMoodSubmissionControllerProvider.notifier);
    final user = ref.read(currentUserStreamProvider).value;
    if (user == null) {
      submission.fail('You need to be signed in.'); // defensive; router prevents
      return null;
    }
    submission.begin();
    final usecase = ref.read(saveMoodEntryUseCaseProvider);
    final result = await usecase(userId: user.uid, draft: state);
    return result.fold(
      ok: (entry) { submission.succeed(); state = MoodDraft.empty(); return entry; },
      err: (f)    { submission.fail(f.message); return null; },
    );
  }
}
```

`LogMoodSubmissionController` is a sibling `@riverpod class` holding `LogMoodSubmissionState` with `begin() / succeed() / fail(String)` methods. The screen handles navigation: after `await controller.save()` returns non-null, call `if (context.mounted) context.go('/history')`. **The controller never imports `package:go_router` or `BuildContext`.**

### Navigation
Edit `apps/mobile/lib/app/router.dart` lines 88–94: replace the `_PlaceholderScreen` builder for `/log-mood` with `(c, s) => const LogMoodScreen()`. Add the import at the top of router.dart (`import '../features/mood/presentation/log_mood_screen.dart';`). No other router changes. Architect sign-off pre-granted by this brief.

## Handoffs

### → flutter-engineer
Create files in this order (each compiles on its own — codegen runs at the end):

1. `apps/mobile/lib/features/mood/domain/usecases/save_mood_entry.dart`
2. `apps/mobile/lib/features/mood/presentation/controllers/log_mood_submission_state.dart`
3. `apps/mobile/lib/features/mood/presentation/controllers/log_mood_submission_controller.dart`
4. `apps/mobile/lib/features/mood/presentation/controllers/log_mood_controller.dart`
5. `apps/mobile/lib/features/mood/presentation/widgets/mood_type_tile.dart`
6. `apps/mobile/lib/features/mood/presentation/widgets/mood_type_grid.dart`
7. `apps/mobile/lib/features/mood/presentation/widgets/intensity_dots.dart`
8. `apps/mobile/lib/features/mood/presentation/widgets/intensity_slider.dart`
9. `apps/mobile/lib/features/mood/presentation/widgets/mood_text_field.dart`
10. `apps/mobile/lib/features/mood/presentation/log_mood_screen.dart`
11. Update `apps/mobile/lib/app/router.dart` (one-line builder swap + one import).
12. Run `flutter pub run build_runner build --delete-conflicting-outputs`.

Conventions: 100-char lines; design-system tokens only (no hardcoded colors/sizes outside `packages/design_system/`); copy rules from CLAUDE.md (no "improve your mood", no "broke your streak"); private members prefixed `_`; no `print()`; no `!` null-assertion; `Logger` from `packages/core/` if logging at all (and never log mood text — PII rule).

**Do not touch:**
- `apps/mobile/lib/features/auth/**`
- `apps/mobile/lib/features/onboarding/**`
- `apps/mobile/lib/features/mood/data/**` (repo + datasource + mapper are frozen this sprint)
- `apps/mobile/lib/features/mood/domain/entities/**` (no changes to `MoodEntry` / `MoodDraft` / `MoodType`)
- `apps/mobile/lib/features/mood/domain/mood_repository.dart`, `mood_failure.dart`
- `firebase/firestore.rules` (orchestrator deploys current stub manually)
- `functions/**`
- `apps/mobile/lib/main.dart`
- Any other route in `router.dart` besides the `/log-mood` builder swap.

### → qa-engineer (Day 5)
Unit tests (write alongside the use case, same PR):
- `apps/mobile/test/features/mood/domain/usecases/save_mood_entry_test.dart` — covers invariants 1–4 above using a fake `MoodRepository` (override `moodRepositoryProvider` via `ProviderContainer`).

Widget tests (Day 5):
- `apps/mobile/test/features/mood/presentation/log_mood_screen_test.dart` — Save button is disabled when no mood is picked; tapping a tile enables Save; tapping Save calls the controller's `save()` (override `saveMoodEntryUseCaseProvider` with a fake returning `Ok`).
- `apps/mobile/test/features/mood/presentation/widgets/intensity_slider_test.dart` — slider starts at 3, dragging emits integer values 1..5, Semantics value is `'<n> of 5'`, host has min height ≥ 48dp.
- `apps/mobile/test/features/mood/presentation/widgets/mood_type_grid_test.dart` — renders 6 tiles; tapping a tile invokes `onSelect` with the right `MoodType`; selected tile has correct `MoodBloomColors.mood<Type>` background (golden-style `find.byWidgetPredicate`).

These three widget tests count toward the four-widget-test minimum in the Sprint 2 acceptance criteria.

### → security-reviewer (Day 5 audit)
Audit checklist:
- [ ] **R-101 No mood-text in logs.** Grep `lib/features/mood/presentation/` for `Logger.`, `log(`, `print(`, `debugPrint(`. No call site may pass `state.text`, `draft.text`, `entry.text`, `MoodDraft`, `MoodEntry`, or any concatenation that could include them.
- [ ] **R-102 No userId+text correlation in logs.** Even on error paths, log the `MoodFailure` variant only, never the draft.
- [ ] **R-103 Domain purity.** `apps/mobile/lib/features/mood/domain/usecases/save_mood_entry.dart` imports zero `package:flutter/*`, `package:firebase_*/*`, `package:cloud_firestore/*`. Re-run the domain-purity hook after merge.
- [ ] **R-104 Firestore rule stub still in place.** `firebase/firestore.rules` enforces per-user isolation under `users/{uid}/moods/**`. No change expected this sprint; verify the file was not edited as a side effect.
- [ ] **R-105 No secrets in source.** No API keys, no service-account JSON; standard secret-scan hook output is clean on the diff.
- [ ] **R-106 Auth-state guard.** `LogMoodController.save()` reads `currentUserStreamProvider` and bails on null. Confirm there is no path where a null-uid write is attempted against Firestore (the router already prevents reaching the screen unauthenticated; this is defense-in-depth).

## Acceptance Criteria
From `.claude/prompts/sprint-2-kickoff.md` lines 80–87 and HB-002 specifics, the feature is complete when:
- [ ] User can log a mood with intensity 1–5 and save it to Firestore (online write; offline-first is S3).
- [ ] Six mood tiles render in a 3×2 grid; selected tile is tinted with `MoodBloomColors.mood<Type>`.
- [ ] Intensity slider host is ≥ 48dp tall and steps through values 1–5 only (Lin's US-Lin-3).
- [ ] On Android physical device, dragging the slider produces haptic feedback at each integer tick. On Web (Chrome) the screen renders and saves with no haptic and no console error.
- [ ] Text field enforces 500-char hard limit and shows the `{n}/500` counter.
- [ ] Save button is disabled when no mood is selected or while the save is in flight, and shows a 20×20 `CircularProgressIndicator` while submitting (matches sign-in pattern).
- [ ] On success the user is routed to `/history`.
- [ ] On failure (`MoodFailure.network` simulated by airplane mode) the screen surfaces `failure.message` inline above the Save button and the draft is preserved.
- [ ] Domain layer is clean: `grep -r "import 'package:flutter" apps/mobile/lib/features/mood/domain/` returns nothing; same for `firebase_*` and `cloud_firestore`.
- [ ] CI green on `feat/3.2-mood-logging-ui`: `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test` all pass.

## Open Questions for orchestrator
1. **Lin's US-Lin-3 haptic semantics on the 48dp+ slider.** The Material `Slider` thumb is ~24dp tall by default. We meet the ≥48dp tap target by wrapping the slider in a `SizedBox(height: 56)` (drag region extends the full host). Is that acceptable to Lin, or does the persona require the *visual* track to be 48dp? Architect default: **wrap-host is fine; track height stays default**. Confirm with Napat (UI/UX Lead) before Day 5 demo.
2. **Mood tile content: emoji vs Material icon vs nothing.** CLAUDE.md does not specify. Architect default: **no emoji this sprint, label only** — emoji handling is locale-sensitive and we have no a11y review yet. Add an icon in S3 garden work (HB-005-ish) when the iconography is curated. Flutter-engineer must not invent emoji.
3. **Save button in-flight indicator.** Specified above as 20×20 `CircularProgressIndicator(strokeWidth: 2)` matching `sign_in_screen.dart` lines 64–69. Confirmed; this is not a question, only a callout.
4. **Sentinel id for `MoodEntry.create` in the use case.** `MoodEntry.create` rejects empty `id`. Architect default: pass `'pending'` and rely on `MoodFirestoreDatasource.create` + mapper to overwrite with the Firestore-allocated id on the round trip. Alternative: relax `MoodEntry.create` to accept empty id when `MoodEntry` is "transient" — rejected because it weakens the entity invariant for the sake of one caller.
