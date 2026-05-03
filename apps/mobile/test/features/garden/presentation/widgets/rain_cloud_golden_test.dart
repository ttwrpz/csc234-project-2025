@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:moodbloom/features/garden/presentation/widgets/rain_cloud.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

void main() {
  testGoldens('RainCloud — static silhouette (animate:false for determinism)', (
    tester,
  ) async {
    await tester.pumpWidgetBuilder(
      const Center(
        child: SizedBox(
          width: 120,
          height: 120,
          child: RainCloud(
            entryId: 'golden-id',
            mood: MoodType.anxious,
            intensity: 4,
            size: 120,
            animate: false,
          ),
        ),
      ),
      surfaceSize: const Size(160, 160),
    );
    await screenMatchesGolden(tester, 'rain_cloud_static');
  });
}
