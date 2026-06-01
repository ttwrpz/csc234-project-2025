import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'chart_mood_category.dart';
import 'mood_line_chart_theme.dart';
import 'mood_point.dart';
import 'mood_window.dart';

/// Read-only line chart of mean mood intensity per local-time day, one line
/// per [ChartMoodCategory]. Pure presentation - all aggregation happens in the
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

  /// Flat list of (day, category, meanIntensity). Order does not matter - the
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
              // Solid theme.surface (not inverseSurface) so the tooltip
              // reads like a small floating card. Cleaner UX than the
              // inverse-mode floating chip, especially in light theme
              // where the inverse hue was a strong contrast jump from
              // the chart's cream background.
              getTooltipColor: (_) => Theme.of(context).colorScheme.surface,
              tooltipBorder: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1,
              ),
              tooltipRoundedRadius: 12,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              tooltipMargin: 14,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              maxContentWidth: 280,
              getTooltipItems: (touched) {
                final scheme = Theme.of(context).colorScheme;
                final fg = scheme.onSurface;
                final fgDim = scheme.onSurfaceVariant;
                // Sort by barIndex so the tooltip reads Positive → Mild →
                // Strong top-to-bottom; the date header attaches to the
                // first row.
                final sorted = [...touched]
                  ..sort((a, b) => a.barIndex.compareTo(b.barIndex));
                final result = <LineTooltipItem>[];
                for (var i = 0; i < sorted.length; i += 1) {
                  final t = sorted[i];
                  final cat = t.barIndex < lineCategories.length
                      ? lineCategories[t.barIndex]
                      : null;
                  final colorDot = t.barIndex < lineColors.length
                      ? lineColors[t.barIndex]
                      : fg;
                  final intensity = t.y.toStringAsFixed(1);
                  final headerText = i == 0
                      ? '${_tooltipDateLabel(earliest, t.x)}\n'
                      : '';
                  result.add(
                    LineTooltipItem(
                      headerText,
                      TextStyle(
                        color: fgDim,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                        letterSpacing: 0.2,
                      ),
                      children: [
                        TextSpan(
                          text: '●  ',
                          style: TextStyle(
                            color: colorDot,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            height: 1.5,
                          ),
                        ),
                        TextSpan(
                          text: '${_categoryLabel(cat)} mood ',
                          style: TextStyle(
                            color: fg,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                        TextSpan(
                          text: '· intensity $intensity / 5',
                          style: TextStyle(
                            color: fgDim,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return result;
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

/// Tooltip helpers - kept top-level so they aren't captured by the
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
