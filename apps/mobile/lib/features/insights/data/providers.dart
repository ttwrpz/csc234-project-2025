import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mood/data/providers.dart';
import '../../pattern_engine/data/providers.dart';
import '../domain/repositories/insights_repository.dart';
import '../domain/usecases/load_insights.dart';
import 'insights_repository_impl.dart';

/// Riverpod wiring for the Insights feature.
///
/// The repository composes the existing mood and pattern-engine repos;
/// no new Firestore collections are introduced. Tests can fake either
/// the upstream repos OR this provider directly via `overrideWithValue`.

/// Composed [InsightsRepository] - joins the per-feature mood + pattern
/// streams into the day-bucketed [DailyInsight] list the chart renders.
final insightsRepositoryProvider = Provider<InsightsRepository>(
  (ref) => InsightsRepositoryImpl(
    moodRepository: ref.watch(moodRepositoryProvider),
    patternRepository: ref.watch(patternRepositoryProvider),
  ),
);

/// Pure-Dart [LoadInsightsUseCase] - const-ish wrapper so controllers
/// depend on a single-method abstraction.
final loadInsightsUseCaseProvider = Provider<LoadInsightsUseCase>(
  (ref) =>
      LoadInsightsUseCase(repository: ref.watch(insightsRepositoryProvider)),
);
