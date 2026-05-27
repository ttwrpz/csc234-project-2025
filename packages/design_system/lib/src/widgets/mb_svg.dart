import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/colors.dart';

/// SVG widget set ported from the Claude Design handoff bundle's
/// `prototype/svgs.jsx` to Flutter CustomPainters.
///
/// Each painter renders a tiny stylized glyph (mood icon, brand mark,
/// sun glyph, token gem) using pure `Canvas` ops. The shapes are
/// resolution-independent and pick up colors via the `color` parameter
/// (mood icons should be tinted by the parent surface).
///
/// All glyphs use a 24x24 logical viewBox (sun glyph uses 100x100) and
/// the painter scales the canvas to whatever `size` the caller wants.

// ---------------------------------------------------------------------------
// Brand mark - 5-petal stylized bloom
// ---------------------------------------------------------------------------

/// 5-petal stylized bloom used in the app brand, onboarding header,
/// toast brand chip, and auth screens.
class MbBrandSvg extends StatelessWidget {
  const MbBrandSvg({super.key, this.size = 24, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? MoodBloomColors.seed;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _BrandPainter(tint)),
    );
  }
}

class _BrandPainter extends CustomPainter {
  const _BrandPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // 24x24 viewBox; scale to size.
    final s = size.width / 24.0;
    canvas.scale(s);

    final petal = Paint()..color = color.withValues(alpha: 0.95);
    // 5 petals: ellipse (cx=12, cy=6, rx=3, ry=4.5) rotated 72deg around
    // center (12,12). Drawn via rotate-around-center.
    for (var i = 0; i < 5; i++) {
      canvas.save();
      canvas.translate(12, 12);
      canvas.rotate(i * 72 * math.pi / 180.0);
      canvas.translate(-12, -12);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(12, 6), width: 6, height: 9),
        petal,
      );
      canvas.restore();
    }

    // Inner disc + small core dot (cream + tinted)
    canvas.drawCircle(
      const Offset(12, 12),
      2.4,
      Paint()..color = MoodBloomColors.surfaceCream,
    );
    canvas.drawCircle(
      const Offset(12, 12),
      1.2,
      Paint()..color = color.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(_BrandPainter old) => old.color != color;
}

// ---------------------------------------------------------------------------
// Mood icons - one per MbMoodKind. All use `currentColor`-equivalent
// (tinted by the parent or the explicit `color` param).
// ---------------------------------------------------------------------------

/// Dispatches to the correct mood painter based on the [mood] enum.
class MbMoodSvg extends StatelessWidget {
  const MbMoodSvg({super.key, required this.mood, this.size = 24, this.color});

  final MbMoodKind mood;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint =
        color ?? DefaultTextStyle.of(context).style.color ?? Colors.black;
    final painter = switch (mood) {
      MbMoodKind.happy => _HappyPainter(tint),
      MbMoodKind.calm => _CalmPainter(tint),
      MbMoodKind.okay => _OkayPainter(tint),
      MbMoodKind.sad => _SadPainter(tint),
      MbMoodKind.angry => _AngryPainter(tint),
      MbMoodKind.anxious => _AnxiousPainter(tint),
    };
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: painter),
    );
  }
}

abstract class _MoodPainterBase extends CustomPainter {
  const _MoodPainterBase(this.color);
  final Color color;

  @override
  bool shouldRepaint(covariant _MoodPainterBase old) => old.color != color;
}

/// Happy - sun bloom: 8 petals around a disc.
class _HappyPainter extends _MoodPainterBase {
  const _HappyPainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;
    canvas.scale(s);
    final petal = Paint()..color = color.withValues(alpha: 0.85);

    // 8 petals: ellipse (cx=12, cy=4.5, rx=1.6, ry=3) rotated 45deg.
    for (var i = 0; i < 8; i++) {
      canvas.save();
      canvas.translate(12, 12);
      canvas.rotate(i * 45 * math.pi / 180.0);
      canvas.translate(-12, -12);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(12, 4.5), width: 3.2, height: 6),
        petal,
      );
      canvas.restore();
    }
    // Center disc r=3.4 (solid color).
    canvas.drawCircle(const Offset(12, 12), 3.4, Paint()..color = color);
  }
}

/// Calm - sprout with stem + two leaves.
class _CalmPainter extends _MoodPainterBase {
  const _CalmPainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;
    canvas.scale(s);

