import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// One slide's art in the v1.6 onboarding deck. The widget renders into a
/// 260×200 logical canvas (the prototype's `ArtFrame` size) and scales
/// uniformly to whatever box the slide gives it.
///
/// All paths are ported verbatim from
/// `.tmp-handoff/.../prototype/onboarding.jsx`. Colours pick up from the
/// active [MbColors] theme extension so the art recolours cleanly between
/// light and dark mode.
enum OnboardingArtKind {
  /// Slide 0 - single brand bloom rising from soft ground, sun in
  /// upper-right, two distant hill bands.
  welcome,

  /// Slide 1 - six mood cards (3×2 grid) with the "happy" cell
  /// selected, plus a 1–5 intensity slider mock-up at the bottom.
  logMoods,

  /// Slide 2 - a row of five small plants in mixed moods rising from
  /// the ground band, sun + drifting cloud in the sky.
  gardenGrowth,

  /// Slide 3 - bell glyph inside a soft-green disc with a coral badge,
  /// three sound-wave arcs to either side, scattered sparkles.
  notifications,

  /// Slide 4 - coral-stroked shield with a soft-green inner face and
  /// the brand seed heart at its centre. Compassionate, not clinical.
  disclaimer,
}

/// Onboarding art widget. Renders the 260×200 painter for [kind] inside
/// a [RepaintBoundary] so it does not invalidate on parent rebuilds.
class OnboardingArt extends StatelessWidget {
  const OnboardingArt({
    super.key,
    required this.kind,
    this.width = 260,
    this.height = 200,
  });

  final OnboardingArtKind kind;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final painter = switch (kind) {
      OnboardingArtKind.welcome => _WelcomeArtPainter(mb: mb),
      OnboardingArtKind.logMoods => _LogMoodsArtPainter(mb: mb),
      OnboardingArtKind.gardenGrowth => _GardenGrowthArtPainter(mb: mb),
      OnboardingArtKind.notifications => _NotificationsArtPainter(mb: mb),
      OnboardingArtKind.disclaimer => _DisclaimerArtPainter(mb: mb),
    };
    return RepaintBoundary(
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(painter: painter, child: const SizedBox.expand()),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared painter scaffolding
// ---------------------------------------------------------------------------

/// Base painter - handles the sky-gradient rounded backdrop that every
/// slide shares (`ArtFrame` in the prototype). Concrete painters override
/// [paintContent] to layer their slide-specific shapes on top of it.
abstract class _OnboardingArtPainter extends CustomPainter {
  const _OnboardingArtPainter({required this.mb});

  /// Active surface palette - supplies sky gradient stops, ground band
  /// colors, sun tones, and the dimmer "line" stroke used by frames.
  final MbColors mb;

  static const double _vbW = 260;
  static const double _vbH = 200;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _vbW, size.height / _vbH);
    _paintBackground(canvas);
    paintContent(canvas);
    canvas.restore();
  }

  /// Slide-specific shapes drawn over the [ _paintBackground ] gradient.
  /// Coordinates are expressed in the 260×200 viewBox.
  void paintContent(Canvas canvas);

  void _paintBackground(Canvas canvas) {
    final bgRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, _vbW, _vbH),
      const Radius.circular(24),
    );
    canvas.drawRRect(
      bgRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [mb.skyTop, mb.skyMid, mb.skyBot],
          stops: const [0, 0.55, 1],
        ).createShader(const Rect.fromLTWH(0, 0, _vbW, _vbH)),
    );
  }

  @override
  bool shouldRepaint(covariant _OnboardingArtPainter oldDelegate) =>
      oldDelegate.mb != mb;
}

// ---------------------------------------------------------------------------
// Slide 0 - Welcome (sun + two hill bands + central brand bloom)
// ---------------------------------------------------------------------------

class _WelcomeArtPainter extends _OnboardingArtPainter {
  const _WelcomeArtPainter({required super.mb});

