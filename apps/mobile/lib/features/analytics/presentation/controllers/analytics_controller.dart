import 'package:analytics_pkg/analytics_pkg.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../mood/data/providers.dart';
import '../../data/providers.dart';
import '../../domain/entities/analytics_state.dart';

part 'analytics_controller.g.dart';

/// Returns an `AsyncValue<AnalyticsState>` for the requested [MoodWindow].
/// The chart re-renders whenever new mood entries arrive on
/// `myMoodsStreamProvider`.
///
/// Parameterised by `window` (riverpod_generator family) so each window
/// selection has its own provider instance — no manual cache invalidation
/// needed when the user toggles between 7d / 30d / 90d.
///
/// Riverpod 3: `StreamProvider.stream` was removed. We watch the upstream
/// `AsyncValue<List<MoodEntry>>` directly and `whenData` it through the
/// pure use case, mirroring the `gardenStateStreamProvider` shape.
@riverpod
AsyncValue<AnalyticsState> analyticsController(Ref ref, MoodWindow window) {
  final useCase = ref.watch(computeAnalyticsStateUseCaseProvider);
  final moods = ref.watch(myMoodsStreamProvider);
  return moods.whenData(
    (entries) => useCase(entries: entries, window: window, now: DateTime.now()),
  );
}
