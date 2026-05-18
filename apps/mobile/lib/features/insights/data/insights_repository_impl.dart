import 'dart:async';

import 'package:core/core.dart';

import '../../garden/domain/services/garden_health_ewma.dart';
import '../../mood/domain/entities/mood_entry.dart';
import '../../mood/domain/entities/mood_type.dart';
import '../../mood/domain/mood_repository.dart';
import '../../mood/domain/services/mood_score.dart';
import '../../pattern_engine/domain/entities/pattern_result.dart';
import '../../pattern_engine/domain/entities/tier.dart';
import '../../pattern_engine/domain/repositories/pattern_repository.dart';
import '../domain/entities/daily_insight.dart';
import '../domain/entities/insight_window.dart';
import '../domain/entities/pattern_engine_trigger_kind.dart';
import '../domain/repositories/insights_repository.dart';

/// Joins `users/{uid}/moods/*` with `users/{uid}/patterns/{date}` into the
/// gap-filled [DailyInsight] list the Insights screen renders.
///
/// Composition strategy: a hand-rolled `_LatestCombiner` merges the two
/// inbound streams without taking a dependency on rxdart (not in
/// pubspec — adding it for one operator would be heavier than the
/// 30-line helper below). The combiner re-emits whenever either side
/// updates; it suppresses emission until the first event has landed on
/// each source so consumers never see a half-joined snapshot.
///
/// Aggregation rules:
///   * `avgMoodScore` = mean of `computeMoodScore(mood, intensity).value`
///     across every mood entry whose local-midnight equals the day. Null
///     on days with zero entries.
///   * `gardenHealthH` = EWMA `H_t` folded forward day-by-day, resetting
///     to `H_0 = 0` at every Monday boundary (mirrors
///     `ComputeGardenStateUseCase` — weekly harvest resets H_t). Days
///     without entries do NOT fold zero — they carry the previous H_t
///     unchanged.
///   * `dominantEmotion` = the most-frequent `mood` on the day; ties
///     broken by `MoodType.values` declaration order.
///   * `triggeredTier` = lifted from the matching `PatternResult`
///     document; null when no document exists.
///   * Result list is always exactly `window.dayCount` items long,
///     ordered date ascending. Empty days surface as
///     [DailyInsight.empty] with `gardenHealthH` carried forward so the
///     overlay line stays continuous.
class InsightsRepositoryImpl implements InsightsRepository {
  const InsightsRepositoryImpl({
    required MoodRepository moodRepository,
    required PatternRepository patternRepository,
  }) : _moodRepository = moodRepository,
       _patternRepository = patternRepository;

  final MoodRepository _moodRepository;
  final PatternRepository _patternRepository;

  @override
  Stream<List<DailyInsight>> watchInsights({
    required String userId,
    required InsightWindow window,
  }) {
    if (userId.isEmpty) {
      return Stream.value(_emptyWindow(window));
    }
    final moods = _moodRepository.watchAll(userId: userId);
    final patterns = _patternRepository.watchRange(
      userId: userId,
      startDateId: _dateId(window.startDate),
      endDateId: _dateId(window.endDate),
    );
    return _LatestCombiner<List<MoodEntry>, List<PatternResult>>(
      moods,
      patterns,
    ).stream.map((tuple) => joinForTest(window, tuple.$1, tuple.$2));
  }

  /// Pure join function — extracted so it can be unit-tested without
  /// spinning up streams. Public-with-`forTest`-suffix per the project's
  /// existing pattern (see `MoodRepositoryImpl`).
  ///
  /// Folds garden-health EWMA forward day-by-day across [window]. To
  /// correctly seed `H_0 = 0` at every Monday boundary the fold walks
  /// from the most recent Monday on-or-before `window.startDate` rather
  /// than from `window.startDate` itself — so a 14-day window that opens
  /// on a Wednesday still inherits the right partial-week H_t.
  static List<DailyInsight> joinForTest(
    InsightWindow window,
    List<MoodEntry> allMoods,
    List<PatternResult> patterns,
  ) {
    // 1. Bucket mood entries by local-midnight day.
    final moodsByDay = <DateTime, List<MoodEntry>>{};
    for (final e in allMoods) {
      final d = localMidnight(e.createdAt);
      moodsByDay.putIfAbsent(d, () => <MoodEntry>[]).add(e);
    }
    // 2. Bucket pattern docs by dateId — there is at most one per day.
    final patternsByDay = <String, PatternResult>{
      for (final p in patterns) p.dateId: p,
    };

    // 3. Walk from the Monday on-or-before `window.startDate` up to
    //    `window.endDate`, folding H_t day by day. Reset H_t to 0 each
    //    Monday (matches the weekly harvest cycle). Days
    //    without entries do NOT fold zero — carry the previous H_t.
    final foldStart = _mondayOnOrBefore(window.startDate);
    var h = 0.0;
    // Tracks whether the user has logged at least one entry in the
    // CURRENT week. Reset on every Monday so empty Mondays surface as
    // null (no signal) rather than carrying Sunday's H forward — which
    // would defeat the weekly reset.
    var weekHasEntry = false;
    final hByDay = <DateTime, double?>{};
    for (
      var d = foldStart;
      !d.isAfter(window.endDate);
      d = d.add(const Duration(days: 1))
    ) {
      if (d.weekday == DateTime.monday) {
        h = 0.0;
        weekHasEntry = false;
      }
      final entries = moodsByDay[d];
      if (entries != null && entries.isNotEmpty) {
        h = stepGardenHealthEwma(h, _avgScore(entries));
        weekHasEntry = true;
        hByDay[d] = h;
      } else {
        // Empty day: carry forward THIS WEEK's H (only if the week
        // has at least one prior entry). Otherwise null — no signal.
        hByDay[d] = weekHasEntry ? h : null;
      }
    }

    // 4. Emit one DailyInsight per day in the window.
    final out = <DailyInsight>[];
    for (var i = 0; i < window.dayCount; i++) {
      final day = window.startDate.add(Duration(days: i));
      final entries = moodsByDay[day] ?? const <MoodEntry>[];
      final dateId = _dateId(day);
      final pattern = patternsByDay[dateId];
      out.add(
        DailyInsight(
          date: day,
          avgMoodScore: entries.isEmpty ? null : _avgScore(entries),
          gardenHealthH: hByDay[day],
          dominantEmotion: entries.isEmpty ? null : _dominantEmotion(entries),
          entryCount: entries.length,
          triggeredTier: pattern?.triggeredTier,
          triggerReasonKey: _reasonFor(pattern),
        ),
      );
    }
    return out;
  }