  @override
  void paintContent(Canvas canvas) {
    const w = _OnboardingArtPainter._vbW;
    const h = _OnboardingArtPainter._vbH;

    // Sun - soft halo + solid core in the upper-right quadrant.
    final sunCenter = Offset(w * 0.78, h * 0.28);
    canvas.drawCircle(
      sunCenter,
      42,
      Paint()..color = mb.sun2.withValues(alpha: 0.65),
    );
    canvas.drawCircle(sunCenter, 18, Paint()..color = mb.sun1);

    // Distant hill band - softer tone, behind the foreground band.
    final hill = Path()
      ..moveTo(0, h * 0.72)
      ..quadraticBezierTo(w * 0.3, h * 0.62, w * 0.6, h * 0.7)
      ..quadraticBezierTo(w * 0.8, h * 0.74, w, h * 0.68)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hill, Paint()..color = mb.ground.withValues(alpha: 0.5));

    // Foreground ground band - full-opacity ground tone.
    final ground = Path()
      ..moveTo(0, h * 0.82)
      ..quadraticBezierTo(w * 0.4, h * 0.76, w, h * 0.8)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(ground, Paint()..color = mb.ground2);

    // Central brand bloom - rises from the ground band.
    canvas.save();
    canvas.translate(w / 2, h * 0.55);

    // Stem.
    canvas.drawLine(
      const Offset(0, 0),
      Offset(0, h * 0.32),
      Paint()
        ..color = mb.grass
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Two leaves on the stem (left tilted -25°, right tilted +25°).
    _drawRotatedOval(
      canvas,
      Offset(-12, h * 0.18),
      14,
      6,
      -25,
      Paint()..color = mb.grass,
    );
    _drawRotatedOval(
      canvas,
      Offset(12, h * 0.12),
      14,
      6,
      25,
      Paint()..color = mb.grass,
    );

    // Five-petal corolla. Petals point up; each petal rotated 72° from
    // the previous one around the bloom's centre.
    final petal = Paint()
      ..color = const Color(0xFFF4A78C).withValues(alpha: 0.95);
    for (var i = 0; i < 5; i++) {
      canvas.save();
      canvas.rotate(i * 72 * math.pi / 180);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, -22), width: 14, height: 26),
        petal,
      );
      canvas.restore();
    }
    canvas.drawCircle(
      Offset.zero,
      7,
      Paint()..color = MoodBloomColors.seedDark,
    );
    canvas.restore();
  }
}

void _drawRotatedOval(
  Canvas canvas,
  Offset center,
  double rx,
  double ry,
  double angleDeg,
  Paint paint,
) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(angleDeg * math.pi / 180);
  canvas.drawOval(
    Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
    paint,
  );
  canvas.restore();
}

// ---------------------------------------------------------------------------
// Slide 1 - Log moods (3×2 mood grid + 5-step intensity slider mock-up)
// ---------------------------------------------------------------------------

class _LogMoodsArtPainter extends _OnboardingArtPainter {
  const _LogMoodsArtPainter({required super.mb});

  @override
  void paintContent(Canvas canvas) {
    const w = _OnboardingArtPainter._vbW;
    const h = _OnboardingArtPainter._vbH;

    // 3×2 grid of mood cells. First cell ("happy") is the selected
    // state - tinted background + matching coloured border.
    const cellW = 60.0;
    const cellH = 50.0;
    const gap = 8.0;
    const gridW = cellW * 3 + gap * 2;
    final gx = (w - gridW) / 2;
    final gy = h * 0.18;

    final moods = <_MoodCell>[
      _MoodCell(MbMoodKind.happy, MoodBloomColors.moodHappy),
      _MoodCell(MbMoodKind.calm, MoodBloomColors.moodCalm),
      _MoodCell(MbMoodKind.okay, MoodBloomColors.moodOkay),
      _MoodCell(MbMoodKind.sad, MoodBloomColors.moodSad),
      _MoodCell(MbMoodKind.angry, MoodBloomColors.moodAngry),
      _MoodCell(MbMoodKind.anxious, MoodBloomColors.moodAnxious),
    ];

    for (var i = 0; i < moods.length; i++) {
      final m = moods[i];
      final col = i % 3;
      final row = i ~/ 3;
      final x = gx + col * (cellW + gap);
      final y = gy + row * (cellH + gap);
      final selected = i == 0;

      // Background - tinted swatch for the selected cell, plain card
      // tone for the rest.
      final cellRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, cellW, cellH),
        const Radius.circular(12),
      );
      canvas.drawRRect(
        cellRect,
        Paint()
          ..color = selected ? Color.lerp(mb.card, m.color, 0.22)! : mb.card,
      );
      canvas.drawRRect(
        cellRect,
        Paint()
          ..color = selected ? m.color : mb.line
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 1.5 : 1,
      );

