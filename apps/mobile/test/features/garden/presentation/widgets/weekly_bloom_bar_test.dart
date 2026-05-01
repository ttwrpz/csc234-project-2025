import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/domain/entities/garden_state.dart';
import 'package:moodbloom/features/garden/presentation/widgets/weekly_bloom_bar.dart';

/// Pumps [bar] inside a minimal MaterialApp host. The bar reads Theme for
/// label colors so a real ThemeData is required.
Future<void> _pumpBar(WidgetTester tester, WeeklyBloomBar bar) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: bar)),
    ),
  );
}

List<DayBloom> _days(List<DayBloomKind> kinds) {
  // Anchor on a fixed reference day so weekday letters are deterministic.
  final today = DateTime(2026, 4, 29);
  return [
    for (var i = 0; i < kinds.length; i += 1)
      DayBloom(
        day: today.subtract(Duration(days: i)),
        kind: kinds[i],
      ),
  ];
}

/// Walks the painted Container decorations under the bar and pulls out the
/// fill colors of cells whose height matches the bar cell height. Filters
/// out outer/inner layout containers that don't carry a BoxDecoration.
List<Color> _cellColors(WidgetTester tester) {
  final containers = tester
      .widgetList<Container>(find.byType(Container))
      .where((c) => c.decoration is BoxDecoration);
  return [
    for (final c in containers)
      ((c.decoration as BoxDecoration).color ?? const Color(0x00000000)),
  ];
}

void main() {
  group('WeeklyBloomBar', () {
    testWidgets('renders 7 cells when given 7 days', (tester) async {
      await _pumpBar(
        tester,
        WeeklyBloomBar(days: _days(List.filled(7, DayBloomKind.empty))),
      );
      final colors = _cellColors(tester);
      expect(colors, hasLength(7));
    });

    testWidgets('all-bloom week → all cells use the happy mood color', (
      tester,
    ) async {
      await _pumpBar(
        tester,
        WeeklyBloomBar(days: _days(List.filled(7, DayBloomKind.bloom))),
      );
      final colors = _cellColors(tester);
      expect(colors, everyElement(MoodBloomColors.moodHappy));
    });

    testWidgets('all-empty week → all cells use the dim surface color', (
      tester,
    ) async {
      await _pumpBar(
        tester,
        WeeklyBloomBar(days: _days(List.filled(7, DayBloomKind.empty))),
      );
      final colors = _cellColors(tester);
      expect(colors, everyElement(MoodBloomColors.surfaceDim));
    });

    testWidgets('mixed week → exactly the bloom days carry the happy color', (
      tester,
    ) async {
      // Index 0 = today; we expect today and the day-before-yesterday to
      // be blooms in this configuration.
      final kinds = <DayBloomKind>[
        DayBloomKind.bloom, // today
        DayBloomKind.empty, // yesterday
        DayBloomKind.bloom, // 2 days ago
        DayBloomKind.empty,
        DayBloomKind.empty,
        DayBloomKind.empty,
        DayBloomKind.empty,
      ];
      await _pumpBar(tester, WeeklyBloomBar(days: _days(kinds)));
      final colors = _cellColors(tester);
      final blooms = colors.where((c) => c == MoodBloomColors.moodHappy).length;
      final empties = colors
          .where((c) => c == MoodBloomColors.surfaceDim)
          .length;
      expect(blooms, 2);
      expect(empties, 5);
    });
  });
}
