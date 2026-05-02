@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:moodbloom/features/garden/presentation/widgets/wilting_plant.dart';

void main() {
  testGoldens('WiltingPlant — intensity 2 silhouette', (tester) async {
    await tester.pumpWidgetBuilder(
      const Center(child: WiltingPlant(intensity: 2, size: 96)),
      surfaceSize: const Size(160, 160),
    );
    await screenMatchesGolden(tester, 'wilting_plant_intensity_2');
  });

  testGoldens('WiltingPlant — grayscale silhouette is distinct from a flower '
      '(WCAG 2.2 colour-independence regression)', (tester) async {
    await tester.pumpWidgetBuilder(
      const ColorFiltered(
        colorFilter: ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0, // R
          0.2126, 0.7152, 0.0722, 0, 0, // G
          0.2126, 0.7152, 0.0722, 0, 0, // B
          0, 0, 0, 1, 0, // A
        ]),
        child: Center(child: WiltingPlant(intensity: 2, size: 96)),
      ),
      surfaceSize: const Size(160, 160),
    );
    await screenMatchesGolden(tester, 'wilting_plant_grayscale');
  });
}
