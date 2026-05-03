import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// 64×64 r20 softGreen container with a 36×36 hand-drawn flora glyph.
/// Reused as the centered hero mark on the Sign In / Sign Up / Biometric
/// gate screens. Transcribed from `screens.jsx` lines 102–110.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 64, this.glyphSize = 36});

  final double size;
  final double glyphSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: MoodBloomColors.softGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: glyphSize,
        height: glyphSize,
        child: const CustomPaint(painter: _FloraGlyphPainter()),
      ),
    );
  }
}

class _FloraGlyphPainter extends CustomPainter {
  const _FloraGlyphPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 48, size.height / 48);
    final stem = Paint()
      ..color = MoodBloomColors.seed
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(24, 40), const Offset(24, 20), stem);

    final centerPaint = Paint()..color = MoodBloomColors.seed;
    canvas.drawCircle(const Offset(24, 16), 8, centerPaint);

    // Side petals — 90% opacity to match the prototype.
    canvas.drawCircle(
      const Offset(16, 20),
      5,
      Paint()..color = MoodBloomColors.amber.withAlpha(0xE6),
    );
    canvas.drawCircle(
      const Offset(32, 20),
      5,
      Paint()..color = MoodBloomColors.coral.withAlpha(0xE6),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