    // Stem: M 12 21 L 12 12 stroked.
    final stem = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(12, 21), const Offset(12, 12), stem);

    // Left leaf: M 12 13 Q 5 11 5 5 Q 11 6 12 13 Z (filled).
    final leafL = Path()
      ..moveTo(12, 13)
      ..quadraticBezierTo(5, 11, 5, 5)
      ..quadraticBezierTo(11, 6, 12, 13)
      ..close();
    canvas.drawPath(leafL, Paint()..color = color);

    // Right leaf: M 12 13 Q 19 11 19 5 Q 13 6 12 13 Z opacity 0.78.
    final leafR = Path()
      ..moveTo(12, 13)
      ..quadraticBezierTo(19, 11, 19, 5)
      ..quadraticBezierTo(13, 6, 12, 13)
      ..close();
    canvas.drawPath(leafR, Paint()..color = color.withValues(alpha: 0.78));
  }
}

/// Okay - single rounded leaf with subtle centerline.
class _OkayPainter extends _MoodPainterBase {
  const _OkayPainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;
    canvas.scale(s);

    // M 12 3 Q 3 8 6 16 Q 9 21 12 21 Q 15 21 18 16 Q 21 8 12 3 Z
    final leaf = Path()
      ..moveTo(12, 3)
      ..quadraticBezierTo(3, 8, 6, 16)
      ..quadraticBezierTo(9, 21, 12, 21)
      ..quadraticBezierTo(15, 21, 18, 16)
      ..quadraticBezierTo(21, 8, 12, 3)
      ..close();
    canvas.drawPath(leaf, Paint()..color = color);

    // Centerline M 12 6 L 12 19 stroked with cream @ 0.5.
    canvas.drawLine(
      const Offset(12, 6),
      const Offset(12, 19),
      Paint()
        ..color = MoodBloomColors.surfaceCream.withValues(alpha: 0.5)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }
}

/// Sad - teardrop with subtle highlight.
class _SadPainter extends _MoodPainterBase {
  const _SadPainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;
    canvas.scale(s);

    // M 12 3 Q 5 13 7 18 Q 9 22 12 22 Q 15 22 17 18 Q 19 13 12 3 Z
    final tear = Path()
      ..moveTo(12, 3)
      ..quadraticBezierTo(5, 13, 7, 18)
      ..quadraticBezierTo(9, 22, 12, 22)
      ..quadraticBezierTo(15, 22, 17, 18)
      ..quadraticBezierTo(19, 13, 12, 3)
      ..close();
    canvas.drawPath(tear, Paint()..color = color);

    // Highlight ellipse cx=10 cy=14 rx=1.8 ry=3, cream @ 0.35.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(10, 14), width: 3.6, height: 6),
      Paint()..color = MoodBloomColors.surfaceCream.withValues(alpha: 0.35),
    );
  }
}

/// Angry - storm cloud + lightning bolt.
class _AngryPainter extends _MoodPainterBase {
  const _AngryPainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;
    canvas.scale(s);

    // Cloud body: M 6 13 Q 3 13 3 10 Q 3 7 6 7 Q 7 4 11 5 Q 14 4 16 7
    //             Q 21 7 21 11 Q 21 14 17 14 L 7 14 Q 6 14 6 13 Z
    final cloud = Path()
      ..moveTo(6, 13)
      ..quadraticBezierTo(3, 13, 3, 10)
      ..quadraticBezierTo(3, 7, 6, 7)
      ..quadraticBezierTo(7, 4, 11, 5)
      ..quadraticBezierTo(14, 4, 16, 7)
      ..quadraticBezierTo(21, 7, 21, 11)
      ..quadraticBezierTo(21, 14, 17, 14)
      ..lineTo(7, 14)
      ..quadraticBezierTo(6, 14, 6, 13)
      ..close();
    canvas.drawPath(cloud, Paint()..color = color);

    // Lightning bolt: M 11 13 L 8 19 L 11 19 L 9 23 L 15 16 L 12 16 L 14 13 Z
    final bolt = Path()
      ..moveTo(11, 13)
      ..lineTo(8, 19)
      ..lineTo(11, 19)
      ..lineTo(9, 23)
      ..lineTo(15, 16)
      ..lineTo(12, 16)
      ..lineTo(14, 13)
      ..close();
    canvas.drawPath(bolt, Paint()..color = color.withValues(alpha: 0.7));
  }
}

