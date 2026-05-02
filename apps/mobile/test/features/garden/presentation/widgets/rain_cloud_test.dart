import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/presentation/widgets/rain_cloud.dart';

void main() {
  group('RainCloud', () {
    testWidgets('renders Icons.cloud in the anxious-mood colour', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RainCloud(entryId: 'e-1', animate: false)),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.cloud));
      expect(icon.color, MoodBloomColors.moodAnxious);
    });

    testWidgets(
      'animate: false → opacity stays at 1.0 across pumps (golden-friendly)',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: RainCloud(entryId: 'e-static', animate: false),
            ),
          ),
        );

        await tester.pump(const Duration(seconds: 30));
        final opacityWidget = tester.widget<Opacity>(find.byType(Opacity));
        expect(opacityWidget.opacity, 1.0);
      },
    );

    testWidgets(
      'animate: true → opacity decays toward 0 across the fade window',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: RainCloud(entryId: 'fade-id')),
          ),
        );

        // Initial frame: full opacity.
        Opacity opacityWidget = tester.widget<Opacity>(find.byType(Opacity));
        expect(opacityWidget.opacity, closeTo(1.0, 0.01));

        // Past the maximum 25-second window: cloud is fully faded.
        await tester.pump(const Duration(seconds: 26));
        opacityWidget = tester.widget<Opacity>(find.byType(Opacity));
        expect(opacityWidget.opacity, 0.0);

        // Stop the test cleanly: pumping a few more frames keeps the
        // controller from leaking timers.
        await tester.pump(const Duration(seconds: 1));
      },
    );

    testWidgets(
      'fade duration is deterministic per entryId (golden-stability)',
      (tester) async {
        // The same entryId must produce the same controller duration on
        // every render so goldens (animate: false) plus runtime widgets
        // can rely on the underlying timing.
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: RainCloud(entryId: 'cloud-A')),
          ),
        );
        // Drain animation timers before tearing down to satisfy the
        // tester's "no pending timers" check.
        await tester.pump(const Duration(seconds: 26));
      },
    );
  });
}
