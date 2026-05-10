@Tags(['golden'])
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:moodbloom/features/garden/domain/entities/plant_tier.dart';
import 'package:moodbloom/features/garden/presentation/widgets/garden_bed.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

/// Visual goldens for the entry-driven [GardenBed]. Anchors the v1.0
/// polish (2026-05-10) regression "wipe still shows 3 flowers" and the
/// "real flower art" requirement: each species must depict a full
/// plant (stem + leaves + flower head) at canvas scale.
///
/// `animate: false` keeps the painter deterministic across frames.
void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: buildLightTheme(),
    debugShowCheckedModeBanner: false,
    home: Scaffold(body: Center(child: child)),
  );

  MoodEntry entry(MoodType m, String id) => MoodEntry(
    id: id,
    userId: 'u-1',
    mood: m,
    intensity: 4,
    text: '',
    createdAt: DateTime(2026, 5, 10, 10),
  );

  Future<void> snap(
    WidgetTester tester,
    String name, {
    required List<MoodEntry> entries,
    required PlantTier tier,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidgetBuilder(
      wrap(GardenBed(entries: entries, tier: tier, animate: false)),
      surfaceSize: const Size(800, 400),
    );
    await screenMatchesGolden(tester, name);
  }

  testGoldens('GardenBed — empty (TC-empty: wipe leaves no ghost flowers)', (
    tester,
  ) async {
    await snap(
      tester,
      'garden_bed_empty',
      entries: const [],
      tier: PlantTier.resting,
    );
  });

  testGoldens('GardenBed — single sunflower (Joy)', (tester) async {
    await snap(
      tester,
      'garden_bed_sunflower',
      entries: [entry(MoodType.happy, 'h')],
      tier: PlantTier.flourishing,
    );
  });

  testGoldens('GardenBed — single daisy (Okay)', (tester) async {
    await snap(
      tester,
      'garden_bed_daisy',
      entries: [entry(MoodType.okay, 'o')],
      tier: PlantTier.thriving,
    );
  });

  testGoldens('GardenBed — single forget-me-not (Sad)', (tester) async {
    await snap(
      tester,
      'garden_bed_forget_me_not',
      entries: [entry(MoodType.sad, 's')],
      tier: PlantTier.weathering,
    );
  });

  testGoldens('GardenBed — single poppy (Anger)', (tester) async {
    await snap(
      tester,
      'garden_bed_poppy',
      entries: [entry(MoodType.angry, 'a')],
      tier: PlantTier.weathering,
    );
  });

  testGoldens('GardenBed — single fern (Anxiety)', (tester) async {
    await snap(
      tester,
      'garden_bed_fern',
      entries: [entry(MoodType.anxious, 'x')],
      tier: PlantTier.thriving,
    );
  });

  testGoldens('GardenBed — single lavender (Calm)', (tester) async {
    await snap(
      tester,
      'garden_bed_lavender',
      entries: [entry(MoodType.calm, 'c')],
      tier: PlantTier.flourishing,
    );
  });

  testGoldens('GardenBed — mixed bed (resting tier, baseline ambient)', (
    tester,
  ) async {
    await snap(
      tester,
      'garden_bed_mixed_resting',
      entries: [
        entry(MoodType.happy, 'h'),
        entry(MoodType.calm, 'c'),
        entry(MoodType.okay, 'o'),
        entry(MoodType.sad, 's'),
      ],
      tier: PlantTier.resting,
    );
  });

  testGoldens(
    'GardenBed — mixed bed (flourishing tier — butterflies overlay)',
    (tester) async {
      await snap(
        tester,
        'garden_bed_mixed_flourishing',
        entries: [
          entry(MoodType.happy, 'h1'),
          entry(MoodType.happy, 'h2'),
          entry(MoodType.calm, 'c'),
          entry(MoodType.okay, 'o'),
        ],
        tier: PlantTier.flourishing,
      );
    },
  );

  testGoldens(
    'GardenBed — mixed bed (weathering tier — cloud shadow overlay)',
    (tester) async {
      await snap(
        tester,
        'garden_bed_mixed_weathering',
        entries: [
          entry(MoodType.sad, 's'),
          entry(MoodType.anxious, 'x'),
          entry(MoodType.okay, 'o'),
        ],
        tier: PlantTier.weathering,
      );
    },
  );

  testGoldens(
    'GardenBed — mixed bed (storm season — lanterns overlay, plants alive)',
    (tester) async {
      await snap(
        tester,
        'garden_bed_mixed_storm_season',
        entries: [
          entry(MoodType.sad, 's1'),
          entry(MoodType.sad, 's2'),
          entry(MoodType.angry, 'a'),
          entry(MoodType.anxious, 'x'),
        ],
        tier: PlantTier.stormSeason,
      );
    },
  );
}