      // Per-mood SVG-port glyph centred in the cell. Mirrors the
      // prototype's `MoodGlyph` component - each mood gets its own
      // shape so the grid reads as "six distinct moods" instead of
      // "six colour swatches". Drawn slightly above the cell centre
      // (the prototype offsets by -4dp) so the eye reads the glyph as
      // the cell's payload.
      canvas.save();
      canvas.translate(x + cellW / 2, y + cellH / 2 - 4);
      _drawMoodGlyph(canvas, m.kind, m.color);
      canvas.restore();
    }

    // Intensity slider mock-up - 132-wide rail centred under the grid,
    // filled to the third tick (3/5). Thumb sits at the same position
    // and uses the happy mood colour to match the selected cell.
    final railY = gy + cellH * 2 + gap + 22;
    final cx = w / 2;
    final railRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - 66, railY - 2, 132, 4),
      const Radius.circular(2),
    );
    canvas.drawRRect(railRect, Paint()..color = mb.line);
    final fillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - 66, railY - 2, 66, 4),
      const Radius.circular(2),
    );
    canvas.drawRRect(fillRect, Paint()..color = MoodBloomColors.moodHappy);

    // 5 tick dots - filled white-ish for the first three (within the
    // filled portion), dim grey for the last two.
    for (var i = 0; i < 5; i++) {
      final tx = cx - 66 + (i * 33.0);
      canvas.drawCircle(
        Offset(tx, railY),
        1.6,
        Paint()
          ..color = i <= 2
              ? Colors.white.withValues(alpha: 0.95)
              : mb.textDim.withValues(alpha: 0.5),
      );
    }

    // Thumb (3/5).
    canvas.drawCircle(Offset(cx, railY), 8, Paint()..color = mb.card);
    canvas.drawCircle(
      Offset(cx, railY),
      8,
      Paint()
        ..color = MoodBloomColors.moodHappy
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }
}

class _MoodCell {
  const _MoodCell(this.kind, this.color);
  final MbMoodKind kind;
  final Color color;
}

