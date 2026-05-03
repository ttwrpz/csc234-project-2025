import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';
import 'package:moodbloom/features/mood/presentation/widgets/mood_type_grid.dart';
import 'package:moodbloom/features/mood/presentation/widgets/mood_type_tile.dart';

Future<void> _pumpGrid(
  WidgetTester tester, {
  MoodType? selected,
  ValueChanged<MoodType>? onSelect,
}) async {
  // Tall surface so all six tiles are laid out and visible.
  await tester.binding.setSurfaceSize(const Size(800, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: MoodTypeGrid(selected: selected, onSelect: onSelect ?? (_) {}),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('MoodTypeGrid', () {
    testWidgets('renders one tile per MoodType (six in total)', (tester) async {
      await _pumpGrid(tester);

      expect(
        find.byType(MoodTypeTile),
        findsNWidgets(MoodType.values.length),
        reason: 'grid must render exactly one tile per MoodType enum value',
      );
      // Each enum label is rendered once.
      for (final type in MoodType.values) {
        expect(
          find.text(type.name),
          findsOneWidget,
          reason: 'tile for ${type.name} must show its label',
        );
      }
    });

    testWidgets('tapping a tile invokes onSelect with the matching MoodType', (
      tester,
    ) async {
      MoodType? captured;
      await _pumpGrid(tester, onSelect: (m) => captured = m);

      await tester.tap(find.text(MoodType.calm.name));
      await tester.pumpAndSettle();

      expect(
        captured,
        equals(MoodType.calm),
        reason: 'onSelect must receive the tapped tile\'s MoodType',
      );
    });

    testWidgets(
      'selected MoodType yields exactly one tile with selected: true',
      (tester) async {
        await _pumpGrid(tester, selected: MoodType.happy);

        final selectedTiles = find.byWidgetPredicate(
          (w) => w is MoodTypeTile && w.selected,
        );
        expect(
          selectedTiles,
          findsOneWidget,
          reason: 'only the selected MoodType\'s tile may report selected:true',
        );
        // And it is the right one.
        expect(
          find.byWidgetPredicate(
            (w) => w is MoodTypeTile && w.selected && w.type == MoodType.happy,
          ),
          findsOneWidget,
        );
      },
    );
  });
}
