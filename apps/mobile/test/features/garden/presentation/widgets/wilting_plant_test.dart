import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/presentation/widgets/wilting_plant.dart';

void main() {
  group('WiltingPlant', () {
    testWidgets('renders an Icons.spa glyph in the sad-mood colour', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: WiltingPlant(intensity: 2))),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.spa));
      expect(icon.icon, Icons.spa);
      expect(icon.color, MoodBloomColors.moodSad);
    });

    testWidgets('does not render Icons.local_florist (flower regression)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: WiltingPlant(intensity: 1))),
      );

      expect(find.byIcon(Icons.local_florist), findsNothing);
    });

    testWidgets('accepts each valid intensity 1..3 without assertion', (
      tester,
    ) async {
      for (final i in const [1, 2, 3]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: WiltingPlant(intensity: i)),
          ),
        );
        expect(find.byType(WiltingPlant), findsOneWidget);
      }
    });

    test('asserts intensity outside 1..3', () {
      expect(() => WiltingPlant(intensity: 0), throwsAssertionError);
      expect(() => WiltingPlant(intensity: 4), throwsAssertionError);
      expect(() => WiltingPlant(intensity: 5), throwsAssertionError);
    });
  });
}
