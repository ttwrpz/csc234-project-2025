@Tags(['golden'])
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:moodbloom/features/garden/domain/entities/garden_state.dart';
import 'package:moodbloom/features/garden/presentation/widgets/daily_score_strip.dart';

/// Visual goldens for the 7-day score strip across the three
/// load-bearing series shapes. The strip is the visual successor to the
/// deleted `WeeklyBloomBar` and is the only place where empty/positive/
/// negative cells share a row, so its layout regression net belongs in
/// the S4 garden golden suite.
///
/// Three scenarios, all anchored to today = 2026-05-09 so the weekday
/// labels are stable across runs:
///   * empty       — 7 placeholder cells (avgScore null, count 0).
///   * all_positive — 7 cells with avgScore ramping +0.2 .. +1.0.
///   * mixed        — 4 negative cells, 2 positive cells, 1 null cell.
///
/// Surface is 800×160 (the strip is wide and short — 160 dp leaves
/// breathing room for the header row + the 60 dp cell column inside
/// 16 dp Scaffold padding). The use case emits the list newest-first;
/// the widget reverses internally so today's cell sits at the right
/// edge.
void main() {
  // Anchor day matches the brief — keeps the rendered weekday letters
  // stable in CI regardless of the host's clock.
  final today = DateTime(2026, 5, 9);

  List<DayScore> series(List<double?> avgs) {
    // Newest-first list of 7 cells, matching the use-case contract.
    return [
      for (var i = 0; i < 7; i += 1)
        DayScore(
          day: today.subtract(Duration(days: i)),
          avgScore: avgs[i],
          entryCount: avgs[i] == null ? 0 : 1,
        ),
    ];
  }

  Widget wrap(Widget child) => MaterialApp(
    theme: buildLightTheme(),
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );

  testGoldens('DailyScoreStrip — empty week (7 placeholder cells)', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 160));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final days = series(List<double?>.filled(7, null));
    await tester.pumpWidgetBuilder(
      wrap(DailyScoreStrip(last7Days: days)),
      surfaceSize: const Size(800, 160),
    );
    await screenMatchesGolden(tester, 'daily_score_strip_empty');
  });

  testGoldens('DailyScoreStrip — all-positive week (+0.2 .. +1.0)', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 160));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // Newest-first: today=+1.0, yesterday=+0.86, …, 6 days ago=+0.2.
    // Linear ramp so reviewers can read the magnitude shading at a
    // glance and the strip exercises both ends of the positive scale.
    final avgs = <double?>[for (var i = 0; i < 7; i += 1) 1.0 - (i * 0.8 / 6)];
    final days = series(avgs);

    await tester.pumpWidgetBuilder(
      wrap(DailyScoreStrip(last7Days: days)),
      surfaceSize: const Size(800, 160),
    );
    await screenMatchesGolden(tester, 'daily_score_strip_all_positive');
  });

  testGoldens(
    'DailyScoreStrip — mixed week (4 negative / 2 positive / 1 null)',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 160));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Order is newest-first so cell[0] is today. The mix gives every
      // cell type a presence in the row so the golden locks the three
      // distinct fills (positive, gentler, placeholder) side-by-side.
      final days = series(const <double?>[
        0.7, // today — positive
        -0.5, // yesterday — gentler
        null, // 2 days ago — empty placeholder
        -0.8, // 3 days ago — gentler (deeper)
        0.3, // 4 days ago — positive (smaller)
        -0.4, // 5 days ago — gentler
        -0.6, // 6 days ago — gentler
      ]);

      await tester.pumpWidgetBuilder(
        wrap(DailyScoreStrip(last7Days: days)),
        surfaceSize: const Size(800, 160),
      );
      await screenMatchesGolden(tester, 'daily_score_strip_mixed');
    },
  );
}
