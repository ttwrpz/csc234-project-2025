import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/presentation/widgets/rain_cloud.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

void main() {
  group('RainCloud', () {
    testWidgets('animate: false → renders a CustomPaint with no timers', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RainCloud(
              entryId: 'e-static',
              mood: MoodType.anxious,
              intensity: 4,
              animate: false,
            ),
          ),
        ),
      );

      // Pump well past the animation window — without controllers there
      // are no scheduled timers to drain.
      await tester.pump(const Duration(seconds: 30));
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets(
      'animate: true → drift cycle exposes a non-zero opacity envelope',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: RainCloud(
                entryId: 'fade-id',
                mood: MoodType.angry,
                intensity: 5,
                indexInScene: 0,
              ),
            ),
          ),
        );

        // Initial frame: just past t=0 — opacity envelope is starting
        // to ramp up but the cloud is rendered.
        await tester.pump(const Duration(milliseconds: 16));
        expect(find.byType(Opacity), findsWidgets);

        // Halfway through the 18-second period: envelope should be at
        // 0.85 (the steady-state plateau).
        await tester.pump(const Duration(seconds: 9));
        final opacities = tester
            .widgetList<Opacity>(find.byType(Opacity))
            .map((o) => o.opacity)
            .toList();
        expect(opacities, isNotEmpty);
        // At least one Opacity wrapping the cloud should be near the
        // plateau value.
        expect(opacities.any((o) => o >= 0.7), isTrue);

        // Drain the rest of the period so the test ends without
        // pending timers.
        await tester.pump(const Duration(seconds: 10));
      },
    );
  });
}