/// Tiny per-mood glyph painted at the centre of an onboarding mood
/// cell. Ports the prototype's `MoodGlyph` component (size 18 in viewBox
/// units) to Flutter `Canvas` ops:
///
///   * happy   - 8 small petals around a central disk
///   * calm    - vertical stem with two paired leaves
///   * okay    - single rounded teardrop
///   * sad     - drooping teardrop
///   * angry   - jagged stylised crown with a lightning bolt
///   * anxious - vertical stem with 3 pairs of grain ellipses
///
/// All shapes paint in [color] so the glyph picks up the mood swatch
/// without an extra blend step. The painter assumes the caller has
/// already translated the canvas to the glyph's centre.
void _drawMoodGlyph(Canvas canvas, MbMoodKind kind, Color color) {
  const size = 18.0;
  final paint = Paint()..color = color;
  switch (kind) {
    case MbMoodKind.happy:
      // 8 petals around a central disk (size 0.07 × 0.18 ovals
      // rotated 0/45/90/.../315 degrees, plus a 0.15-radius core).
      final petalPaint = Paint()..color = color.withValues(alpha: 0.9);
      for (var i = 0; i < 8; i++) {
        canvas.save();
        canvas.rotate(i * math.pi / 4);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(0, -size * 0.4),
            width: size * 0.14,
            height: size * 0.36,
          ),
          petalPaint,
        );
        canvas.restore();
      }
      canvas.drawCircle(Offset.zero, size * 0.15, paint);
    case MbMoodKind.calm:
      // Vertical stem + two paired leaves (one fainter for depth).
      canvas.drawLine(
        const Offset(0, 9),
        const Offset(0, 0),
        Paint()
          ..color = color
          ..strokeWidth = 1.4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      final leftLeaf = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-7, -3, -7, -8)
        ..quadraticBezierTo(-1, -7, 0, 0)
        ..close();
      canvas.drawPath(leftLeaf, paint);
      final rightLeaf = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(7, -3, 7, -8)
        ..quadraticBezierTo(1, -7, 0, 0)
        ..close();
      canvas.drawPath(
        rightLeaf,
        Paint()..color = color.withValues(alpha: 0.78),
      );
    case MbMoodKind.okay:
      // Single rounded teardrop.
      final teardrop = Path()
        ..moveTo(0, -9)
        ..quadraticBezierTo(-8, -4, -5, 5)
        ..quadraticBezierTo(-2, 9, 0, 9)
        ..quadraticBezierTo(2, 9, 5, 5)
        ..quadraticBezierTo(8, -4, 0, -9)
        ..close();
      canvas.drawPath(teardrop, paint);
    case MbMoodKind.sad:
      // Drooping teardrop (slightly narrower than okay, longer tail).
      final droop = Path()
        ..moveTo(0, -9)
        ..quadraticBezierTo(-6, 0, -4, 6)
        ..quadraticBezierTo(-2, 10, 0, 10)
        ..quadraticBezierTo(2, 10, 4, 6)
        ..quadraticBezierTo(6, 0, 0, -9)
        ..close();
      canvas.drawPath(droop, paint);
    case MbMoodKind.angry:
      // Stylised cloud-like crown + a lightning bolt drop. The crown
      // outline matches the prototype's `M -6 1 Q -9 1 ...` SVG path.
      final crown = Path()
        ..moveTo(-6, 1)
        ..quadraticBezierTo(-9, 1, -9, -2)
        ..quadraticBezierTo(-9, -5, -6, -5)
        ..quadraticBezierTo(-5, -8, -1, -7)
        ..quadraticBezierTo(2, -8, 4, -5)
        ..quadraticBezierTo(9, -5, 9, -1)
        ..quadraticBezierTo(9, 2, 5, 2)
        ..lineTo(-5, 2)
        ..close();
      canvas.drawPath(crown, paint);
      // Small lightning bolt below the crown.
      final bolt = Path()
        ..moveTo(-1, 1)
        ..lineTo(-4, 7)
        ..lineTo(-1, 7)
        ..lineTo(-3, 11)
        ..lineTo(3, 4)
        ..lineTo(0, 4)
        ..lineTo(2, 1)
        ..close();
      canvas.drawPath(bolt, Paint()..color = color.withValues(alpha: 0.65));
    case MbMoodKind.anxious:
      // Vertical stem + 3 stacked pairs of grain ellipses leaning
      // outward (mirrors the prototype's wheat-head glyph).
      canvas.drawLine(
        const Offset(0, 10),
        const Offset(0, -6),
        Paint()
          ..color = color
          ..strokeWidth = 1.4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      for (var i = 0; i < 3; i++) {
        final dy = i * 4.0;
        final yShift = -2 + dy * -0.5;
        _drawRotatedOval(canvas, Offset(-3, yShift), 1.6, 2.6, -25, paint);
        _drawRotatedOval(canvas, Offset(3, yShift), 1.6, 2.6, 25, paint);
      }
  }
}

// ---------------------------------------------------------------------------
// Slide 2 - Garden growth (5 small plants of mixed moods on a hill band)
// ---------------------------------------------------------------------------

class _GardenGrowthArtPainter extends _OnboardingArtPainter {
  const _GardenGrowthArtPainter({required super.mb});