/// Anxious - wheat stalk with three grain pairs.
class _AnxiousPainter extends _MoodPainterBase {
  const _AnxiousPainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;
    canvas.scale(s);

    // Stem: M 12 22 L 12 6 stroked.
    canvas.drawLine(
      const Offset(12, 22),
      const Offset(12, 6),
      Paint()
        ..color = color
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // 3 grain pairs: ellipse (cx=9, cy=9, rx=1.6, ry=2.4) rotated -25,
    // and (cx=15, cy=9, rx=1.6, ry=2.4) rotated +25, with each pair
    // translated +4 in y.
    for (var i = 0; i < 3; i++) {
      final dy = i * 4.0;
      _drawRotatedOval(canvas, Offset(9, 9 + dy), 1.6, 2.4, -25, color);
      _drawRotatedOval(canvas, Offset(15, 9 + dy), 1.6, 2.4, 25, color);
    }

    // Top tendril: M 12 6 Q 12 3 14 2 stroked.
    final tip = Path()
      ..moveTo(12, 6)
      ..quadraticBezierTo(12, 3, 14, 2);
    canvas.drawPath(
      tip,
      Paint()
        ..color = color
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawRotatedOval(
    Canvas canvas,
    Offset center,
    double rx,
    double ry,
    double angleDeg,
    Color color,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angleDeg * math.pi / 180.0);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rx * 2, height: ry * 2),
      Paint()..color = color,
    );
    canvas.restore();
  }
}

// ---------------------------------------------------------------------------
// Sun glyph - radial gradient circle for SkyHeader.
// ---------------------------------------------------------------------------

class MbSunGlyphSvg extends StatelessWidget {
  const MbSunGlyphSvg({super.key, this.size = 80, this.sun1, this.sun2});

  final double size;
  final Color? sun1;
  final Color? sun2;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>();
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SunPainter(
          sun1 ?? mb?.sun1 ?? MoodBloomColors.amber,
          sun2 ?? mb?.sun2 ?? MoodBloomColors.amber,
        ),
      ),
    );
  }
}

class _SunPainter extends CustomPainter {
  const _SunPainter(this.sun1, this.sun2);

  final Color sun1;
  final Color sun2;

  @override
  void paint(Canvas canvas, Size size) {
    // 100x100 viewBox, radial gradient cx=35% cy=35%, circle cx=50,
    // cy=50, r=48.
    final s = size.width / 100.0;
    canvas.scale(s);
    final rect = const Rect.fromLTWH(0, 0, 100, 100);
    final gradient = RadialGradient(
      center: const Alignment(-0.3, -0.3), // 35%, 35%
      radius: 0.7,
      colors: [sun1, sun2, sun2.withValues(alpha: 0)],
      stops: const [0.0, 0.65, 1.0],
    );
    canvas.drawCircle(
      const Offset(50, 50),
      48,
      Paint()..shader = gradient.createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_SunPainter old) => old.sun1 != sun1 || old.sun2 != sun2;
}

// ---------------------------------------------------------------------------
// Token gem - small gem icon for the token balance pill.
// ---------------------------------------------------------------------------

class MbTokenGlyphSvg extends StatelessWidget {
  const MbTokenGlyphSvg({super.key, this.size = 16, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint =
        color ?? DefaultTextStyle.of(context).style.color ?? Colors.black;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _TokenPainter(tint)),
    );
  }
}

class _TokenPainter extends CustomPainter {
  const _TokenPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;
    canvas.scale(s);

    // Outer gem outline: M 12 3 L 20 9 L 17 19 L 7 19 L 4 9 Z (stroked).
    final outer = Path()
      ..moveTo(12, 3)
      ..lineTo(20, 9)
      ..lineTo(17, 19)
      ..lineTo(7, 19)
      ..lineTo(4, 9)
      ..close();
    canvas.drawPath(
      outer,
      Paint()
        ..color = color
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    // Inner facet: M 9 9 L 15 9 L 12 19 Z (filled, opacity 0.4).
    final inner = Path()
      ..moveTo(9, 9)
      ..lineTo(15, 9)
      ..lineTo(12, 19)
      ..close();
    canvas.drawPath(inner, Paint()..color = color.withValues(alpha: 0.4));
  }

  @override
  bool shouldRepaint(_TokenPainter old) => old.color != color;
}
