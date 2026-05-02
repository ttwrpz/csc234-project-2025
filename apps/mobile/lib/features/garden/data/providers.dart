import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mood/data/providers.dart';
import '../../mood/domain/entities/mood_entry.dart';
import '../domain/entities/garden_state.dart';
import '../domain/usecases/compute_garden_state.dart';

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