  @override
  void paintContent(Canvas canvas) {
    const w = _OnboardingArtPainter._vbW;
    const h = _OnboardingArtPainter._vbH;

    // Sun in upper-right.
    canvas.drawCircle(
      Offset(w * 0.82, h * 0.25),
      32,
      Paint()..color = mb.sun2.withValues(alpha: 0.5),
    );

    // Small cloud upper-left.
    final cloud = Paint()..color = Colors.white.withValues(alpha: 0.55);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.22, h * 0.22),
        width: 44,
        height: 14,
      ),
      cloud,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.32, h * 0.18),
        width: 26,
        height: 12,
      ),
      cloud,
    );

    // Distant hill curve.
    final hill = Path()
      ..moveTo(0, h * 0.7)
      ..quadraticBezierTo(w * 0.4, h * 0.6, w, h * 0.66)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hill, Paint()..color = mb.ground.withValues(alpha: 0.6));

    // Foreground ground band.
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.82, w, h * 0.18),
      Paint()..color = mb.ground2,
    );

    // 5 plants - mixed moods rising from the foreground ground band.
    // Ports the prototype's `<window.Plant>` shapes (the same geometry
    // as the SkyHeader plot strip's mini-plants) so the onboarding
    // garden reads identically to the live home garden the user is
    // about to grow.
    const plantMoods = <MbMoodKind>[
      MbMoodKind.happy,
      MbMoodKind.calm,
      MbMoodKind.okay,
      MbMoodKind.happy,
      MbMoodKind.calm,
    ];
    final colors = <MbMoodKind, Color>{
      MbMoodKind.happy: MoodBloomColors.moodHappy,
      MbMoodKind.calm: MoodBloomColors.moodCalm,
      MbMoodKind.okay: MoodBloomColors.moodOkay,
    };
    final baseY = h * 0.82;
    const plantW = 28.0;
    for (var i = 0; i < plantMoods.length; i++) {
      final x = (w / (plantMoods.length + 1)) * (i + 1);
      final plantH = 60.0 + i * 4.0;
      final colour = colors[plantMoods[i]] ?? MoodBloomColors.moodOkay;
      canvas.save();
      canvas.translate(x - plantW / 2, baseY - plantH);
      _drawOnboardingPlant(
        canvas,
        plantMoods[i],
        colour,
        mb.grass,
        plantW,
        plantH,
      );
      canvas.restore();
    }
  }
}

/// Per-mood plant painter for the Garden Growth onboarding slide.
/// Ports the prototype's `Plant` SVG shapes (same geometry as the
/// SkyHeader plot strip) so the onboarding garden reads identically to
/// the live garden the user is about to start growing. The painter
/// only implements the moods this slide uses (happy / calm / okay) -
/// add other moods if the slide composition changes.
void _drawOnboardingPlant(
  Canvas canvas,
  MbMoodKind mood,
  Color color,
  Color grass,
  double w,
  double h,
) {
  final cx = w / 2;
  final stemBot = h;
  final stemTop = h * 0.28;

  // Stem.
  final stemPaint = Paint()
    ..color = grass
    ..strokeWidth = 1.6
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final stemPath = Path();
  switch (mood) {
    case MbMoodKind.happy:
      stemPath
        ..moveTo(cx, stemBot)
        ..quadraticBezierTo(cx - 1.2, (stemBot + stemTop) / 2, cx, stemTop + 2);
    case MbMoodKind.calm:
      stemPath
        ..moveTo(cx, stemBot)
        ..lineTo(cx, stemTop);
    case MbMoodKind.okay:
      stemPath
        ..moveTo(cx, stemBot)
        ..lineTo(cx, stemTop + h * 0.18);
    case _:
      stemPath
        ..moveTo(cx, stemBot)
        ..lineTo(cx, stemTop);
  }
  canvas.drawPath(stemPath, stemPaint);

  switch (mood) {
    case MbMoodKind.happy:
      // Sunflower head: 10 petals + brown disk + small accent dot.
      // Two leaves on either side of the stem.
      _drawRotatedOval(
        canvas,
        Offset(cx - 7, h * 0.68),
        5,
        2.4,
        -30,
        Paint()..color = grass,
      );
      _drawRotatedOval(
        canvas,
        Offset(cx + 7, h * 0.52),
        5,
        2.4,
        30,
        Paint()..color = grass,
      );
      canvas.save();
      canvas.translate(cx, stemTop - 2);
      final petal = Paint()..color = color;
      for (var i = 0; i < 10; i++) {
        canvas.save();
        canvas.rotate(i * (2 * math.pi / 10));
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(0, -6), width: 4, height: 9),
          petal,
        );
        canvas.restore();
      }
      final disk = HSLColor.fromColor(color).withLightness(0.30).toColor();
      canvas.drawCircle(Offset.zero, 4, Paint()..color = disk);
      canvas.drawCircle(
        const Offset(-1, -1),
        1.2,
        Paint()..color = color.withValues(alpha: 0.8),
      );
      canvas.restore();
    case MbMoodKind.calm:
      // Paired leaves at three heights + bud at apex.
      final leafPaint = Paint()..color = grass.withValues(alpha: 0.92);
      for (final y in const <double>[0.72, 0.55, 0.4]) {
        _drawRotatedOval(canvas, Offset(cx - 5, h * y), 4.5, 2, -32, leafPaint);
        _drawRotatedOval(canvas, Offset(cx + 5, h * y), 4.5, 2, 32, leafPaint);
      }
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, stemTop - 1), width: 6, height: 10),
        Paint()..color = color,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, stemTop - 1), width: 3, height: 7),
        Paint()..color = grass.withValues(alpha: 0.45),
      );
    case MbMoodKind.okay:
      // Tuft of 6 grass blades from the ground line (no flower head).
      const blades = <double>[-10, -6, -2, 2, 6, 10];
      for (var i = 0; i < blades.length; i++) {
        final dx = blades[i];
        final blade = h * (0.4 + (i % 3) * 0.06);
        final sway = (i % 2 == 0) ? -3.0 : 3.0;
        final paint = Paint()
          ..color = (i % 2 == 0 ? grass : color).withValues(alpha: 0.85)
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawPath(
          Path()
            ..moveTo(cx + dx, stemBot)
            ..quadraticBezierTo(
              cx + dx + sway,
              stemBot - blade / 2,
              cx + dx + sway * 1.5,
              stemBot - blade,
            ),
          paint,
        );
      }
    case _:
      // Other moods not used by this slide. Falls back to a simple
      // coloured bloom for safety if the composition ever changes.
      canvas.drawCircle(Offset(cx, stemTop), 6, Paint()..color = color);
  }
}

