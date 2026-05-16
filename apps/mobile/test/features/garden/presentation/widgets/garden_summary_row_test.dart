import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moodbloom/features/garden/domain/entities/atmosphere.dart';
import 'package:moodbloom/features/garden/domain/entities/garden_state.dart';
import 'package:moodbloom/features/garden/domain/entities/plant_tier.dart';
import 'package:moodbloom/features/garden/presentation/widgets/garden_summary_row.dart';

/// Builds a `GardenState` with the given tier and at least one entry
/// so the empty-state short-circuit (which collapses the pill) does
/// not fire. `last7Days` is filled with placeholder cells — the row
/// only uses the tier label, not the strip data.
GardenState _stateFor(PlantTier tier) {
  return GardenState(
    gardenHealth: switch (tier) {
      PlantTier.flourishing => 0.5,
      PlantTier.thriving => 0.2,
      PlantTier.resting => 0.0,
      PlantTier.weathering => -0.2,
      PlantTier.stormSeason => -0.5,
    },
    plantTier: tier,
    atmosphere: Atmosphere.calmSunny,
    last7Days: List.generate(
      7,
      (i) => DayScore(
        day: DateTime(2026, 5, 16).subtract(Duration(days: i)),
        avgScore: null,
        entryCount: 0,
      ),
    ),
    // Non-zero so isEmpty is false — the pill renders.
    totalEntryCount: 3,
  );
}

Future<void> _pumpRow(WidgetTester tester, GardenState state) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(body: GardenSummaryRow(state: state)),
      ),
      GoRoute(
        path: '/analytics',
        builder: (_, _) => const Scaffold(body: Text('analytics-stub')),
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(routerConfig: router, theme: buildLightTheme()),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('GardenSummaryRow — tier pill (v1.5 polish, plant-impact)', () {
    testWidgets('renders the "Flourishing" label for the flourishing tier', (
      tester,
    ) async {
      await _pumpRow(tester, _stateFor(PlantTier.flourishing));
      // Tagline's own "flourishing week." would shadow an exact-match
      // on "Flourishing"; use a Text-widget-by-data filter so the
      // pill's Text node (capital F, alone) is found explicitly.
      final pillText = find.byWidgetPredicate(
        (w) => w is Text && w.data == 'Flourishing',
      );
      expect(pillText, findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(r'Garden state: Flourishing')),
        findsOneWidget,
      );
    });

    testWidgets('renders the "Thriving" label for the thriving tier', (
      tester,
    ) async {
      await _pumpRow(tester, _stateFor(PlantTier.thriving));
      expect(find.text('Thriving'), findsOneWidget);
    });

    testWidgets('renders the "Resting" label for the resting tier', (
      tester,
    ) async {
      await _pumpRow(tester, _stateFor(PlantTier.resting));
      expect(find.text('Resting'), findsOneWidget);
    });

    testWidgets('renders the "Weathering" label for the weathering tier', (
      tester,
    ) async {
      await _pumpRow(tester, _stateFor(PlantTier.weathering));
      expect(find.text('Weathering'), findsOneWidget);
    });

    testWidgets('renders the "Storm Season" label for the storm-season tier', (
      tester,
    ) async {
      await _pumpRow(tester, _stateFor(PlantTier.stormSeason));
      expect(find.text('Storm Season'), findsOneWidget);
    });

    testWidgets('pill collapses on empty state so the tagline reads alone', (
      tester,
    ) async {
      final emptyState = GardenState(
        gardenHealth: 0.0,
        plantTier: PlantTier.resting,
        atmosphere: Atmosphere.calmSunny,
        last7Days: List.generate(
          7,
          (i) => DayScore(
            day: DateTime(2026, 5, 16).subtract(Duration(days: i)),
            avgScore: null,
            entryCount: 0,
          ),
        ),
        totalEntryCount: 0,
      );
      await _pumpRow(tester, emptyState);
      // Empty state hides the pill (no badge to assert on a user
      // who has logged nothing) and surfaces the empty-state tagline.
      expect(find.text('Resting'), findsNothing);
      expect(find.textContaining('Plant your first mood'), findsOneWidget);
    });
  });
}
