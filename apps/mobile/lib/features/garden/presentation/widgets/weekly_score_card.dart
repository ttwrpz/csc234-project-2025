import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../mood/domain/entities/mood_entry.dart';
import '../../../mood/domain/entities/mood_type.dart';
import '../../../mood/domain/services/mood_score.dart';
import '../../../mood/presentation/widgets/mood_kind_adapter.dart';

/// "THIS WEEK" overview card that ports the prototype's
/// `GardenScreen` weekly-score block: an eyebrow + date range row,
/// a large serif signed weekly average, a 7-bar Mon..Sun mini chart
/// driven by each day's mean mood-score, and a "weekly average"
/// caption.
///
/// Bars are center-anchored on a y=0 baseline so positive days grow
/// up and negative days grow down. Each day's bar is tinted by that
/// day's dominant-mood swatch (`MbMoodPalette.colorOf`) so users
/// recognise the colour code from the rest of the app. Empty days
/// collapse to a thin neutral pill.
///
/// Pure presentation - bucketing + average + dominant-mood lookup
/// happens inside `build` from the [weekEntries] + [weekStart] inputs
/// so the caller doesn't have to precompute anything.
class WeeklyScoreCard extends StatelessWidget {
  const WeeklyScoreCard({
    super.key,
    required this.weekEntries,
    required this.weekStart,
  });

  /// All entries that fall within the active week. Need not be
  /// sorted; the widget buckets by local-midnight on
  /// `createdAt.toLocal()`.
  final List<MoodEntry> weekEntries;

  /// Local-midnight of Monday of the active week. The 7 bars are
  /// `weekStart`, `weekStart + 1d`, ..., `weekStart + 6d` in order.
  /// Use [_mondayOf] when computing this from today's date.
  final DateTime weekStart;

  /// Max vertical bar height. Bars are split symmetrically around a
  /// baseline at `_barMaxHeight / 2`, so a |score|=1 day fills the
  /// full half-height of the strip.
  static const double _barMaxHeight = 48;

  /// Pill height for empty (no-entry) days. Stays tiny so the user
  /// sees "nothing happened" not "the bar collapsed".
  static const double _emptyPillHeight = 4;

  /// Returns the Monday-aligned local-midnight for [now]. Sundays
  /// are bucketed into the week that started six days earlier so the
  /// week chart always reads Mon -> Sun.
  static DateTime mondayOf(DateTime now) {
    final local = now.toLocal();
    final midnight = DateTime(local.year, local.month, local.day);
    // weekday: Mon=1 .. Sun=7
    final delta = midnight.weekday - DateTime.monday;
    return midnight.subtract(Duration(days: delta));
  }

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final palette = Theme.of(context).extension<MbMoodPalette>()!;

    final buckets = _bucketByDay(weekEntries, weekStart);
    final dayMeans = buckets.map(_meanScore).toList(growable: false);
    final dayDominantColors = buckets
        .map((entries) => _dominantColor(entries, palette))
        .toList(growable: false);

    final weeklyAvg = _weeklyAverage(weekEntries);
    final dateRange = _formatDateRange(weekStart);
    final signedAvg = _formatSigned(weeklyAvg);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avgColor = _avgColorFor(weeklyAvg, mb, isDark);