// ---------------------------------------------------------------------------
// Slide 3 - Notifications (bell + halo + sound waves + sparkles)
// ---------------------------------------------------------------------------

class _NotificationsArtPainter extends _OnboardingArtPainter {
  const _NotificationsArtPainter({required super.mb});

  @override
  void paintContent(Canvas canvas) {
    const w = _OnboardingArtPainter._vbW;
    const h = _OnboardingArtPainter._vbH;
    final cx = w / 2;
    final cy = h * 0.45;

    // Soft green halo + cream inner ring.
    canvas.drawCircle(
      Offset(cx, cy),
      62,
      Paint()..color = MoodBloomColors.softGreen.withValues(alpha: 0.7),
    );
    canvas.drawCircle(Offset(cx, cy), 44, Paint()..color = mb.card);
    canvas.drawCircle(
      Offset(cx, cy),
      44,
      Paint()
        ..color = mb.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Bell - rounded silhouette using a cubic outline. Centred on the
    // halo, with a small clapper below and a coral notification badge
    // tucked into the upper-right.
    canvas.save();
    canvas.translate(cx, cy);
    final bell = Path()
      ..moveTo(-16, 6)
      ..quadraticBezierTo(-16, -14, -6, -20)
      ..quadraticBezierTo(-6, -26, 0, -26)
      ..quadraticBezierTo(6, -26, 6, -20)
      ..quadraticBezierTo(16, -14, 16, 6)
      ..lineTo(18, 8)
      ..quadraticBezierTo(18, 12, 14, 12)
      ..lineTo(-14, 12)
      ..quadraticBezierTo(-18, 12, -18, 8)
      ..close();
    canvas.drawPath(bell, Paint()..color = MoodBloomColors.seed);

    // Clapper.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 16), width: 7, height: 6),
      Paint()..color = MoodBloomColors.seed,
    );

    // Coral badge with a thin background-colour halo so it reads as
    // separated from the bell silhouette.
    canvas.drawCircle(
      const Offset(14, -14),
      6,
      Paint()..color = MoodBloomColors.coral,
    );
    canvas.drawCircle(
      const Offset(14, -14),
      6,
      Paint()
        ..color = mb.bg
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.restore();

    // Sound-wave arcs - two pairs (close + distant) flanking the bell
    // on both sides. Drawn as open quadratic strokes.
    final wavePaint = Paint()
      ..color = MoodBloomColors.seed.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final waveFainter = Paint()
      ..color = MoodBloomColors.seed.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final left1 = Path()
      ..moveTo(cx - 70, cy)
      ..quadraticBezierTo(cx - 70, cy - 12, cx - 58, cy - 18);
    final left2 = Path()
      ..moveTo(cx - 80, cy + 6)
      ..quadraticBezierTo(cx - 82, cy - 14, cx - 64, cy - 24);
    final right1 = Path()
      ..moveTo(cx + 70, cy)
      ..quadraticBezierTo(cx + 70, cy - 12, cx + 58, cy - 18);
    final right2 = Path()
      ..moveTo(cx + 80, cy + 6)
      ..quadraticBezierTo(cx + 82, cy - 14, cx + 64, cy - 24);
    canvas.drawPath(left1, wavePaint);
    canvas.drawPath(left2, waveFainter);
    canvas.drawPath(right1, wavePaint);
    canvas.drawPath(right2, waveFainter);

    // Scattered sparkle dots - small filled circles in mood-happy,
    // coral, and seed colours at low opacity.
    canvas.drawCircle(
      Offset(w * 0.18, h * 0.22),
      2.5,
      Paint()..color = MoodBloomColors.moodHappy.withValues(alpha: 0.8),
    );
    canvas.drawCircle(
      Offset(w * 0.84, h * 0.78),
      3,
      Paint()..color = MoodBloomColors.coral.withValues(alpha: 0.75),
    );
    canvas.drawCircle(
      Offset(w * 0.78, h * 0.18),
      2,
      Paint()..color = MoodBloomColors.seed.withValues(alpha: 0.7),
    );
  }
}

// ---------------------------------------------------------------------------
// Slide 4 - Disclaimer (shield outline + soft inner face + heart at centre)
// ---------------------------------------------------------------------------

class _DisclaimerArtPainter extends _OnboardingArtPainter {
  const _DisclaimerArtPainter({required super.mb});

