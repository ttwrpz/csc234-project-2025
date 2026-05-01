import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// One wilting-plant glyph in the garden canvas, used for negative moods at
/// intensity 1–3 (per ADR-0006 — "compassionate reframing"). The silhouette
/// differs from [GardenFlower] by **shape**, not colour: a rotated leaf
/// cluster (`Icons.spa`) sitting on a downward-arcing stem painted by
/// [_DroopingStemPainter]. The shape difference survives the grayscale
/// accessibility golden so the two glyphs are distinguishable without
/// relying on hue (WCAG 2.2 — "do not rely on colour alone").
///
/// Stateless and decorative. The garden canvas exposes one aggregate
/// Semantics label for the whole scene so individual plants are excluded
/// from the a11y tree to keep announcements short.
class WiltingPlant extends StatelessWidget {
  const WiltingPlant({
    super.key,
    required this.intensity,
    this.size = _defaultSize,
  }) : assert(
         intensity >= 1 && intensity <= 3,
         'WiltingPlant is for negative intensity 1..3; '
         'use RainCloud for intensity 4..5.',
       );

  /// User-felt intensity of the underlying entry. Currently informational —
  /// future revisions may modulate the droop angle by intensity.
  final int intensity;
  final double size;

  static const double _defaultSize = 24;
  static const double _droopAngleRadians = -25 * math.pi / 180;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Transform.rotate(
              angle: _droopAngleRadians,
              child: Icon(
                Icons.spa,
                color: MoodBloomColors.moodSad,
                size: size,
              ),
            ),
            Positioned(
              bottom: 0,
              child: SizedBox(
                width: size,
                height: size * 0.4,
                child: CustomPaint(painter: _DroopingStemPainter()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DroopingStemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MoodBloomColors.moodSad.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.35,
        size.width * 0.6,
        size.height,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DroopingStemPainter oldDelegate) => false;
}
