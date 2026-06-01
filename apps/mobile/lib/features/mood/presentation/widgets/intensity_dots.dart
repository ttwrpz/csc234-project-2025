import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Five circular indicators, the first `intensity` of which are filled.
/// Visual only - excluded from the semantics tree because the slider already
/// announces the value.
class IntensityDots extends StatelessWidget {
  const IntensityDots({super.key, required this.intensity});

  final int intensity;

  static const double _dotSize = 12;
  static const int _max = 5;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < _max; i++) ...[
            if (i > 0) const SizedBox(width: MoodBloomSpacing.sm),
            Container(
              width: _dotSize,
              height: _dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < intensity
                    ? MoodBloomColors.seed
                    : MoodBloomColors.outline,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
