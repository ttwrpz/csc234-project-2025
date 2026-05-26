import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moodbloom/features/garden/domain/entities/flower_species.dart';
import 'package:moodbloom/features/garden/domain/entities/plant_tier.dart';
import 'package:moodbloom/features/garden/presentation/widgets/flower_sprite.dart';
import 'package:moodbloom/features/garden/presentation/widgets/garden_bed.dart';
import 'package:moodbloom/features/garden/presentation/widgets/per_flower_detail_modal.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

import '../../../../helpers/pump_app.dart';

MoodEntry _entry({
  required String id,
  required MoodType mood,
  int intensity = 3,
  String text = '',
  DateTime? createdAt,
}) {
  return MoodEntry(
    id: id,
    userId: 'u-1',
    mood: mood,
    intensity: intensity,
    text: text,
    createdAt: createdAt ?? DateTime(2026, 5, 10, 14, 30),
  );
}

void main() {
  group('PerFlowerDetailModal - TC-7 entry-detail surface', () {
    testWidgets('renders mood title, intensity dots, text snippet, and date', (
      tester,
    ) async {
      await pumpApp(
        tester,
        child: PerFlowerDetailModal(
          entry: _entry(
            id: 'e-1',
            mood: MoodType.happy,
            intensity: 4,
            text: 'had a nice walk',
            createdAt: DateTime(2026, 5, 10, 14, 30),
          ),
        ),
      );

      // Mood title — sentence-cased from `MoodType.name` ("happy" → "Happy").
      expect(find.text('Happy'), findsOneWidget);
      // Body excerpt.
      expect(find.text('had a nice walk'), findsOneWidget);
      // Date — formatted as "Mon D, HH:MM" in the modal's `_formatDate`.
      // We assert on the substring "May 10" + ":30" so the test stays
      // resilient to a future swap from 24-hr to 12-hr clock formatting.
      expect(find.textContaining('May 10'), findsOneWidget);
      expect(find.textContaining(':30'), findsOneWidget);
      // Intensity dots — one MbIntensityDots widget with the value we
      // passed in. Reading the field directly is more diagnostic than
      // counting filled dots from the painter.
      final dots = tester.widget<MbIntensityDots>(find.byType(MbIntensityDots));
      expect(dots.value, 4, reason: 'modal forwards entry.intensity verbatim');
    });

    testWidgets('empty entry text renders the em-dash placeholder', (
      tester,
    ) async {
      await pumpApp(
        tester,
        child: PerFlowerDetailModal(
          entry: _entry(id: 'e-2', mood: MoodType.calm, text: ''),
        ),
      );

      // Empty-string text resolves to "—" in the modal's body card.
      expect(find.text('-'), findsOneWidget);
    });

    testWidgets(
      'sprite uses the mood-to-species mapping (sad → forget-me-not)',
      (tester) async {
        await pumpApp(
          tester,
          child: PerFlowerDetailModal(
            entry: _entry(id: 'e-3', mood: MoodType.sad, text: 'tough day'),
          ),
        );

        // FlowerSpecies.forMood(MoodType.sad) == FlowerSpecies.forgetMeNot.
        // We assert the rendered FlowerSprite has the matching species.
        final sprite = tester.widget<FlowerSprite>(find.byType(FlowerSprite));
        expect(sprite.species, FlowerSpecies.forgetMeNot);
      },
    );

    testWidgets('sprite uses the mood-to-species mapping (anxious → fern)', (
      tester,
    ) async {
      await pumpApp(
        tester,
        child: PerFlowerDetailModal(
          entry: _entry(id: 'e-4', mood: MoodType.anxious),
        ),
      );
      final sprite = tester.widget<FlowerSprite>(find.byType(FlowerSprite));
      expect(sprite.species, FlowerSpecies.fern);
    });

    testWidgets('"Open entry" CTA navigates to /history/<id>', (tester) async {
      // The modal calls `Navigator.of(context).pop()` BEFORE
      // `context.go(...)` so the bottom-sheet route is gone before the
      // router push. We host the modal under a real
      // `showModalBottomSheet` so the pop tears down the sheet route
      // (and not the page below) — same wiring production uses.
      final entry = _entry(
        id: 'e-route',
        mood: MoodType.okay,
        text: 'routing test',
      );

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: Builder(
                builder: (innerContext) => Center(
                  child: ElevatedButton(
                    onPressed: () =>
                        PerFlowerDetailModal.show(innerContext, entry),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/history/:id',
            builder: (_, state) =>
                Scaffold(body: Text('history-${state.pathParameters['id']}')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router, theme: buildLightTheme()),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(PerFlowerDetailModal), findsOneWidget);

      await tester.tap(find.text('Open entry'));
      await tester.pumpAndSettle();

      // Router lands on the stub `/history/<id>` page.
      expect(find.text('history-e-route'), findsOneWidget);
    });

    testWidgets('"Close" button dismisses the modal via Navigator.pop', (
      tester,
    ) async {
      // Mount the modal inside a host whose builder pushes the modal
      // via the same idiom production uses (`showModalBottomSheet`).
      // That gives us a real Navigator to verify the pop.
      final entry = _entry(
        id: 'e-close',
        mood: MoodType.happy,
        text: 'will close',
      );

      Widget host(BuildContext outerContext) {
        return Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => PerFlowerDetailModal.show(outerContext, entry),
              child: const Text('open'),
            ),
          ),
        );
      }

      await pumpApp(tester, child: Builder(builder: host));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Modal is mounted.
      expect(find.byType(PerFlowerDetailModal), findsOneWidget);
      expect(find.text('will close'), findsOneWidget);

      // Tap "Close" and confirm the sheet is torn down.
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(PerFlowerDetailModal), findsNothing);
    });
  });

  group('GardenBed - TC-7 per-flower tap dispatches onFlowerTap', () {
    testWidgets(
      'tapping the hit-area for the first flower invokes onFlowerTap with the '
      'corresponding MoodEntry',
      (tester) async {
        final entries = [
          _entry(
            id: 'a',
            mood: MoodType.happy,
            createdAt: DateTime(2026, 5, 10, 10),
          ),
          _entry(
            id: 'b',
            mood: MoodType.sad,
            createdAt: DateTime(2026, 5, 10, 9),
          ),
          _entry(
            id: 'c',
            mood: MoodType.calm,
            createdAt: DateTime(2026, 5, 10, 8),
          ),
        ];

        final tapped = <MoodEntry>[];
        await pumpApp(
          tester,
          child: Scaffold(
            body: Center(
              child: GardenBed(
                entries: entries,
                tier: PlantTier.thriving,
                animate: false,
                onFlowerTap: tapped.add,
              ),
            ),
          ),
        );
        await tester.pump();

        // The bed wires per-flower hit-spots as round InkResponse hit-
        // spots (v1.5 final polish — switched from InkWell rectangles to
        // CircleBorder-shaped InkResponses so the tap area matches the
        // flower silhouette). One per visible entry when `onFlowerTap !=
        // null`. The bed sorts entries by `createdAt` descending, so
        // entry 'a' (10:00) is at index 0.
        final inkWell = find.descendant(
          of: find.byType(GardenBed),
          matching: find.byType(InkResponse),
        );
        expect(
          inkWell,
          findsNWidgets(3),
          reason: 'one hit-spot per entry when onFlowerTap is non-null',
        );
        await tester.tap(inkWell.first);
        // Let the ink-splash animation play through to disposal so the
        // test binding's perf-mode-disposed invariant doesn't fail.
        await tester.pumpAndSettle();

        expect(tapped, hasLength(1));
        expect(
          tapped.single.id,
          'a',
          reason:
              'first hit-spot maps to first sorted entry (newest createdAt)',
        );
      },
    );

    testWidgets('without onFlowerTap the bed does NOT mount hit-spots', (
      tester,
    ) async {
      await pumpApp(
        tester,
        child: Scaffold(
          body: Center(
            child: GardenBed(
              entries: [_entry(id: 'z', mood: MoodType.happy)],
              tier: PlantTier.flourishing,
              animate: false,
            ),
          ),
        ),
      );
      await tester.pump();

      // No callback → no Positioned hit-spots in the Stack. The bed
      // falls back to a bare CustomPaint canvas — no InkResponse
      // anywhere.
      final inkWell = find.descendant(
        of: find.byType(GardenBed),
        matching: find.byType(InkResponse),
      );
      expect(inkWell, findsNothing);
    });
  });
}
