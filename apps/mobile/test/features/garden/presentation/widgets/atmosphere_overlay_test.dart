import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/domain/entities/atmosphere.dart';
import 'package:moodbloom/features/garden/presentation/widgets/atmosphere_overlay.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('AtmosphereOverlay - smoke (one per state)', () {
    Future<void> pump(WidgetTester tester, Atmosphere a) async {
      await pumpApp(
        tester,
        child: Scaffold(
          body: SizedBox(
            width: 320,
            height: 100,
            child: AtmosphereOverlay(
              atmosphere: a,
              animate: false,
              child: const ColoredBox(color: Color(0xFFE8F3ED)),
            ),
          ),
        ),
      );
      // Single pump - animate:false means no controller is running.
      await tester.pump();
    }

    testWidgets('calmSunny renders the wrapped child + overlay', (
      tester,
    ) async {
      await pump(tester, Atmosphere.calmSunny);
      expect(find.byType(AtmosphereOverlay), findsOneWidget);
      expect(find.byType(IgnorePointer), findsWidgets);
    });

    testWidgets('brightSunny renders without throwing', (tester) async {
      await pump(tester, Atmosphere.brightSunny);
      expect(find.byType(AtmosphereOverlay), findsOneWidget);
    });

    testWidgets('lightRain renders without throwing', (tester) async {
      await pump(tester, Atmosphere.lightRain);
      expect(find.byType(AtmosphereOverlay), findsOneWidget);
    });

    testWidgets('storm renders without throwing', (tester) async {
      await pump(tester, Atmosphere.storm);
      expect(find.byType(AtmosphereOverlay), findsOneWidget);
    });
  });
}
