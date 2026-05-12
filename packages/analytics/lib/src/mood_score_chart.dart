import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'mood_score_chart_theme.dart';
import 'mood_score_point.dart';

/// Mood-score time-series chart for the (S5) Insights screen. Plots two
/// lines in the closed Y range `[-1, +1]`:
///
///   * the per-day mean mood-score `S_day` (primary, solid)
///   * the EWMA `H_t` Garden Health overlay (secondary, dashed)
///
/// 5 horizontal bands (Storm Season → Flourishing) sit behind both
/// lines as a low-alpha visual reference. Bands and line colours come
/// from the caller via [MoodScoreChartTheme] so this package stays
/// decoupled from `packages/design_system`.
///
/// Both series accept null per day — those points are skipped, so the
/// remaining segments connect across gaps without inventing data.
class MoodScoreLineChart extends StatelessWidget {
  const MoodScoreLineChart({
    required this.points,
    required this.theme,
    this.emptyState,
    super.key,
  });

  /// One sample per day in the user's window, ordered date-ascending.
  final List<MoodScorePoint> points;

  /// Visual theme.
  final MoodScoreChartTheme theme;

  /// Widget rendered when [points] is empty. Defaults to a centred hint.
  final Widget? emptyState;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Semantics(
        label: 'Mood score chart, no data for the selected window.',
        child: emptyState ?? const _DefaultEmptyState(),
      );
    }

    final scoreSpots = <FlSpot>[];
    final healthSpots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      if (p.score != null) {
        scoreSpots.add(FlSpot(i.toDouble(), p.score!.clamp(-1.0, 1.0)));
      }
      if (p.health != null) {
        healthSpots.add(FlSpot(i.toDouble(), p.health!.clamp(-1.0, 1.0)));
      }
    }

    return Semantics(
      label:
          'Mood score chart for ${points.length} days. '
          '${scoreSpots.length} score points, '
          '${healthSpots.length} health points.',
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (points.length - 1).toDouble().clamp(0.0, double.infinity),
          minY: -1,
          maxY: 1,
          rangeAnnotations: RangeAnnotations(
            horizontalRangeAnnotations: _bands(theme),
          ),
          lineBarsData: [
            // Primary: mood score S_t.
            LineChartBarData(
              spots: scoreSpots,
              color: theme.scoreLineColor,
              barWidth: theme.scoreLineWidth,
              isCurved: false,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, idx) => FlDotCirclePainter(
                  radius: theme.dotRadius,
                  color: theme.scoreLineColor,
                  strokeWidth: 0,
                ),
              ),
            ),
            // Overlay: Garden Health H_t (dashed).
            if (healthSpots.isNotEmpty)
              LineChartBarData(
                spots: healthSpots,
                color: theme.healthLineColor,
                barWidth: theme.healthLineWidth,
                isCurved: true,
                preventCurveOverShooting: true,
                dashArray: const [4, 4],
                dotData: const FlDotData(show: false),
              ),
          ],
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 0.5,
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
                interval: 0.5,
                reservedSize: 32,
                getTitlesWidget: (value, _) {
                  if ((value * 10).round() % 5 != 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      value == 0 ? '0' : value.toStringAsFixed(1),
                      style: TextStyle(
                        color: theme.axisLabelColor,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _xTickInterval(points.length),
                reservedSize: 22,
                getTitlesWidget: (value, _) {
                  final i = value.round();
                  if ((value - i).abs() > 0.001) {
                    return const SizedBox.shrink();
                  }
                  if (i < 0 || i >= points.length) {
                    return const SizedBox.shrink();
                  }
                  final day = points[i].day;
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

  /// 5 plant-tier bands keyed off `H_t` thresholds (spec §2.3). Each is
  /// drawn at low alpha so the score line stays the dominant signal.
  static List<HorizontalRangeAnnotation> _bands(MoodScoreChartTheme theme) {
    // Defensive: fall back to a single neutral band if the caller passed
    // fewer than 5 colours.
    if (theme.tierBandColors.length < 5) {
      return const [];
    }
    return [
      // Flourishing  : H >= +0.4
      HorizontalRangeAnnotation(
        y1: 0.4,
        y2: 1.0,
        color: theme.tierBandColors[0],
      ),
      // Thriving     : +0.1 <= H < +0.4
      HorizontalRangeAnnotation(
        y1: 0.1,
        y2: 0.4,
        color: theme.tierBandColors[1],
      ),
      // Resting      : -0.1 < H < +0.1
      HorizontalRangeAnnotation(
        y1: -0.1,
        y2: 0.1,
        color: theme.tierBandColors[2],
      ),
      // Weathering   : -0.4 < H <= -0.1
      HorizontalRangeAnnotation(
        y1: -0.4,
        y2: -0.1,
        color: theme.tierBandColors[3],
      ),
      // Storm Season : H <= -0.4
      HorizontalRangeAnnotation(
        y1: -1.0,
        y2: -0.4,
        color: theme.tierBandColors[4],
      ),
    ];
  }

  /// Pick an x-axis tick interval that keeps the labels readable for
  /// 7-, 14-, and 30-day windows. Pure helper so tests can assert it.
  static double _xTickInterval(int dayCount) {
    if (dayCount <= 7) return 1;
    if (dayCount <= 14) return 2;
    return 5;
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
          'Your insights will appear here as your garden grows.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
