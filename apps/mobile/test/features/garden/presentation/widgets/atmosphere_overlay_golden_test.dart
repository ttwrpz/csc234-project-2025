@Tags(['golden'])
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:moodbloom/features/garden/domain/entities/atmosphere.dart';
import 'package:moodbloom/features/garden/presentation/widgets/atmosphere_overlay.dart';

import '../../../../support/golden_fonts.dart';

/// Visual goldens for the 4 daily atmosphere states. Restored after
/// commit 8a72f5ad trimmed the golden suite; adapted to the current
/// `AtmosphereOverlay` API (unchanged: `atmosphere` + `child` +
/// `@visibleForTesting animate`).
///
/// Each test wraps a stable green child (`ColoredBox 400x400`) so the
/// goldens lock the OVERLAY (gradient + drops/rays), not whatever the
/// child happens to render. The child is the proxy for "plants
/// underneath" - under `Atmosphere.storm` that child must remain
/// recognizable: rain falls AROUND it, not on it (CLAUDE.md: plants are
/// never destroyed/wilting in any state).
///
/// `animate: false` pins the drop-fall phase to 0 so two consecutive
/// renders match and `pumpAndSettle` returns. All four goldens share
/// the same 800x600 surface so reviewers can flip through them and see
/// only the gradient + treatment difference.
void main() {
  installOfflineGoogleFonts();

  const stableChild = SizedBox(
    width: 400,
    height: 400,
    child: ColoredBox(color: Color(0xFF6FA587)),
  );

  Widget wrap(Widget child) => MaterialApp(
    theme: buildLightTheme(),
    debugShowCheckedModeBanner: false,
    home: Scaffold(body: Center(child: child)),
  );

  Future<void> pumpAtmosphere(
    WidgetTester tester,
    Atmosphere atmosphere,
    String goldenName,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidgetBuilder(
      wrap(
        AtmosphereOverlay(
          atmosphere: atmosphere,
          animate: false,
          child: stableChild,
        ),
      ),
      surfaceSize: const Size(800, 600),
    );
    await screenMatchesGolden(tester, goldenName);
  }

  testGoldens('AtmosphereOverlay - calmSunny', (tester) async {
    await pumpAtmosphere(
      tester,
      Atmosphere.calmSunny,
      'atmosphere_overlay_calm_sunny',
    );
  });

  testGoldens('AtmosphereOverlay - brightSunny', (tester) async {
    await pumpAtmosphere(
      tester,
      Atmosphere.brightSunny,
      'atmosphere_overlay_bright_sunny',
    );
  });

  testGoldens('AtmosphereOverlay - lightRain', (tester) async {
    await pumpAtmosphere(
      tester,
      Atmosphere.lightRain,
      'atmosphere_overlay_light_rain',
    );
  });

  testGoldens(
    'AtmosphereOverlay - storm (child stays visible underneath rain)',
    (tester) async {
      await pumpAtmosphere(
        tester,
        Atmosphere.storm,
        'atmosphere_overlay_storm',
      );
    },
  );
}
