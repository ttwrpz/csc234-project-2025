import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// One flower glyph in the garden canvas. Stateless, no animation in S3 —
/// the goal is a calm, dense visual that grows as the user logs positive
/// moods. The hue is parameterized so the canvas can alternate between
/// happy (warm yellow) and calm (sage teal) blooms.
class GardenFlower extends StatelessWidget {
  const GardenFlower({super.key, required this.color, this.size = _defaultSize});

  final Color color;
  final double size;

  static const double _defaultSize = 24;

  @override
  Widget build(BuildContext context) {
    // Decorative — the screen exposes a count via Semantics on the canvas
    // itself, so each individual flower is excluded from the a11y tree to
    // keep the announcement short.
    return ExcludeSemantics(
      child: Icon(Icons.local_florist, color: color, size: size),
    );
  }

  /// Convenience: the two positive mood colors, in display order. Callers
  /// alternate between them to give the canvas a varied, hand-planted feel.
  static const List<Color> positivePalette = <Color>[
    MoodBloomColors.moodHappy,
    MoodBloomColors.moodCalm,
  ];
}
