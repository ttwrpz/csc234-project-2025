import '../entities/daily_insight.dart';
import '../entities/insight_window.dart';

/// Read-only contract for the Insights screen's chart data.
///
/// The data layer joins per-feature streams (mood entries + pattern
/// documents) into a deterministic, gap-filled list of [DailyInsight]s
/// covering the [window] inclusive on both endpoints. The returned list
/// is always exactly `window.dayCount` items long and ordered by date
/// ascending (oldest first). Days with no entries become
/// [DailyInsight.empty] slots — never omitted, never streak-shamed.
///
/// Pure-Dart contract — imports only sibling domain entities. Domain-purity
/// rule per CLAUDE.md.
abstract class InsightsRepository {
  /// Streams the user's joined insights over [window]. Emits a new list
  /// whenever either source (moods or patterns) updates. Errors are
  /// surfaced via the stream's error channel; the controller maps them
  /// to [InsightsFailure] before reaching presentation.
  Stream<List<DailyInsight>> watchInsights({
    required String userId,
    required InsightWindow window,
  });
}