  /// Picks the dominant algorithm that fired on a given day so the
  /// Insights marker-tap popover can show ONE plain-English reason.
  ///
  /// Resolution rule:
  ///  * No tier triggered → `null` (no marker, no popover content).
  ///  * Tier 1 has one source: Mann-Kendall.
  ///  * Tier 2 has one source: sliding 5-of-7.
  ///  * Tier 3 has three possible sources, ordered by acuity:
  ///    3-consecutive → z-score → CUSUM. We pick the first one whose
  ///    flag tripped, since each maps to a different copy line. If a
  ///    legacy doc (pre-engine-flags) carries `triggeredTier = three`
  ///    with none of the three Tier-3 flags asserted, return `null`
  ///    rather than guess — the popover renders without the algorithm
  ///    line (graceful degradation).
  static PatternEngineTriggerKind? _reasonFor(PatternResult? pattern) {
    if (pattern == null) return null;
    final tier = pattern.triggeredTier;
    if (tier == null) return null;
    switch (tier) {
      case Tier.one:
        final z = pattern.mannKendallZ;
        if (z != null && z < -1.96) return PatternEngineTriggerKind.mannKendall;
        return null;
      case Tier.two:
        if (pattern.slidingNegCount >= 5) {
          return PatternEngineTriggerKind.sliding5of7;
        }
        return null;
      case Tier.three:
        if (pattern.consecutiveHighIntensity >= 3) {
          return PatternEngineTriggerKind.threeConsecutive;
        }
        final z = pattern.zScoreToday;
        if (z != null && z < -2.5) return PatternEngineTriggerKind.zScore;
        if (pattern.cusumC > 0) return PatternEngineTriggerKind.cusum;
        return null;
    }
  }

  static List<DailyInsight> _emptyWindow(InsightWindow window) => [
    for (var i = 0; i < window.dayCount; i++)
      DailyInsight.empty(window.startDate.add(Duration(days: i))),
  ];

  static double _avgScore(List<MoodEntry> entries) {
    var sum = 0.0;
    for (final e in entries) {
      sum += computeMoodScore(e.mood, e.intensity).value;
    }
    return sum / entries.length;
  }

  /// Most-frequent mood across [entries]. Ties broken by `MoodType.values`
  /// declaration order — iterates the enum once and tracks the highest
  /// count seen so far, picking the FIRST type that hits that count.
  /// Deterministic across renders.
  static MoodType _dominantEmotion(List<MoodEntry> entries) {
    final counts = <MoodType, int>{};
    for (final e in entries) {
      counts[e.mood] = (counts[e.mood] ?? 0) + 1;
    }
    MoodType? best;
    var bestCount = -1;
    for (final type in MoodType.values) {
      final c = counts[type] ?? 0;
      if (c > bestCount) {
        best = type;
        bestCount = c;
      }
    }
    return best ?? entries.first.mood;
  }

  static String _dateId(DateTime day) {
    final local = day.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime _mondayOnOrBefore(DateTime day) {
    final local = day.toLocal();
    final midnight = DateTime(local.year, local.month, local.day);
    final daysFromMonday = midnight.weekday - DateTime.monday;
    return midnight.subtract(Duration(days: daysFromMonday));
  }
}

/// Manual two-stream combiner that re-emits the latest tuple whenever
/// either input pushes. Replicates the subset of rxdart's
/// `Rx.combineLatest2` we need without taking the dep — see class doc on
/// [InsightsRepositoryImpl] for the rationale.
///
/// Holds the most recent value from each source. Suppresses emission
/// until BOTH sources have produced at least one event (otherwise the
/// initial half-joined snapshot would surface to consumers). Forwards
/// errors from either source as-is so the consumer can map them.
class _LatestCombiner<A, B> {
  _LatestCombiner(this._a, this._b);

  final Stream<A> _a;
  final Stream<B> _b;

  Stream<(A, B)> get stream {
    late StreamController<(A, B)> controller;
    StreamSubscription<A>? subA;
    StreamSubscription<B>? subB;
    A? latestA;
    B? latestB;
    var hasA = false;
    var hasB = false;

    void emitIfReady() {
      if (hasA && hasB && !controller.isClosed) {
        controller.add((latestA as A, latestB as B));
      }
    }

    controller = StreamController<(A, B)>(
      onListen: () {
        subA = _a.listen((v) {
          latestA = v;
          hasA = true;
          emitIfReady();
        }, onError: controller.addError);
        subB = _b.listen((v) {
          latestB = v;
          hasB = true;
          emitIfReady();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await subA?.cancel();
        await subB?.cancel();
      },
    );
    return controller.stream;
  }
}