  @override
  void paintContent(Canvas canvas) {
    const w = _OnboardingArtPainter._vbW;
    const h = _OnboardingArtPainter._vbH;

    canvas.save();
    canvas.translate(w / 2, h / 2 - 4);

    // Outer shield - card-toned fill, line-toned stroke. Lines bend
    // inward at the top to give "rounded shoulders" rather than a
    // sharp point.
    final outer = Path()
      ..moveTo(0, -68)
      ..lineTo(50, -50)
      ..quadraticBezierTo(50, 12, 0, 60)
      ..quadraticBezierTo(-50, 12, -50, -50)
      ..close();
    canvas.drawPath(outer, Paint()..color = mb.card);
    canvas.drawPath(
      outer,
      Paint()
        ..color = mb.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Inner soft-green face - slightly smaller, semi-transparent so
    // the outer card tone shows through.
    final inner = Path()
      ..moveTo(0, -58)
      ..lineTo(42, -44)
      ..quadraticBezierTo(42, 8, 0, 50)
      ..quadraticBezierTo(-42, 8, -42, -44)
      ..close();
    canvas.drawPath(
      inner,
      Paint()..color = MoodBloomColors.softGreen.withValues(alpha: 0.7),
    );

    // Heart at centre - the warm payload of the shield. Two cubics
    // shape the lobes, closed back to the bottom point. The heart
    // alone carries the compassionate intent; the prototype's tiny
    // supportive cross above-left was dropped per design review (it
    // can read as clinical / religious to some users).
    final heart = Path()
      ..moveTo(0, 16)
      ..cubicTo(-22, 0, -28, -16, -16, -22)
      ..cubicTo(-8, -26, 0, -18, 0, -10)
      ..cubicTo(0, -18, 8, -26, 16, -22)
      ..cubicTo(28, -16, 22, 0, 0, 16)
      ..close();
    canvas.drawPath(heart, Paint()..color = MoodBloomColors.seed);

    canvas.restore();
  }
}
