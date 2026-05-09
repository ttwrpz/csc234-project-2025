import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../auth/data/providers.dart';
import '../../mood/data/providers.dart';
import '../../mood/domain/entities/mood_entry.dart';
import '../domain/cheer_up_events_repository.dart';
import '../domain/entities/garden_state.dart';
import '../domain/entities/intervention_state.dart';
import '../domain/intervention_state_repository.dart';
import '../domain/pattern_detector.dart';
import '../domain/usecases/compute_garden_state.dart';
import 'cheer_up_events_repository_impl.dart';
import 'datasources/cheer_up_events_firestore_datasource.dart';
import 'datasources/intervention_state_firestore_datasource.dart';
import 'intervention_state_repository_impl.dart';
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
/// daily-score strip + atmosphere roll forward when the underlying stream
/// re-emits (e.g. a fresh mood log). Crossing midnight without a new
/// emission is acceptable — the strip refreshes on the next interaction.
///
/// `weekStart` is the local-midnight `DateTime` of the current week's
/// Monday. `H_t` resets to 0 on every fresh week (weekly harvest cycle —
/// ADR-0010 §3).
final gardenStateStreamProvider = Provider<AsyncValue<GardenState>>((ref) {
  final useCase = ref.watch(computeGardenStateUseCaseProvider);
  final moods = ref.watch(myMoodsStreamProvider);
  return moods.whenData((entries) {
    final now = DateTime.now();
    return useCase(
      entries: entries,
      now: now,
      weekStart: _localMondayMidnight(now),
    );
  });
});

/// Local-midnight `DateTime` of the Monday of the week containing [now].
/// Pure helper colocated with the provider — kept private because the
/// domain layer should not own week-start semantics (those are presentation /
/// product policy: Monday vs Sunday vs ISO weeks).
DateTime _localMondayMidnight(DateTime now) {
  final local = now.toLocal();
  final daysFromMonday = local.weekday - DateTime.monday;
  final monday = DateTime(
    local.year,
    local.month,
    local.day,
  ).subtract(Duration(days: daysFromMonday));
  return monday;
}

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
///
/// Per ADR-0008 this is the OFFLINE MIRROR for [InterventionAnchors],
/// not the source of truth — the cloud doc at
/// `users/{uid}/interventionState/current` is canonical. Read+write
/// callers go through [interventionStateRepositoryProvider].
final interventionStateStorageProvider =
    FutureProvider<InterventionStateStorage>((ref) async {
      final prefs = await ref.watch(sharedPreferencesProvider.future);
      return InterventionStateStorage(prefs);
    });

/// Thin Firestore datasource for the
/// `users/{uid}/interventionState/current` doc. Tests fake this
/// provider via `overrideWithValue` to avoid spinning up a real
/// `FirebaseFirestore`.
final interventionStateFirestoreDatasourceProvider =
    Provider<InterventionStateFirestoreDatasource>(
      (ref) =>
          InterventionStateFirestoreDatasource(ref.watch(firestoreProvider)),
    );

/// Firestore-primary [InterventionStateRepository] (per ADR-0008). The
/// SharedPreferences storage above is wrapped as the offline mirror.
final interventionStateRepositoryProvider =
    FutureProvider<InterventionStateRepository>((ref) async {
      final mirror = await ref.watch(interventionStateStorageProvider.future);
      final datasource = ref.watch(
        interventionStateFirestoreDatasourceProvider,
      );
      return InterventionStateRepositoryImpl(
        datasource: datasource,
        mirror: mirror,
        uidGetter: () => ref.read(currentUserStreamProvider).value?.uid,
      );
    });

/// Thin Firestore datasource for the
/// `users/{uid}/cheerUpEvents/{evtId}` audit log. Tests fake this
/// provider via `overrideWithValue` to avoid spinning up a real
/// `FirebaseFirestore`.
final cheerUpEventsFirestoreDatasourceProvider =
    Provider<CheerUpEventsFirestoreDatasource>(
      (ref) => CheerUpEventsFirestoreDatasource(ref.watch(firestoreProvider)),
    );

/// [CheerUpEventsRepository] for the cheer-up audit log (HB-003 §5.5b).
/// Idempotent doc-create at `users/{uid}/cheerUpEvents/{dayUtc}-{reason}`;
/// the Cloud Function `sendCheerUpPush` triggers on the create.
final cheerUpEventsRepositoryProvider = Provider<CheerUpEventsRepository>((
  ref,
) {
  return CheerUpEventsRepositoryImpl(
    datasource: ref.watch(cheerUpEventsFirestoreDatasourceProvider),
    uidGetter: () => ref.read(currentUserStreamProvider).value?.uid,
  );
});

/// Cached read of the persisted [InterventionAnchors]. Recomputes
/// whenever the upstream repository or auth state invalidates.
///
/// Returns the empty pair (`InterventionAnchors()`) on auth-pending /
/// repo-loading paths so the detector can run without surfacing a
/// loading flicker on Home.
final interventionAnchorsProvider = FutureProvider<InterventionAnchors>((
  ref,
) async {
  final repo = await ref.watch(interventionStateRepositoryProvider.future);
  final result = await repo.read();
  return switch (result) {
    Ok(:final value) => value,
    Err() => const InterventionAnchors(),
  };
});

/// Pipes the live mood stream through [detectPattern], applying the
/// persisted `lastTriggeredAt` / `firstTriggeredAt` anchors so the 48h
/// cooldown and 10-day escalation rules are honoured across cold
/// launches.
///
/// External shape unchanged (an `AsyncValue<InterventionState>`) so the
/// Garden screen and any existing tests keep working — the swap of the
/// underlying storage to the Firestore-primary repository is internal.
final interventionStateProvider = Provider<AsyncValue<InterventionState>>((
  ref,
) {
  final moodsAsync = ref.watch(myMoodsStreamProvider);
  final anchorsAsync = ref.watch(interventionAnchorsProvider);

  if (anchorsAsync.isLoading) return const AsyncValue.loading();
  final anchors = anchorsAsync.value;
  if (anchors == null) {
    return AsyncValue.error(
      anchorsAsync.error ?? StateError('anchors unavailable'),
      anchorsAsync.stackTrace ?? StackTrace.current,
    );
  }

  return moodsAsync.whenData((entries) {
    return detectPattern(
      entries,
      now: DateTime.now(),
      lastTriggeredAt: anchors.lastTriggeredAt,
      firstTriggeredAt: anchors.firstTriggeredAt,
    );
  });
});
