import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/domain/entities/flower_species.dart';
import 'package:moodbloom/features/garden/presentation/widgets/flower_sprite.dart';

/// Wraps the sprite in a [MaterialApp] that registers [MbMoodPalette]
/// as a `ThemeExtension`, mirroring how the running app provides it.
/// Without this the sprite cannot resolve its default tint.
Widget _harness(Widget child) {
  return MaterialApp(
    theme: ThemeData.light().copyWith(
      extensions: const <ThemeExtension<dynamic>>[MbMoodPalette.shared],
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('FlowerSprite — renders for each species', () {
    for (final species in FlowerSpecies.values) {
      testWidgets('species=${species.name} → exposes a CustomPaint', (
        tester,
      ) async {
        await tester.pumpWidget(_harness(FlowerSprite(species: species)));
        // The sprite uses a single CustomPaint internally; we don't
        // pin a specific painter type because the painter is private.
        expect(find.byType(CustomPaint), findsWidgets);
        expect(find.byType(FlowerSprite), findsOneWidget);
      });
    }
  });

  group('FlowerSprite — semantics label', () {
    testWidgets(
      'excludeSemantics: true (default) → sprite is hidden from a11y tree',
      (tester) async {
        await tester.pumpWidget(
          _harness(const FlowerSprite(species: FlowerSpecies.sunflower)),
        );
        // The sprite itself does not contribute a semantics label; the
        // parent (MoodEntryTile) carries the mood label instead.
        expect(find.bySemanticsLabel('sunflower flower'), findsNothing);
      },
    );

    testWidgets(
      'excludeSemantics: false → label format is "<species> flower"',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            const FlowerSprite(
              species: FlowerSpecies.sunflower,
              excludeSemantics: false,
            ),
          ),
        );
        expect(find.bySemanticsLabel('sunflower flower'), findsOneWidget);
      },
    );

    testWidgets('fern uses the "leaf" suffix, not "flower"', (tester) async {
      await tester.pumpWidget(
        _harness(
          const FlowerSprite(
            species: FlowerSpecies.fern,
            excludeSemantics: false,
          ),
        ),
      );
      expect(find.bySemanticsLabel('fern leaf'), findsOneWidget);
      expect(find.bySemanticsLabel('fern flower'), findsNothing);
    });

    test('semanticLabelOf is exhaustive — every species has a label', () {
      for (final s in FlowerSpecies.values) {
        final label = FlowerSprite.semanticLabelOf(s);
        expect(label, isNotEmpty);
        expect(label, contains(s == FlowerSpecies.fern ? 'leaf' : 'flower'));
      }
    });
  });

  group('FlowerSprite — sizing', () {
    testWidgets('default size is 24×24', (tester) async {
      await tester.pumpWidget(
        _harness(const FlowerSprite(species: FlowerSpecies.daisy)),
      );
      final sized = tester
          .widgetList<SizedBox>(
            find.descendant(
              of: find.byType(FlowerSprite),
              matching: find.byType(SizedBox),
            ),
          )
          .firstWhere((s) => s.width == 24 && s.height == 24);
      expect(sized.width, 24);
      expect(sized.height, 24);
    });

    testWidgets('size: 64 → painter inherits the explicit 64×64 box', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(const FlowerSprite(species: FlowerSpecies.poppy, size: 64)),
      );
      final sized = tester
          .widgetList<SizedBox>(
            find.descendant(
              of: find.byType(FlowerSprite),
              matching: find.byType(SizedBox),
            ),
          )
          .firstWhere((s) => s.width == 64 && s.height == 64);
      expect(sized.width, 64);
      expect(sized.height, 64);
    });
  });
}
