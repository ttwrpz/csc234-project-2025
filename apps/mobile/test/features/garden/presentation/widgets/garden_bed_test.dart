import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/domain/entities/plant_tier.dart';
import 'package:moodbloom/features/garden/presentation/widgets/garden_bed.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

import '../../../../helpers/pump_app.dart';

MoodEntry _entry(
  MoodType mood, {
  required String id,
  int intensity = 3,
  DateTime? createdAt,
}) {
  return MoodEntry(
    id: id,
    userId: 'u-1',
    mood: mood,
    intensity: intensity,
    text: '',
    createdAt: createdAt ?? DateTime(2026, 5, 10, 10),
  );
}

void main() {
  group('GardenBed — smoke', () {
    Future<void> pump(
      WidgetTester tester, {
      required List<MoodEntry> entries,
      required PlantTier tier,
    }) async {
      await pumpApp(
        tester,
        child: Scaffold(
          body: Center(
            child: GardenBed(entries: entries, tier: tier, animate: false),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('empty entries renders ground+grass only — no flowers', (
      tester,
    ) async {
      await pump(tester, entries: const [], tier: PlantTier.resting);
      expect(find.byType(GardenBed), findsOneWidget);
      // Semantics label changes shape on empty (no species join).
      expect(
        find.bySemanticsLabel(RegExp(r'Empty garden bed')),
        findsOneWidget,
      );
    });

    testWidgets('single happy entry surfaces sunflower in semantics', (
      tester,
    ) async {
      await pump(
        tester,
        entries: [_entry(MoodType.happy, id: 'a', intensity: 4)],
        tier: PlantTier.thriving,
      );
      expect(find.bySemanticsLabel(RegExp(r'sunflower')), findsOneWidget);
    });

    testWidgets('caps at 25 plants when entries exceed maximum', (
      tester,
    ) async {
      final base = DateTime(2026, 5, 10, 10);
      final entries = [
        for (var i = 0; i < 30; i += 1)
          _entry(
            MoodType.happy,
            id: 'e$i',
            intensity: 3,
            createdAt: base.subtract(Duration(hours: i)),
          ),
      ];
      await pump(tester, entries: entries, tier: PlantTier.flourishing);
      final bed = tester.widget<GardenBed>(find.byType(GardenBed));
      expect(bed.entries.length, 30, reason: 'inputs preserved on the widget');
      // Semantics label reflects the post-cap count (25 plants).
      expect(find.bySemanticsLabel(RegExp(r'25 plants')), findsOneWidget);
    });

    testWidgets('overflow badge shows "+N" when showOverflowBadge: true', (
      tester,
    ) async {
      final entries = [
        for (var i = 0; i < 30; i += 1)
          _entry(
            MoodType.happy,
            id: 'b$i',
            intensity: 3,
            createdAt: DateTime(2026, 5, 10).subtract(Duration(hours: i)),
          ),
      ];
      await pumpApp(
        tester,
        child: Scaffold(
          body: Center(
            child: GardenBed(
              entries: entries,
              tier: PlantTier.flourishing,
              animate: false,
              showOverflowBadge: true,
            ),
          ),
        ),
      );
      await tester.pump();
      // 30 entries minus the 25 visible cap = +5 hidden.
      expect(find.text('+5'), findsOneWidget);
    });

    testWidgets('mixed-mood week shows each species name in semantics', (
      tester,
    ) async {
      final entries = [
        _entry(MoodType.happy, id: 'h'),
        _entry(MoodType.sad, id: 's'),
        _entry(MoodType.calm, id: 'c'),
        _entry(MoodType.angry, id: 'a'),
        _entry(MoodType.anxious, id: 'x'),
        _entry(MoodType.okay, id: 'o'),
      ];
      await pump(tester, entries: entries, tier: PlantTier.thriving);
      // Semantics label joins the species set; just confirm a couple
      // distinct species appear.
      expect(find.bySemanticsLabel(RegExp(r'sunflower')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'forgetMeNot')), findsOneWidget);
    });

    for (final tier in PlantTier.values) {
      testWidgets('tier ${tier.name} renders without throwing', (tester) async {
        await pump(
          tester,
          entries: [_entry(MoodType.calm, id: 't-${tier.name}')],
          tier: tier,
        );
        expect(find.byType(GardenBed), findsOneWidget);
      });
    }
  });
}
