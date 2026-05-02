@Tags(['golden'])
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:moodbloom/features/garden/presentation/widgets/garden_flower.dart';

void main() {
  testGoldens('GardenFlower — happy hue', (tester) async {
    await tester.pumpWidgetBuilder(
      const Center(
        child: GardenFlower(color: MoodBloomColors.moodHappy, size: 96),
      ),
      surfaceSize: const Size(160, 160),
    );
    await screenMatchesGolden(tester, 'garden_flower_happy');
  });

  testGoldens('GardenFlower — calm hue', (tester) async {
    await tester.pumpWidgetBuilder(
      const Center(
        child: GardenFlower(color: MoodBloomColors.moodCalm, size: 96),
      ),
      surfaceSize: const Size(160, 160),
    );
    await screenMatchesGolden(tester, 'garden_flower_calm');
  });
}
