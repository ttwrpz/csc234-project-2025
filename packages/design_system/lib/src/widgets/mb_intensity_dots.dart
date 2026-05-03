import 'package:flutter/material.dart';

/// Row of 5 small dots representing intensity 1–5. Filled with [color] up to
/// [value]; the rest are dimmed.
class MbIntensityDots extends StatelessWidget {
  const MbIntensityDots({
    super.key,
    required this.value,
    required this.color,
    this.max = 5,
    this.dotSize = 6,
    this.gap = 3,
  }) : assert(value >= 0, 'value must be non-negative'),
       assert(max > 0, 'max must be positive');

  final int value;
  final Color color;
  final int max;
  final double dotSize;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, max);
    return Semantics(
      label: 'Intensity $clamped of $max',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < max; i++) ...[
            if (i > 0) SizedBox(width: gap),
            Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: i < clamped ? color : Colors.black.withAlpha(0x1F),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
