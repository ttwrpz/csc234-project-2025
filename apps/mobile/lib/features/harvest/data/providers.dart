import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../auth/data/providers.dart';
import '../domain/entities/weekly_garden.dart';
import '../domain/repositories/harvest_repository.dart';
import '../domain/usecases/archive_weekly_garden.dart';
import '../domain/usecases/compute_weekly_summary.dart';
import 'datasources/weekly_gardens_firestore_datasource.dart';
import 'repositories/harvest_repository_impl.dart';

/// Riverpod wiring for the Weekly Harvest cycle.
///
/// The use case providers live here (data layer) because the domain
/// layer must not import `package:flutter_riverpod` per CLAUDE.md's
/// domain-purity rule. The use case CLASSES are pure-Dart and live in
/// `domain/usecases/`; these providers just expose const instances for
/// controllers + screens.

/// Pure-Dart [ComputeWeeklySummaryUseCase]. Const instance - safe to
/// `overrideWithValue` in tests with a fake.
final computeWeeklySummaryUseCaseProvider =
    Provider<ComputeWeeklySummaryUseCase>(
      (ref) => const ComputeWeeklySummaryUseCase(),
    );

/// Thin Firestore datasource for the
/// `users/{uid}/weeklyGardens/{weekId}` collection. Tests fake this
/// provider via `overrideWithValue` to avoid spinning up a real
/// `FirebaseFirestore`.
final weeklyGardensFirestoreDatasourceProvider =
    Provider<WeeklyGardensFirestoreDatasource>(
      (ref) => WeeklyGardensFirestoreDatasource(ref.watch(firestoreProvider)),
    );

/// Firestore-backed [HarvestRepository]. Wraps the datasource and maps
/// Firestore exceptions to `HarvestFailure`.
final harvestRepositoryProvider = Provider<HarvestRepository>(
  (ref) => HarvestRepositoryImpl(
    datasource: ref.watch(weeklyGardensFirestoreDatasourceProvider),
  ),
);

/// [ArchiveWeeklyGardenUseCase] wired to the repository + summary
/// use case. Controllers call the use case directly; tests can swap
/// the repository via `overrideWithValue`.
final archiveWeeklyGardenUseCaseProvider = Provider<ArchiveWeeklyGardenUseCase>(
  (ref) => ArchiveWeeklyGardenUseCase(
    repository: ref.watch(harvestRepositoryProvider),
    computeSummary: ref.watch(computeWeeklySummaryUseCaseProvider),
  ),
);

/// Streams the current user's archived weeks newest-first. Emits an
/// empty list when the user has not yet harvested any week. Returns
/// an empty stream when no user is signed in (the History tab is
/// rendered after auth so this is mostly defensive).
final weeklyGardenHistoryProvider = StreamProvider<List<WeeklyGarden>>((ref) {
  final user = ref.watch(currentUserStreamProvider).value;
  if (user == null) {
    return const Stream<List<WeeklyGarden>>.empty();
  }
  return ref.watch(harvestRepositoryProvider).watchHistory(userId: user.uid);
});