    return MbCard(
      padding: const EdgeInsets.all(MoodBloomSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'DAILY SCORE',
                style: MbFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                  color: mb.textDim,
                ),
              ),
              const Spacer(),
              Text(
                dateRange,
                style: MbFonts.nunito(fontSize: 11, color: mb.textDim),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                signedAvg,
                style: MbFonts.fraunces(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: avgColor,
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'weekly average',
                style: MbFonts.nunito(fontSize: 13, color: mb.textDim),
              ),
            ],
          ),
          const SizedBox(height: MoodBloomSpacing.md),
          _MiniChart(
            dayMeans: dayMeans,
            dayColors: dayDominantColors,
            barMaxHeight: _barMaxHeight,
            emptyPillHeight: _emptyPillHeight,
            line: mb.line,
            textDim: mb.textDim,
          ),
          const SizedBox(height: 10),
          Text(
            'Mood is weather. The ecosystem holds.',
            style: MbFonts.nunito(fontSize: 12, color: mb.textDim),
          ),
        ],
      ),
    );
  }

  /// Buckets [entries] into 7 lists keyed by `weekStart + dayIndex`.
  /// Bucket order is Mon, Tue, ..., Sun.
  static List<List<MoodEntry>> _bucketByDay(
    List<MoodEntry> entries,
    DateTime weekStart,
  ) {
    final out = List<List<MoodEntry>>.generate(7, (_) => <MoodEntry>[]);
    for (final e in entries) {
      final local = e.createdAt.toLocal();
      final dayKey = DateTime(local.year, local.month, local.day);
      final diff = dayKey.difference(weekStart).inDays;
      if (diff < 0 || diff > 6) continue;
      out[diff].add(e);
    }
    return out;
  }

  /// Mean of `MoodScore.value` for one day's entries. Returns 0 for
  /// an empty list (the caller decides whether to render that as an
  /// empty pill or a zero-height bar - the mini chart treats null vs
  /// 0 the same way via the entry count check).
  static double _meanScore(List<MoodEntry> entries) {
    if (entries.isEmpty) return 0;
    var sum = 0.0;
    for (final e in entries) {
      sum += computeMoodScore(e.mood, e.intensity).value;
    }
    return sum / entries.length;
  }

  static double _weeklyAverage(List<MoodEntry> entries) {
    if (entries.isEmpty) return 0;
    var sum = 0.0;
    for (final e in entries) {
      sum += computeMoodScore(e.mood, e.intensity).value;
    }
    return sum / entries.length;
  }

  /// Returns the colour swatch of the most-frequent mood in
  /// [entries]. Falls back to null when empty (caller renders the
  /// neutral pill).
  static Color? _dominantColor(List<MoodEntry> entries, MbMoodPalette palette) {
    if (entries.isEmpty) return null;
    final counts = <MoodType, int>{};
    for (final e in entries) {
      counts[e.mood] = (counts[e.mood] ?? 0) + 1;
    }
    MoodType? dominant;
    var bestCount = 0;
    counts.forEach((mood, count) {
      if (count > bestCount) {
        bestCount = count;
        dominant = mood;
      }
    });
    final m = dominant;
    if (m == null) return null;
    return palette.colorOf(m.mbKind);
  }

  /// Picks the score colour for the large headline number. Strongly
  /// negative weeks lean coral so the user reads the headline at a
  /// glance ("a heavy week"). Positive weeks lean seed-green for the
  /// same reason. Neutral weeks stay on the body-text colour. Both
  /// accents are theme-aware so they stay legible on the dark scaffold
  /// (the deep coralText / seed both read too dim on navy).
  static Color _avgColorFor(double avg, MbColors mb, bool isDark) {
    if (avg <= -0.3) return mb.destructiveText;
    if (avg >= 0.1) return MoodBloomColors.brandText(isDark);
    return mb.text;
  }

  static String _formatSigned(double v) {
    final sign = v >= 0 ? '+' : '-';
    final mag = v.abs().toStringAsFixed(2);
    return '$sign$mag';
  }

  static String _formatDateRange(DateTime weekStart) {
    final end = weekStart.add(const Duration(days: 6));
    final m1 = _shortMonth(weekStart.month);
    final m2 = _shortMonth(end.month);
    if (m1 == m2) {
      return '$m1 ${weekStart.day} - ${end.day}';
    }
    return '$m1 ${weekStart.day} - $m2 ${end.day}';
  }

  static const List<String> _shortMonths = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String _shortMonth(int month) =>
      _shortMonths[(month - 1).clamp(0, 11)];
}

/// The 7-bar Mon..Sun chart that sits at the bottom of
/// [WeeklyScoreCard]. Pulled out so the build method up top reads as
/// a vertical column of named blocks; this widget owns the bar
/// geometry and the weekday letters.
class _MiniChart extends StatelessWidget {
  const _MiniChart({
    required this.dayMeans,
    required this.dayColors,
    required this.barMaxHeight,
    required this.emptyPillHeight,
    required this.line,
    required this.textDim,
  });

  final List<double> dayMeans;
  final List<Color?> dayColors;
  final double barMaxHeight;
  final double emptyPillHeight;
  final Color line;
  final Color textDim;

  /// Two-letter weekday labels (Mon-first). Single letters collided on
  /// Saturday/Sunday (both 'S'), which read as a duplicate day; the
  /// two-letter form keeps every day distinct.
  static const List<String> _letters = [
    'Mo',
    'Tu',
    'We',
    'Th',
    'Fr',
    'Sa',
    'Su',
  ];

  @override
  Widget build(BuildContext context) {
    final stripHeight = barMaxHeight;
    final halfHeight = stripHeight / 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: stripHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: _Bar(
                    mean: dayMeans[i],
                    color: dayColors[i],
                    halfHeight: halfHeight,
                    emptyPillHeight: emptyPillHeight,
                    line: line,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(
                    _letters[i],
                    style: MbFonts.nunito(fontSize: 10, color: textDim),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// One vertical bar in the mini chart. Renders as either:
///   * An empty-day neutral pill at the baseline (when [color] is
///     null), or
///   * A coloured rounded-rect grown from the centre baseline up
///     (positive) or down (negative), height proportional to |mean|.
class _Bar extends StatelessWidget {
  const _Bar({
    required this.mean,
    required this.color,
    required this.halfHeight,
    required this.emptyPillHeight,
    required this.line,
  });

  final double mean;
  final Color? color;
  final double halfHeight;
  final double emptyPillHeight;
  final Color line;

  @override
  Widget build(BuildContext context) {
    if (color == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Container(
          height: emptyPillHeight,
          decoration: BoxDecoration(
            color: line,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
    }
    final magnitude = mean.abs().clamp(0.0, 1.0);
    final h = magnitude * halfHeight;
    final positive = mean >= 0;
    // Center-anchored: positive bars grow up from the midline,
    // negative bars grow down. We stack two SizedBoxes vertically;
    // the active one carries the colored rect, the inactive one is
    // sized to the same half-height so the bar visually centres.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            height: halfHeight,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: positive
                  ? Container(
                      height: h,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          SizedBox(
            height: halfHeight,
            child: Align(
              alignment: Alignment.topCenter,
              child: positive
                  ? const SizedBox.shrink()
                  : Container(
                      height: h,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
