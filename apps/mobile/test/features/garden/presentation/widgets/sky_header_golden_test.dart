@Tags(['golden'])
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:moodbloom/features/garden/data/providers.dart';
import 'package:moodbloom/features/garden/domain/entities/atmosphere.dart';
import 'package:moodbloom/features/garden/domain/entities/garden_state.dart';
import 'package:moodbloom/features/garden/domain/entities/plant_tier.dart';
import 'package:moodbloom/features/garden/presentation/widgets/sky_header.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

import '../../../../support/golden_fonts.dart';

/// NEW goldens for the garden sky hero (`SkyHeader`). This widget did not
/// have golden coverage before; it is the most prominent surface in the
/// app (the per-tier sky gradient + atmosphere painter + 7-day plot
/// strip), so it earns a baseline.
///
/// Determinism: `SkyHeader` exposes `@visibleForTesting animate = false`,
/// which renders a single still frame (t = 0) of the cloud/bird/rain
/// ticker so two consecutive renders match and `pumpAndSettle` returns.
/// We pin a fixed `weekStart` and a fixed mood entry per day so the plot
/// strip is identical on every run.
///
/// Coverage:
///   - Flourishing tier, light theme   (best-case bright sky)
///   - Storm Season tier, light theme  (rain + lightning, plants sheltered)
///   - Flourishing tier, dark theme    (moon + fireflies + aurora variant)
void main() {
  installOfflineGoogleFonts();

  // Fixed Monday-aligned local-midnight so the strip's 7 day plots are
  // stable across runs.
  final weekStart = DateTime(2026, 5, 4);

  // One entry per day of the week so the plot strip renders 7 plants.
  final weekEntries = <MoodEntry>[
    for (var i = 0; i < 7; i++)
      MoodEntry(
        id: 'e-$i',
        userId: 'u-1',
        mood: i.isEven ? MoodType.happy : MoodType.calm,
        intensity: 3,
        text: '',
        createdAt: weekStart.add(Duration(days: i, hours: 9)),
      ),
  ];

  GardenState stateFor(PlantTier tier, double health, Atmosphere atmosphere) {
    return GardenState(
      gardenHealth: health,
      plantTier: tier,
      atmosphere: atmosphere,
      last7Days: [
        for (var i = 0; i < 7; i++)
          DayScore(
            day: weekStart.add(Duration(days: i)),
            avgScore: i.isEven ? 0.6 : 0.4,
            entryCount: 1,
          ),
      ],
      totalEntryCount: 7,
    );
  }

  Future<void> pumpHeader(
    WidgetTester tester, {
    required ThemeData theme,
    required GardenState state,
    required String goldenName,
  }) async {
    await tester.pumpWidgetBuilder(
      SkyHeader(
        state: state,
        weekEntries: weekEntries,
        weekStart: weekStart,
        animate: false,
      ),
      wrapper: (child) => ProviderScope(
        overrides: [
          // SkyHeader -> SkyPlotStrip -> _SkinnedPlant watches the skin
          // resolver. Pin every species to the classic meadow shape with
          // no accent so the plot strip renders deterministically without
          // touching Firestore-backed skin streams.
          resolvedPlantSkinProvider.overrideWith(
            (ref, species) => (style: GardenSkinId.meadow, accentArgb: null),
          ),
        ],
        child: MaterialApp(
          theme: theme,
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      ),
      surfaceSize: const Size(420, 380),
    );
    // SkyHeader builds its inner `AtmosphereOverlay` with the default
    // `animate: true`, so the rain/sun-ray ticker never lets
    // `pumpAndSettle` (the default golden pump) terminate. Pump a single
    // fixed frame instead - the SkyHeader's own painter is pinned to a
    // still frame via `animate: false`, and one fixed-duration pump
    // gives the overlay a deterministic phase without waiting for the
    // (endless) animation to settle.
    await screenMatchesGolden(
      tester,
      goldenName,
      customPump: (t) => t.pump(const Duration(milliseconds: 16)),
    );
  }

  testGoldens('SkyHeader - flourishing tier, light theme', (tester) async {
    await pumpHeader(
      tester,
      theme: buildLightTheme(),
      state: stateFor(PlantTier.flourishing, 0.6, Atmosphere.brightSunny),
      goldenName: 'sky_header_flourishing_light',
    );
  });

  testGoldens('SkyHeader - storm season tier, light theme', (tester) async {
    await pumpHeader(
      tester,
      theme: buildLightTheme(),
      state: stateFor(PlantTier.stormSeason, -0.6, Atmosphere.storm),
      goldenName: 'sky_header_storm_light',
    );
  });

  testGoldens('SkyHeader - flourishing tier, dark theme', (tester) async {
    await pumpHeader(
      tester,
      theme: buildDarkTheme(),
      state: stateFor(PlantTier.flourishing, 0.6, Atmosphere.brightSunny),
      goldenName: 'sky_header_flourishing_dark',
    );
  });
}
