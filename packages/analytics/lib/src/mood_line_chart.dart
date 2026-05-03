import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'chart_mood_category.dart';
import 'mood_line_chart_theme.dart';
import 'mood_point.dart';
import 'mood_window.dart';

/// Read-only line chart of mean mood intensity per local-time day, one line
/// per [ChartMoodCategory]. Pure presentation — all aggregation happens in the
/// `compute_analytics_state` use case in the app layer.
///
/// Empty input collapses to a friendly placeholder rather than a `LineChart`
/// with no series, which would otherwise throw inside fl_chart.
class MoodLineChart extends StatelessWidget {
  const MoodLineChart({
    required this.points,
    required this.window,
    MoodLineChartTheme? theme,
    this.emptyState,
    super.key,
  }) : _theme = theme;

  /// Flat list of (day, category, meanIntensity). Order does not matter — the
  /// widget groups by category internally.
  final List<MoodPoint> points;

  /// Window the points were computed for. The X-axis spans
  /// `now - (window.days - 1)` … `now`.
  final MoodWindow window;

  /// Optional override theme. Falls back to [MoodLineChartTheme.fallback].
  final MoodLineChartTheme? _theme;

  /// Widget rendered when [points] is empty. Defaults to a centered hint.
  final Widget? emptyState;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Semantics(
        label: 'Mood chart, no data for the selected window.',
        child: emptyState ?? const _DefaultEmptyState(),
      );
    }

    final theme = _theme ?? MoodLineChartTheme.fallback();
    final today = _truncateToLocalDay(DateTime.now());
    final earliest = today.subtract(Duration(days: window.days - 1));

    // Parallel arrays keyed by `barIndex` (== position in `lines`). The
    // hover tooltip callback receives `LineBarSpot.barIndex` and uses
    // these to resolve the category label/color without re-running the
    // grouping logic.
    final lines = <LineChartBarData>[];
    final lineCategories = <ChartMoodCategory>[];
    final lineColors = <Color>[];
    for (final category in ChartMoodCategory.values) {
      final color = theme.colorByCategory[category];
      if (color == null) continue;
      final categoryPoints =
          points.where((p) => p.category == category).toList()
            ..sort((a, b) => a.day.compareTo(b.day));
      if (categoryPoints.isEmpty) continue;

      final spots = <FlSpot>[
        for (final p in categoryPoints)
          FlSpot(
            _truncateToLocalDay(p.day).difference(earliest).inDays.toDouble(),
            p.meanIntensity,
          ),
      ];
      lineCategories.add(category);
      lineColors.add(color);
      final areaColors = theme.areaFillBelowGradient;
      lines.add(
        LineChartBarData(
          spots: spots,
          color: color,
          barWidth: theme.lineWidth,
          isCurved: false,
          belowBarData: areaColors == null
              ? BarAreaData(show: false)
              : BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: areaColors,
                  ),
                ),
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, idx) => FlDotCirclePainter(
              radius: theme.dotRadius,
              color: color,
              strokeWidth: 0,
            ),
          ),
        ),
      );
    }

    return Semantics(
      label:
          'Mood chart for the last ${window.days} days, '
          '${lines.length} categor${lines.length == 1 ? "y" : "ies"} plotted.',
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (window.days - 1).toDouble(),
          minY: 1,
          maxY: 5,
          lineBarsData: lines,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (_) => FlLine(
              color: theme.gridColor,
              strokeWidth: 1,
              dashArray: theme.dashedGridLine ? const [2, 4] : null,
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(color: theme.gridColor),
              bottom: BorderSide(color: theme.gridColor),
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 28,
                getTitlesWidget: (value, _) {
                  if (value < 1 || value > 5) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: theme.axisLabelColor,
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _bottomTickInterval(window),
                reservedSize: 24,
                getTitlesWidget: (value, _) {
                  final dayIndex = value.round();
                  if ((value - dayIndex).abs() > 0.001) {
                    return const SizedBox.shrink();
                  }
                  if (dayIndex < 0 || dayIndex >= window.days) {
                    return const SizedBox.shrink();
                  }
                  final day = earliest.add(Duration(days: dayIndex));
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${day.month}/${day.day}',
                      style: TextStyle(
                        color: theme.axisLabelColor,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              // Theme-aware tooltip surface. fl_chart's default is a light
              // grey that disappears in dark mode and washes out the value
              // text in light mode. We use the chart theme's gridColor as
              // the on-surface fallback when the caller hasn't supplied a
              // tooltip color, then auto-pick text color by background
              // luminance so contrast meets WCAG AA in both modes.
              getTooltipColor: (_) => theme.tooltipBgColor,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              tooltipRoundedRadius: 8,
              getTooltipItems: (touched) {
                final fg =
                    ThemeData.estimateBrightnessForColor(
                          theme.tooltipBgColor,
                        ) ==
                        Brightness.dark
                    ? Colors.white
                    : const Color(0xFF1F2937);
                final fgDim = fg.withValues(alpha: 0.7);
                return [
                  for (final t in touched)
                    LineTooltipItem(
                      // Header line: weekday + day, e.g. "Sun · Mar 9".
                      _tooltipDateLabel(earliest, t.x),
                      TextStyle(
                        color: fgDim,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        const TextSpan(text: '\n'),
                        TextSpan(
                          // Body line: category dot + label + value.
                          text:
                              '${_categoryLabel(t.barIndex < lineCategories.length ? lineCategories[t.barIndex] : null)} '
                              '${t.y.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: fg,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ];
              },
            ),
          ),
        ),
      ),
    );
  }

  static DateTime _truncateToLocalDay(DateTime t) {
    final local = t.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static double _bottomTickInterval(MoodWindow window) {
    return switch (window) {
      MoodWindow.week => 1,
      MoodWindow.month => 5,
      MoodWindow.quarter => 15,
    };
  }
}

/// Tooltip helpers — kept top-level so they aren't captured by the
/// closure on every paint, and so the formatting is unit-testable.
String _tooltipDateLabel(DateTime earliest, double xValue) {
  final day = earliest.add(Duration(days: xValue.round()));
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
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
  return '${weekdays[day.weekday - 1]} · ${months[day.month - 1]} ${day.day}';
}

String _categoryLabel(ChartMoodCategory? c) => switch (c) {
  ChartMoodCategory.positive => 'Positive',
  ChartMoodCategory.negativeMild => 'Mild',
  ChartMoodCategory.negativeStrong => 'Strong',
  null => '',
};

class _DefaultEmptyState extends StatelessWidget {
  const _DefaultEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Nothing to chart yet.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
