@Tags(['golden'])
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:moodbloom/features/garden/domain/entities/plant_tier.dart';
import 'package:moodbloom/features/garden/presentation/widgets/plant_tier_group.dart';

/// Visual goldens for the 5 ecosystem plant tiers. **Most load-bearing
/// test in the S4 garden suite — anchors TC-24** (plants-never-die copy
/// rule, ADR-0010 §1).
///
/// Each golden must depict plants visibly **alive**: stems vertical,
/// leaves intact, buds either blossoming (Flourishing/Thriving) or
/// closed but unbroken (Resting/Weathering/Storm Season). The Storm
/// Season golden in particular MUST NOT show wilting silhouettes,
/// droop arcs, or broken stems — rain belongs to `AtmosphereOverlay`,
/// not to the plant layer. Lanterns and an implied shelter arch are
/// the storm tier's hopeful focal points.
///
/// `animate: false` keeps the painter deterministic (no butterfly drift
/// or lantern glow phase change between frames). All five tiers share
/// the same surface size (800×600) and `entryCount: 5` so the goldens
/// differ only in the painter's tier branch — easy diffs in review.
void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: buildLightTheme(),
    debugShowCheckedModeBanner: false,
    home: Scaffold(body: Center(child: child)),
  );

  testGoldens('PlantTierGroup — flourishing', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidgetBuilder(
      wrap(
        const PlantTierGroup(
          tier: PlantTier.flourishing,
          entryCount: 5,
          animate: false,
        ),
      ),
      surfaceSize: const Size(800, 600),
    );
    await screenMatchesGolden(tester, 'plant_tier_group_flourishing');
  });

  testGoldens('PlantTierGroup — thriving', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidgetBuilder(
      wrap(
        const PlantTierGroup(
          tier: PlantTier.thriving,
          entryCount: 5,
          animate: false,
        ),
      ),
      surfaceSize: const Size(800, 600),
    );
    await screenMatchesGolden(tester, 'plant_tier_group_thriving');
  });

  testGoldens('PlantTierGroup — resting', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidgetBuilder(
      wrap(
        const PlantTierGroup(
          tier: PlantTier.resting,
          entryCount: 5,
          animate: false,
        ),
      ),
      surfaceSize: const Size(800, 600),
    );
    await screenMatchesGolden(tester, 'plant_tier_group_resting');
  });

  testGoldens('PlantTierGroup — weathering', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidgetBuilder(
      wrap(
        const PlantTierGroup(
          tier: PlantTier.weathering,
          entryCount: 5,
          animate: false,
        ),
      ),
      surfaceSize: const Size(800, 600),
    );
    await screenMatchesGolden(tester, 'plant_tier_group_weathering');
  });

  testGoldens('PlantTierGroup — storm season (TC-24 anchor — plants alive)', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidgetBuilder(
      wrap(
        const PlantTierGroup(
          tier: PlantTier.stormSeason,
          entryCount: 5,
          animate: false,
        ),
      ),
      surfaceSize: const Size(800, 600),
    );
    await screenMatchesGolden(tester, 'plant_tier_group_storm_season');
  });
}
