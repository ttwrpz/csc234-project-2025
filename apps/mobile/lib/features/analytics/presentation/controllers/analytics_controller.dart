import 'package:analytics_pkg/analytics_pkg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../mood/data/providers.dart';
import '../../data/providers.dart';
import '../../domain/entities/analytics_state.dart';

part 'analytics_controller.g.dart';

/// Streams an [AnalyticsState] for the requested [MoodWindow]. The chart
/// re-renders whenever new mood entries arrive on `myMoodsStreamProvider`.
///
/// Parameterised by `window` (riverpod_generator family) so each window
/// selection has its own provider instance — no manual cache invalidation
/// needed when the user toggles between 7d / 30d / 90d.
@riverpod
Stream<AnalyticsState> analyticsController(Ref ref, MoodWindow window) {
  final useCase = ref.watch(computeAnalyticsStateUseCaseProvider);
  return ref
      .watch(
        // ignore: deprecated_member_use
        myMoodsStreamProvider.stream,
      )
      .map(
        (entries) =>
            useCase(entries: entries, window: window, now: DateTime.now()),
      );
}
