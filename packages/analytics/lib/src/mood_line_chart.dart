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

    final lines = <LineChartBarData>[];
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
      lines.add(
        LineChartBarData(
          spots: spots,
          color: color,
          barWidth: theme.lineWidth,
          isCurved: false,
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
            getDrawingHorizontalLine: (_) =>
                FlLine(color: theme.gridColor, strokeWidth: 1),
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
          lineTouchData: const LineTouchData(handleBuiltInTouches: true),
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
