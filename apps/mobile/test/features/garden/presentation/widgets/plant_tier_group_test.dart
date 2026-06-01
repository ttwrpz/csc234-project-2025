import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/domain/entities/plant_tier.dart';
import 'package:moodbloom/features/garden/presentation/widgets/plant_tier_group.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('PlantTierGroup - smoke (one per tier)', () {
    Future<void> pump(WidgetTester tester, PlantTier tier) async {
      await pumpApp(
        tester,
        child: Scaffold(
          body: PlantTierGroup(tier: tier, entryCount: 3, animate: false),
        ),
      );
      // The widget itself doesn't animate but the surrounding theme
      // setup may emit a frame; one pump settles it.
      await tester.pump();
    }

    testWidgets('flourishing tier renders without throwing', (tester) async {
      await pump(tester, PlantTier.flourishing);
      expect(find.byType(PlantTierGroup), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(r'Flourishing garden')),
        findsOneWidget,
      );
    });

    testWidgets('thriving tier renders without throwing', (tester) async {
      await pump(tester, PlantTier.thriving);
      expect(find.bySemanticsLabel(RegExp(r'Thriving garden')), findsOneWidget);
    });

    testWidgets('resting tier renders without throwing', (tester) async {
      await pump(tester, PlantTier.resting);
      expect(find.bySemanticsLabel(RegExp(r'Resting garden')), findsOneWidget);
    });

    testWidgets('weathering tier renders without throwing', (tester) async {
      await pump(tester, PlantTier.weathering);
      expect(
        find.bySemanticsLabel(RegExp(r'Weathering garden')),
        findsOneWidget,
      );
    });

    testWidgets('storm season tier renders without throwing', (tester) async {
      await pump(tester, PlantTier.stormSeason);
      expect(find.bySemanticsLabel(RegExp(r'Storm Season')), findsOneWidget);
    });
  });
}
