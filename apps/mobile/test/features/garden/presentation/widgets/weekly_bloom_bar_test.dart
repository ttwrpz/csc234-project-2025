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
      theme: buildLightTheme(),
      home: Scaffold(body: Center(child: bar)),
    ),
  );
}

List<DayBloom> _days(List<DayBloomKind> kinds) {
  final today = DateTime(2026, 4, 29);
  return [
    for (var i = 0; i < kinds.length; i += 1)
      DayBloom(
        day: today.subtract(Duration(days: i)),
        kind: kinds[i],
      ),
  ];
}

/// Returns one cell descriptor per painted bar `Container` directly under a
/// `_BloomColumn` (i.e. the data cells, not surrounding layout containers).
/// We discriminate by whether the container has a non-null `borderRadius`
/// matching the bloom-cell radius (`MoodBloomSpacing.radiusSm`).
List<({Color? color, bool empty})> _cells(WidgetTester tester) {
  final containers = tester.widgetList<Container>(find.byType(Container)).where(
    (c) {
      final dec = c.decoration;
      if (dec is! BoxDecoration) return false;
      final br = dec.borderRadius;
      return br is BorderRadius && br.topLeft.x == MoodBloomSpacing.radiusSm;
    },
  );
  return [
    for (final c in containers)
      (
        color: (c.decoration as BoxDecoration).color,
        empty:
            ((c.decoration as BoxDecoration).color ?? Colors.transparent).a ==
            0.0,
      ),
  ];
}

void main() {
  group('WeeklyBloomBar', () {
    testWidgets('renders 7 cells when given 7 days', (tester) async {
      await _pumpBar(
        tester,
        WeeklyBloomBar(days: _days(List.filled(7, DayBloomKind.empty))),
      );
      expect(_cells(tester), hasLength(7));
    });

    testWidgets('all-bloom week → every cell is non-empty', (tester) async {
      await _pumpBar(
        tester,
        WeeklyBloomBar(days: _days(List.filled(7, DayBloomKind.bloom))),
      );
      final cells = _cells(tester);
      expect(cells, hasLength(7));
      expect(cells.every((c) => !c.empty), isTrue);
    });

    testWidgets('all-empty week → every cell is empty (transparent fill)', (
      tester,
    ) async {
      await _pumpBar(
        tester,
        WeeklyBloomBar(days: _days(List.filled(7, DayBloomKind.empty))),
      );
      final cells = _cells(tester);
      expect(cells, hasLength(7));
      expect(cells.every((c) => c.empty), isTrue);
    });

    testWidgets('mixed week → exactly the bloom days carry a colored bar', (
      tester,
    ) async {
      final kinds = <DayBloomKind>[
        DayBloomKind.bloom,
        DayBloomKind.empty,
        DayBloomKind.bloom,
        DayBloomKind.empty,
        DayBloomKind.empty,
        DayBloomKind.empty,
        DayBloomKind.empty,
      ];
      await _pumpBar(tester, WeeklyBloomBar(days: _days(kinds)));
      final cells = _cells(tester);
      expect(cells, hasLength(7));
      expect(cells.where((c) => !c.empty), hasLength(2));
      expect(cells.where((c) => c.empty), hasLength(5));
    });
  });
}
