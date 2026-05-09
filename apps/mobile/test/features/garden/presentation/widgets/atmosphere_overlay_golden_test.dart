@Tags(['golden'])
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:moodbloom/features/garden/domain/entities/atmosphere.dart';
import 'package:moodbloom/features/garden/presentation/widgets/atmosphere_overlay.dart';

/// Visual goldens for the 4 daily atmosphere states. **Anchors TC-18**
/// (storm-atmosphere child stays visible underneath rain, ADR-0010 §5).
///
/// Each test wraps a stable green child (`Container 400×400`) so the
/// goldens lock the OVERLAY (gradient + drops/rays), not whatever the
/// child happens to render. The child is the proxy for "plants
/// underneath" — under `Atmosphere.storm`, that child must remain
/// recognizable: not obscured, not covered by wilt overlays, not
/// replaced by something dead-looking. Rain falls AROUND the child,
/// not on it.
///
/// `animate: false` pins the drop-fall phase to 0 so two consecutive
/// renders match. All four goldens share the same surface size
/// (800×600) so reviewers can flip through them and see only the
/// gradient + treatment difference.
void main() {
  // A stable, recognizable child. Solid green stands in for the plant
  // tier layer; we deliberately use the simpler primitive so the
  // golden is dominated by the overlay's pixels.
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

  testGoldens('AtmosphereOverlay — calmSunny', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidgetBuilder(
      wrap(
        const AtmosphereOverlay(
          atmosphere: Atmosphere.calmSunny,
          animate: false,
          child: stableChild,
        ),
      ),
      surfaceSize: const Size(800, 600),
    );
    await screenMatchesGolden(tester, 'atmosphere_overlay_calm_sunny');
  });

  testGoldens('AtmosphereOverlay — brightSunny', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidgetBuilder(
      wrap(
        const AtmosphereOverlay(
          atmosphere: Atmosphere.brightSunny,
          animate: false,
          child: stableChild,
        ),
      ),
      surfaceSize: const Size(800, 600),
    );
    await screenMatchesGolden(tester, 'atmosphere_overlay_bright_sunny');
  });

  testGoldens('AtmosphereOverlay — lightRain', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidgetBuilder(
      wrap(
        const AtmosphereOverlay(
          atmosphere: Atmosphere.lightRain,
          animate: false,
          child: stableChild,
        ),
      ),
      surfaceSize: const Size(800, 600),
    );
    await screenMatchesGolden(tester, 'atmosphere_overlay_light_rain');
  });

  testGoldens(
    'AtmosphereOverlay — storm (TC-18 anchor — child stays visible)',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidgetBuilder(
        wrap(
          const AtmosphereOverlay(
            atmosphere: Atmosphere.storm,
            animate: false,
            child: stableChild,
          ),
        ),
        surfaceSize: const Size(800, 600),
      );
      await screenMatchesGolden(tester, 'atmosphere_overlay_storm');
    },
  );
}
