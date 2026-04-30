import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 1..5 discrete slider with a tap-target-friendly host height.
///
/// On Android (non-Web) physical devices, fires
/// [HapticFeedback.selectionClick] when the rounded value transitions to a
/// new integer. Web has no haptic; iOS is out of scope this sprint.
class IntensitySlider extends StatelessWidget {
  const IntensitySlider({
    super.key,
    required this.intensity,
    required this.onChanged,
  });

  final int intensity;
  final ValueChanged<int> onChanged;

  static bool get _hapticEnabled =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      slider: true,
      value: '$intensity of 5',
      child: SizedBox(
        height: MoodBloomSpacing.tapTargetMin + MoodBloomSpacing.sm,
        child: Slider(
          min: 1,
          max: 5,
          divisions: 4,
          value: intensity.toDouble(),
          label: '$intensity',
          onChanged: (raw) {
            final next = raw.round();
            if (next == intensity) return;
            if (_hapticEnabled) {
              HapticFeedback.selectionClick();
            }
            onChanged(next);
          },
        ),
      ),
    );
  }
}
