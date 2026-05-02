import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../mood/data/providers.dart';
import '../../mood/domain/entities/mood_entry.dart';
import '../domain/entities/garden_state.dart';
import '../domain/entities/intervention_state.dart';
import '../domain/pattern_detector.dart';
import '../domain/usecases/compute_garden_state.dart';
import 'intervention_state_storage.dart';

/// Garden has no Firestore-backed data layer of its own — it is a derived
/// view over the mood feed. The providers in this file just wire the pure
/// use case to the existing `myMoodsStreamProvider`.

/// Pure-Dart use case provider. Const constructor → safe to overrideWithValue
/// in tests (the use case has no state).
final computeGardenStateUseCaseProvider = Provider<ComputeGardenStateUseCase>((
  ref,
) {
  return const ComputeGardenStateUseCase();
});

/// Reactive `GardenState` derived from the signed-in user's mood stream.
///
/// We watch the upstream `AsyncValue<List<MoodEntry>>` directly (not via the
/// deprecated `.stream` accessor) and map each non-loading state through the
/// pure use case. `DateTime.now()` is captured on every recompute so the
/// bloom bar / streak roll forward when the underlying stream re-emits (e.g.
/// a fresh mood log). Crossing midnight without a new emission is
/// acceptable — the bar refreshes on the next interaction.
final gardenStateStreamProvider = Provider<AsyncValue<GardenState>>((ref) {
  final useCase = ref.watch(computeGardenStateUseCaseProvider);
  final moods = ref.watch(myMoodsStreamProvider);
  return moods.whenData(
    (entries) => useCase(entries: entries, now: DateTime.now()),
  );
});

/// Underlying mood entries the garden canvas iterates to render per-entry
/// glyphs (flower / wilting plant / rain cloud). Mirrors
/// [myMoodsStreamProvider] under a garden-namespaced alias so the screen
/// can compose state + entries without reaching into the mood feature's
/// providers directly. WBS 4.3 — Day 2.
final gardenEntriesStreamProvider = Provider<AsyncValue<List<MoodEntry>>>(
  (ref) => ref.watch(myMoodsStreamProvider),
);

/// SharedPreferences-backed [InterventionStateStorage]. Resolves once
/// `sharedPreferencesProvider` does. Tests override the underlying
/// `sharedPreferencesProvider` with a fake from
/// `SharedPreferences.setMockInitialValues({...})`.
final interventionStateStorageProvider =
    FutureProvider<InterventionStateStorage>((ref) async {
      final prefs = await ref.watch(sharedPreferencesProvider.future);
      return InterventionStateStorage(prefs);
    });

/// Pipes the live mood stream through [detectPattern], applying the
/// persisted `last_triggered_at` / `first_triggered_at` anchors so the
/// 48h cooldown and 10-day escalation rules are honoured across cold
/// launches.
///
/// Sprint 4 is read-only on this provider — the garden screen does NOT
/// render any UI for the result. Sprint 5's cheer-up banner reads this
/// provider and owns the WRITE side (calling
/// `storage.writeLastTriggeredAt(...)` when the user dismisses the
/// banner). Keeping the writes out of S4 means a flaky detector cannot
/// silently mutate user-visible state before the banner exists to
/// explain it.
final interventionStateProvider = Provider<AsyncValue<InterventionState>>((
  ref,
) {
  final moodsAsync = ref.watch(myMoodsStreamProvider);
  final storageAsync = ref.watch(interventionStateStorageProvider);

  if (storageAsync.isLoading) return const AsyncValue.loading();
  final storage = storageAsync.valueOrNull;
  if (storage == null) {
    return AsyncValue.error(
      storageAsync.error ?? StateError('storage unavailable'),
      storageAsync.stackTrace ?? StackTrace.current,
    );
  }

  return moodsAsync.whenData((entries) {
    return detectPattern(
      entries,
      now: DateTime.now(),
      lastTriggeredAt: storage.readLastTriggeredAt(),
      firstTriggeredAt: storage.readFirstTriggeredAt(),
    );
  });
});
