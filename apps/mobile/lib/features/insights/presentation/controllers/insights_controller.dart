import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;

import '../../../auth/data/providers.dart';
import '../../../disclaimer/data/providers.dart';
import '../../data/providers.dart';
import '../../domain/entities/daily_insight.dart';
import '../../domain/entities/insight_window.dart';

/// Window selection (segmented chips). v1.6 defaults to the 14-day
/// fortnight - it matches the prototype's middle tab and the
/// Mann-Kendall trend test's natural span.
final insightsWindowPresetProvider = StateProvider<InsightWindowPreset>(
  (_) => InsightWindowPreset.fortnight,
);

/// Resolved [InsightWindow] for the current selection. Re-derives when
/// the preset changes; uses `DateTime.now()` so the window always slides
/// with the local clock.
final insightsWindowProvider = Provider<InsightWindow>((ref) {
  final preset = ref.watch(insightsWindowPresetProvider);
  return InsightWindow.from(preset: preset, now: DateTime.now());
});

/// Gate state for the Insights screen.
///
/// `disclaimerRequired` - the bipolar/medical disclaimer ack flag is
/// still `false` for the signed-in user. Presentation MUST hide the
/// chart and show the ack dialog. The flag persists in
/// `users/{uid}.insightsDisclaimerAcked` so this state never reappears
/// after a sign-out / reinstall.
///
/// `ready` - ack landed; the chart can render. `loading` is the brief
/// "stream hasn't emitted yet" gap (one frame in practice).
enum InsightsGateState { loading, disclaimerRequired, ready }

/// Streams the gate state. Combines auth + the disclaimer-ack stream
/// into the single switch the screen consumes.
final insightsGateProvider = Provider<InsightsGateState>((ref) {
  final user = ref.watch(currentUserStreamProvider).value;
  if (user == null) return InsightsGateState.loading;
  final ack = ref.watch(disclaimerAckStreamProvider);
  return ack.when(
    data: (acked) =>
        acked ? InsightsGateState.ready : InsightsGateState.disclaimerRequired,
    loading: () => InsightsGateState.loading,
    // Failing closed keeps the chart hidden until we know the user has
    // acknowledged. Better to ask twice than to slip past the gate.
    error: (_, _) => InsightsGateState.disclaimerRequired,
  );
});

/// The chart's data stream, gated on `InsightsGateState.ready`. Returns
/// `null` while gated so the controller has a single "show / hide"
/// signal and the screen never needs to track gate state twice.
final insightsStreamProvider = StreamProvider<List<DailyInsight>?>((ref) {
  final gate = ref.watch(insightsGateProvider);
  if (gate != InsightsGateState.ready) {
    // Defence-in-depth: even if the controller has
    // data, the chart must not render until the ack lands.
    return Stream.value(null);
  }
  final user = ref.watch(currentUserStreamProvider).value;
  if (user == null) return Stream.value(null);
  final window = ref.watch(insightsWindowProvider);
  final useCase = ref.watch(loadInsightsUseCaseProvider);
  return useCase(userId: user.uid, window: window).map((list) => list);
});
