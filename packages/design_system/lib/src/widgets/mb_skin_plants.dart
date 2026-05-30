import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/garden_skin_id.dart';

/// 30 mood-plant variants (5 skins x 6 moods), ported verbatim from the
/// Claude Design handoff prototype's `skins.jsx`.
///
/// Each skin is a complete alternate visual style for ALL six mood
/// plants. Switching skins re-themes the entire garden - nothing is
/// per-species under the new global skin model.
///
/// Coordinate system: the prototype works in an SVG viewBox of
/// `width x height` (commonly 36x60). Painters here scale the canvas
/// uniformly so callers can pass any [Size]. The SVG `cx = width / 2`
/// and `top = height * 0.28`, `bot = height` anchors are preserved so
/// shapes line up at any size.
///
/// `intensity` (1..5) drives small visual variations: stems get a touch
/// taller and colours grow slightly more saturated at higher intensity,
/// matching the prototype's per-intensity tinting hook.

// ---------------------------------------------------------------------------
// MbMoodKind shim - lives in colors.dart already. Don't re-import here.
// ---------------------------------------------------------------------------

/// Drop-in widget that paints the right plant for `(skinId, mood)` at
/// the supplied [size] and [color] tint.
class MbSkinPlant extends StatelessWidget {
  const MbSkinPlant({
    super.key,
    required this.skinId,
    required this.mood,
    required this.intensity,
    required this.color,
    required this.size,
  });

  /// Which of the five global skins to render.
  final GardenSkinId skinId;

  /// Mood the plant represents.
  final MbMoodKind mood;

  /// 1..5 - mapped to small visual tweaks (stem height, saturation).
  /// Clamped on entry so callers passing 0 or 7 don't blow up.
  final int intensity;

  /// Tint for the bloom. Stem and leaves stay neutral / grass-green.
  final Color color;

  /// Final paint size in device pixels.
  final Size size;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>();
    final grass = mb?.grass ?? const Color(0xFF4C8B6A);
    final i = intensity.clamp(1, 5);
    final painter = _skinPainter(skinId, mood, i, color, grass);
    return SizedBox(
      width: size.width,
      height: size.height,
      child: CustomPaint(painter: painter),
    );
  }
}

CustomPainter _skinPainter(
  GardenSkinId skinId,
  MbMoodKind mood,
  int intensity,
  Color color,
  Color grass,
) {
  switch (skinId) {
    case GardenSkinId.meadow:
      return _MeadowPainter(
        mood: mood,
        intensity: intensity,
        color: color,
        grass: grass,
      );
    case GardenSkinId.origami:
      return _OrigamiPainter(
        mood: mood,
        intensity: intensity,
        color: color,
        grass: grass,
      );
    case GardenSkinId.lantern:
      return _LanternPainter(
        mood: mood,
        intensity: intensity,
        color: color,
        grass: grass,
      );
    case GardenSkinId.constellation:
      return _ConstellationPainter(
        mood: mood,
        intensity: intensity,
        color: color,
        grass: grass,
      );
    case GardenSkinId.crystal:
      return _CrystalPainter(
        mood: mood,
        intensity: intensity,
        color: color,
        grass: grass,
      );
  }
}

// ---------------------------------------------------------------------------
// Base painter - sets up coordinate scaling and the stem path that all
// four prototype skins (Origami / Lantern / Constellation / Crystal) share.
// ---------------------------------------------------------------------------

abstract class _SkinPlantPainterBase extends CustomPainter {
  const _SkinPlantPainterBase({
    required this.mood,
    required this.intensity,
    required this.color,
    required this.grass,
  });

  final MbMoodKind mood;
  final int intensity;
  final Color color;
  final Color grass;

  /// Reference viewBox width (matches `prototype/skins.jsx` defaults).
  static const double viewBoxW = 36;
  static const double viewBoxH = 60;

  /// Returns the stem path in viewBox coords for the given mood.
  /// Ported verbatim from `stemPath()` in `skins.jsx`.
  ///
  /// `intensity` lengthens the visible stem slightly at higher
  /// intensity by lifting `top` upward (smaller y-value), matching the
  /// prototype's "stem grows with intensity" hook.
  Path stemPath() {
    const cx = viewBoxW / 2;
    final intensityShift = (intensity - 3) * 1.2;
    final top = viewBoxH * 0.28 - intensityShift;
    const bot = viewBoxH;

    final p = Path();
    switch (mood) {
      case MbMoodKind.happy:
        p.moveTo(cx, bot);
        p.quadraticBezierTo(cx - 1.2, (bot + top) / 2, cx, top + 2);
      case MbMoodKind.calm:
        p.moveTo(cx, bot);
        p.lineTo(cx, top);
      case MbMoodKind.okay:
        p.moveTo(cx, bot);
        p.lineTo(cx, top + 8);
      case MbMoodKind.sad:
        p.moveTo(cx, bot);
        p.quadraticBezierTo(cx, (bot + top) / 2, cx - 6, top + 4);
      case MbMoodKind.angry:
        final dt = bot - top;
        p.moveTo(cx, bot);
        p.lineTo(cx + 2.5, bot - dt * 0.3);
        p.lineTo(cx - 2, bot - dt * 0.55);
        p.lineTo(cx + 1.5, top + 2);
      case MbMoodKind.anxious:
        p.moveTo(cx, bot);
        p.lineTo(cx, top - 4);
    }
    return p;
  }

  /// Returns the bloom anchor (top of the stem) for the given mood.
  ///
  /// `okay` deliberately uses a SHORTER stem (its `stemPath` ends 8 units
  /// lower at `top + 8`), so its bloom must anchor to that lower tip or it
  /// floats in mid-air above the stem - the bug seen on the "Folded Petal"
  /// (origami okay) skin. Every other mood anchors at the standard stem
  /// top and applies its own per-mood offset inside the skin painter.
  Offset bloomAnchor() {
    const cx = viewBoxW / 2;
    final intensityShift = (intensity - 3) * 1.2;
    final top = viewBoxH * 0.28 - intensityShift;
    final dy = mood == MbMoodKind.okay ? top + 8 : top;
    return Offset(cx, dy);
  }

  /// Scales the canvas so the painter can work in viewBox coords.
  void scaleToViewBox(Canvas canvas, Size size) {
    final sx = size.width / viewBoxW;
    final sy = size.height / viewBoxH;
    canvas.scale(sx, sy);
  }

  /// Mood-tinted color with intensity-driven saturation boost.
  Color boostedColor() {
    final hsl = HSLColor.fromColor(color);
    final saturation = (hsl.saturation + (intensity - 3) * 0.04).clamp(
      0.0,
      1.0,
    );
    return hsl.withSaturation(saturation).toColor();
  }

  @override
  bool shouldRepaint(covariant _SkinPlantPainterBase old) =>
      old.mood != mood ||
      old.intensity != intensity ||
      old.color != color ||
      old.grass != grass;
}

// ---------------------------------------------------------------------------
// 01 - Meadow (default).
// Faithful port of the prototype's `Plant` component from `screens.jsx`
// - the prototype's Meadow plant literally calls `window.Plant({...})`,
// so this skin renders the same geometry as the SkyHeader plot strip
// (the prototype's canonical "default plant" look).
// ---------------------------------------------------------------------------

class _MeadowPainter extends _SkinPlantPainterBase {
  const _MeadowPainter({
    required super.mood,
    required super.intensity,
    required super.color,
    required super.grass,
  });

  /// Reference viewBox - matches `screens.jsx > Plant` (36 x 60 default).
  static const double _w = _SkinPlantPainterBase.viewBoxW;
  static const double _h = _SkinPlantPainterBase.viewBoxH;
  static const double _cx = _w / 2;

  @override
  void paint(Canvas canvas, Size size) {
    scaleToViewBox(canvas, size);
    final tint = boostedColor();

    // Per-mood stem path (already mood-aware in the base class).
    final stemPaint = Paint()
      ..color = grass
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(stemPath(), stemPaint);

    // Per-mood decoration painted in viewBox coordinates - matches the
    // prototype's inline `Plant` SVG groups one-for-one.
    switch (mood) {
      case MbMoodKind.happy:
        _paintHappy(canvas, tint);
      case MbMoodKind.calm:
        _paintCalm(canvas, tint);
      case MbMoodKind.okay:
        _paintOkay(canvas, tint);
      case MbMoodKind.sad:
        _paintSad(canvas, tint);
      case MbMoodKind.angry:
        _paintAngry(canvas, tint);
      case MbMoodKind.anxious:
        _paintAnxious(canvas, tint);
    }
  }

  /// Returns the bloom anchor (top of the stem) consistent with the
  /// per-mood `stemPath`. The `+ 2` lift on Happy + Angry matches the
  /// prototype's `top + 2` head position.
  double _topY() => bloomAnchor().dy;

  // Happy - two leaves + 10-petal sunflower head with seed-dark disk.
  void _paintHappy(Canvas c, Color tint) {
    final leaf = Paint()..color = grass;
    _drawRotatedOval(
      c,
      cx: _cx - 7,
      cy: _h * 0.68,
      rx: 5,
      ry: 2.4,
      rotateDeg: -30,
      paint: leaf,
    );
    _drawRotatedOval(
      c,
      cx: _cx + 7,
      cy: _h * 0.52,
      rx: 5,
      ry: 2.4,
      rotateDeg: 30,
      paint: leaf,
    );
    c.save();
    c.translate(_cx, _topY() - 2);
    final petal = Paint()..color = tint;
    for (var i = 0; i < 10; i += 1) {
      c.save();
      c.rotate(i * (2 * math.pi / 10));
      c.drawOval(
        Rect.fromCenter(center: const Offset(0, -6), width: 4, height: 9),
        petal,
      );
      c.restore();
    }
    c.drawCircle(Offset.zero, 4, Paint()..color = const Color(0xFF6B3E1F));
    c.drawCircle(
      const Offset(-1, -1),
      1.2,
      Paint()..color = MoodBloomColors.seed.withValues(alpha: 0.8),
    );
    c.restore();
  }

  // Calm - paired leaves at three heights + small bud at the apex.
  void _paintCalm(Canvas c, Color tint) {
    final leaf = Paint()..color = grass.withValues(alpha: 0.92);
    for (final y in const <double>[0.72, 0.55, 0.4]) {
      _drawRotatedOval(
        c,
        cx: _cx - 5,
        cy: _h * y,
        rx: 4.5,
        ry: 2,
        rotateDeg: -32,
        paint: leaf,
      );
      _drawRotatedOval(
        c,
        cx: _cx + 5,
        cy: _h * y,
        rx: 4.5,
        ry: 2,
        rotateDeg: 32,
        paint: leaf,
      );
    }
    c.drawOval(
      Rect.fromCenter(center: Offset(_cx, _topY() - 1), width: 6, height: 10),
      Paint()..color = tint,
    );
    c.drawOval(
      Rect.fromCenter(center: Offset(_cx, _topY() - 1), width: 3, height: 7),
      Paint()..color = grass.withValues(alpha: 0.45),
    );
  }

  // Okay - a daisy: a pair of leaves on the short stem, then a ring of
  // rounded petals around a warm yellow eye at the stem tip. Okay is the
  // daisy species, so the default plant for this mood now reads as an
  // actual daisy rather than the old grass tuft (which made the
  // daisy-species skins - "Blush Daisy", "Skyline" - look like grass).
  void _paintOkay(Canvas c, Color tint) {
    final leaf = Paint()..color = grass;
    _drawRotatedOval(
      c,
      cx: _cx - 4,
      cy: _h * 0.72,
      rx: 4,
      ry: 1.8,
      rotateDeg: -28,
      paint: leaf,
    );
    _drawRotatedOval(
      c,
      cx: _cx + 4,
      cy: _h * 0.8,
      rx: 4,
      ry: 1.8,
      rotateDeg: 28,
      paint: leaf,
    );
    // Flower head sits on the stem tip (bloomAnchor handles the okay
    // short-stem offset).
    c.save();
    c.translate(_cx, _topY());
    final petal = Paint()..color = tint;
    for (var i = 0; i < 8; i += 1) {
      c.save();
      c.rotate(i * (2 * math.pi / 8));
      c.drawOval(
        Rect.fromCenter(center: const Offset(0, -5), width: 3.2, height: 7),
        petal,
      );
      c.restore();
    }
    c.drawCircle(Offset.zero, 2.4, Paint()..color = const Color(0xFFF6C744));
    c.drawCircle(
      const Offset(-0.6, -0.6),
      0.9,
      Paint()..color = const Color(0xFFFFE8A3),
    );
    c.restore();
  }

  // Sad - drooping bell flower + a small leaf + a falling droplet.
  void _paintSad(Canvas c, Color tint) {
    c.save();
    c.translate(_cx - 7, _topY() + 4);
    final bell = Path()
      ..moveTo(-3.5, 0)
      ..quadraticBezierTo(-4.5, 7, 0, 7)
      ..quadraticBezierTo(4.5, 7, 3.5, 0)
      ..close();
    c.drawPath(bell, Paint()..color = tint);
    final stamen = Paint()
      ..color = tint.withValues(alpha: 0.7)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    c.drawLine(const Offset(-1.5, 7), const Offset(0, 10), stamen);
    c.drawLine(const Offset(0, 10), const Offset(1.5, 7), stamen);
    c.restore();
    _drawRotatedOval(
      c,
      cx: _cx + 4,
      cy: _h * 0.7,
      rx: 4,
      ry: 2,
      rotateDeg: 20,
      paint: Paint()..color = grass,
    );
    // Droplet beside the bell.
    final droplet = Path()
      ..moveTo(_cx + 8, _h * 0.55)
      ..quadraticBezierTo(_cx + 6, _h * 0.62, _cx + 8, _h * 0.66)
      ..quadraticBezierTo(_cx + 10, _h * 0.62, _cx + 8, _h * 0.55)
      ..close();
    c.drawPath(droplet, Paint()..color = tint.withValues(alpha: 0.85));
  }

  // Angry - spiky leaves + thistle pod with 8 spikes.
  void _paintAngry(Canvas c, Color tint) {
    final spike = Paint()..color = tint.withValues(alpha: 0.88);
    c.drawPath(
      Path()
        ..moveTo(_cx - 9, _h * 0.72)
        ..lineTo(_cx - 1, _h * 0.68)
        ..lineTo(_cx - 9, _h * 0.62)
        ..close(),
      spike,
    );
    c.drawPath(
      Path()
        ..moveTo(_cx + 9, _h * 0.55)
        ..lineTo(_cx + 1, _h * 0.52)
        ..lineTo(_cx + 9, _h * 0.46)
        ..close(),
      spike,
    );
    c.save();
    c.translate(_cx, _topY() + 2);
    c.drawCircle(Offset.zero, 4, Paint()..color = tint);
    final spikePaint = Paint()
      ..color = tint
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 8; i += 1) {
      c.save();
      c.rotate(i * (math.pi / 4));
      c.drawLine(const Offset(0, -4), const Offset(0, -8), spikePaint);
      c.restore();
    }
    c.restore();
  }

  // Anxious - a fern frond: pinnae (leaflets) alternate along the upper
  // rachis, longest near the base and tapering to the tip at the apex.
  // Reads as an actual fern rather than wheat/grass.
  void _paintAnxious(Canvas c, Color tint) {
    final frond = Paint()..color = tint.withValues(alpha: 0.92);
    final tipY = _topY();
    final baseY = _h * 0.62;
    const count = 7;
    for (var i = 0; i < count; i += 1) {
      final t = i / (count - 1);
      final y = tipY + (baseY - tipY) * t;
      final len = 3.0 + t * 7.0;
      final side = i.isEven ? -1.0 : 1.0;
      final tipX = _cx + len * side;
      final tipPY = y - len * 0.5;
      final p = Path()
        ..moveTo(_cx, y)
        ..quadraticBezierTo(_cx + len * 0.4 * side, y - len * 0.6, tipX, tipPY)
        ..quadraticBezierTo(_cx + len * 0.45 * side, y + 0.8, _cx, y)
        ..close();
      c.drawPath(p, frond);
    }
    c.drawCircle(Offset(_cx, tipY - 1), 1.4, frond);
  }

  /// Draws an oval rotated [rotateDeg] degrees around its centre.
  static void _drawRotatedOval(
    Canvas c, {
    required double cx,
    required double cy,
    required double rx,
    required double ry,
    required double rotateDeg,
    required Paint paint,
  }) {
    c.save();
    c.translate(cx, cy);
    c.rotate(rotateDeg * math.pi / 180.0);
    c.drawOval(
      Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
      paint,
    );
    c.restore();
  }
}

// ---------------------------------------------------------------------------
// 02 - Origami (folded paper geometry).
// Ported verbatim from `OrigamiPlant` in `skins.jsx`.
// ---------------------------------------------------------------------------

class _OrigamiPainter extends _SkinPlantPainterBase {
  const _OrigamiPainter({
    required super.mood,
    required super.intensity,
    required super.color,
    required super.grass,
  });

  @override
  void paint(Canvas canvas, Size size) {
    scaleToViewBox(canvas, size);
    final tint = boostedColor();

    // Stem
    final stemPaint = Paint()
      ..color = grass
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(stemPath(), stemPaint);

    // Folded paper leaves (two triangles).
    const cx = _SkinPlantPainterBase.viewBoxW / 2;
    const h = _SkinPlantPainterBase.viewBoxH;
    final leaf1 = Path()
      ..moveTo(cx, h * 0.7)
      ..lineTo(cx - 8, h * 0.66)
      ..lineTo(cx - 4, h * 0.74)
      ..close();
    canvas.drawPath(leaf1, Paint()..color = grass);
    final leaf2 = Path()
      ..moveTo(cx, h * 0.55)
      ..lineTo(cx + 8, h * 0.51)
      ..lineTo(cx + 4, h * 0.59)
      ..close();
    canvas.drawPath(leaf2, Paint()..color = grass.withValues(alpha: 0.85));

    final anchor = bloomAnchor();
    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    _paintBloom(canvas, tint);
    canvas.restore();
  }

  void _paintBloom(Canvas c, Color tint) {
    switch (mood) {
      case MbMoodKind.happy:
        // Crane-like: 5 triangle petals around center, with seed-dark dot.
        c.translate(0, -4);
        final petalPaint = Paint()..color = tint.withValues(alpha: 0.95);
        for (var i = 0; i < 5; i++) {
          c.save();
          c.rotate(i * 2 * math.pi / 5);
          final p = Path()
            ..moveTo(0, 0)
            ..lineTo(0, -10)
            ..lineTo(4, -3)
            ..close();
          c.drawPath(p, petalPaint);
          c.restore();
        }
        final core = Path()
          ..moveTo(-2, 2)
          ..lineTo(2, 2)
          ..lineTo(0, -2)
          ..close();
        c.drawPath(core, Paint()..color = MoodBloomColors.seedDark);
      case MbMoodKind.calm:
        // Diamond bud with centerline.
        c.translate(0, -2);
        final diamond = Path()
          ..moveTo(0, -9)
          ..lineTo(5, 0)
          ..lineTo(0, 7)
          ..lineTo(-5, 0)
          ..close();
        c.drawPath(diamond, Paint()..color = tint);
        c.drawLine(
          const Offset(0, -9),
          const Offset(0, 7),
          Paint()
            ..color = grass.withValues(alpha: 0.6)
            ..strokeWidth = 0.8
            ..style = PaintingStyle.stroke,
        );
      case MbMoodKind.okay:
        // Three folded fronds.
        c.translate(0, _SkinPlantPainterBase.viewBoxH * 0.05);
        for (var i = 0; i < 3; i++) {
          final d = (i - 1) * 4.0;
          final p = Path()
            ..moveTo(d - 2, 0)
            ..lineTo(d + 2, 0)
            ..lineTo(d, -(10.0 - i * 2.0))
            ..close();
          c.drawPath(
            p,
            Paint()..color = (i == 1 ? tint : grass).withValues(alpha: 0.92),
          );
        }
      case MbMoodKind.sad:
        // Folded bell (inverted triangle) with droplet.
        c.translate(-6, 4);
        final bell = Path()
          ..moveTo(-5, 0)
          ..lineTo(5, 0)
          ..lineTo(0, 10)
          ..close();
        c.drawPath(bell, Paint()..color = tint);
        c.drawLine(
          const Offset(0, 0),
          const Offset(0, 10),
          Paint()
            ..color = tint.withValues(alpha: 0.6)
            ..strokeWidth = 0.6
            ..style = PaintingStyle.stroke,
        );
        c.drawCircle(
          const Offset(0, 11),
          1.4,
          Paint()..color = tint.withValues(alpha: 0.7),
        );
      case MbMoodKind.angry:
        // Spiky origami burst.
        final petalPaint = Paint()..color = tint;
        for (var i = 0; i < 6; i++) {
          c.save();
          c.rotate(i * math.pi / 3);
          final p = Path()
            ..moveTo(0, -3)
            ..lineTo(1.4, -10)
            ..lineTo(-1.4, -10)
            ..close();
          c.drawPath(p, petalPaint);
          c.restore();
        }
        final t1 = Path()
          ..moveTo(-3, 0)
          ..lineTo(3, 0)
          ..lineTo(0, -4)
          ..close();
        final t2 = Path()
          ..moveTo(-3, 0)
          ..lineTo(3, 0)
          ..lineTo(0, 4)
          ..close();
        c.drawPath(t1, Paint()..color = tint.withValues(alpha: 0.9));
        c.drawPath(t2, Paint()..color = tint.withValues(alpha: 0.9));
      case MbMoodKind.anxious:
        // Stack of folded grain triangles.
        c.translate(0, -4);
        for (var i = 0; i < 4; i++) {
          c.save();
          c.translate(0, i * 4.0);
          final p = Path()
            ..moveTo(-2.5, 0)
            ..lineTo(2.5, 0)
            ..lineTo(0, -3)
            ..close();
          c.drawPath(p, Paint()..color = tint.withValues(alpha: 0.9));
          c.restore();
        }
    }
  }
}

// ---------------------------------------------------------------------------
// 03 - Lantern (paper lanterns hanging from stems).
// Ported verbatim from `LanternPlant` in `skins.jsx`.
// ---------------------------------------------------------------------------

class _LanternPainter extends _SkinPlantPainterBase {
  const _LanternPainter({
    required super.mood,
    required super.intensity,
    required super.color,
    required super.grass,
  });

  @override
  void paint(Canvas canvas, Size size) {
    scaleToViewBox(canvas, size);
    final tint = boostedColor();

    // Stem
    final stemPaint = Paint()
      ..color = grass
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(stemPath(), stemPaint);

    // Tassel cap at top.
    final anchor = bloomAnchor();
    canvas.drawLine(
      Offset(anchor.dx, anchor.dy),
      Offset(anchor.dx, anchor.dy - 4),
      Paint()
        ..color = grass
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      Offset(anchor.dx, anchor.dy - 5),
      1.6,
      Paint()..color = grass.withValues(alpha: 0.7),
    );

    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    _paintBody(canvas, tint);
    canvas.restore();
  }

  void _paintBody(Canvas c, Color tint) {
    switch (mood) {
      case MbMoodKind.happy:
        // Round bright lantern with glow.
        c.translate(0, 2);
        c.drawCircle(
          const Offset(0, 2),
          10,
          Paint()..color = tint.withValues(alpha: 0.3),
        );
        c.drawOval(
          Rect.fromCenter(center: const Offset(0, 2), width: 14, height: 16),
          Paint()..color = tint,
        );
        final lineP = Paint()
          ..color = MoodBloomColors.seedDark.withValues(alpha: 0.5)
          ..strokeWidth = 0.6
          ..style = PaintingStyle.stroke;
        c.drawLine(const Offset(-7, 0), const Offset(7, 0), lineP);
        c.drawLine(const Offset(-7, 4), const Offset(7, 4), lineP);
        c.drawOval(
          Rect.fromCenter(center: const Offset(-1.5, -1), width: 4, height: 5),
          Paint()..color = const Color(0xFFFFF6D6).withValues(alpha: 0.6),
        );
      case MbMoodKind.calm:
        // Tall slim lantern.
        c.translate(0, 2);
        c.drawOval(
          Rect.fromCenter(center: const Offset(0, 2), width: 8, height: 16),
          Paint()..color = tint,
        );
        c.drawLine(
          const Offset(-4, 2),
          const Offset(4, 2),
          Paint()
            ..color = grass.withValues(alpha: 0.6)
            ..strokeWidth = 0.5
            ..style = PaintingStyle.stroke,
        );
      case MbMoodKind.okay:
        // Hexagonal small lantern.
        c.translate(0, 4);
        final hex = Path()
          ..moveTo(-5, -3)
          ..lineTo(-3, -5)
          ..lineTo(3, -5)
          ..lineTo(5, -3)
          ..lineTo(5, 3)
          ..lineTo(3, 5)
          ..lineTo(-3, 5)
          ..lineTo(-5, 3)
          ..close();
        c.drawPath(hex, Paint()..color = tint.withValues(alpha: 0.95));
      case MbMoodKind.sad:
        // Drooping lantern.
        c.translate(-5, 4);
        c.drawOval(
          Rect.fromCenter(center: const Offset(0, 4), width: 10, height: 14),
          Paint()..color = tint,
        );
        c.drawLine(
          const Offset(-5, 3),
          const Offset(5, 3),
          Paint()
            ..color = grass.withValues(alpha: 0.5)
            ..strokeWidth = 0.5
            ..style = PaintingStyle.stroke,
        );
        c.drawLine(
          const Offset(0, 11),
          const Offset(0, 14),
          Paint()
            ..color = grass
            ..strokeWidth = 0.6
            ..style = PaintingStyle.stroke,
        );
      case MbMoodKind.angry:
        // Spiky lantern.
        c.translate(0, 2);
        final body = Path()
          ..moveTo(0, -8)
          ..lineTo(6, -3)
          ..lineTo(8, 4)
          ..lineTo(4, 9)
          ..lineTo(-4, 9)
          ..lineTo(-8, 4)
          ..lineTo(-6, -3)
          ..close();
        c.drawPath(body, Paint()..color = tint);
        // Spikes
        final sp1 = Path()
          ..moveTo(-8, 4)
          ..lineTo(-11, 1)
          ..lineTo(-9, 3)
          ..close();
        final sp2 = Path()
          ..moveTo(8, 4)
          ..lineTo(11, 1)
          ..lineTo(9, 3)
          ..close();
        final sp3 = Path()
          ..moveTo(0, 9)
          ..lineTo(2, 12)
          ..lineTo(-2, 12)
          ..close();
        c.drawPath(sp1, Paint()..color = tint);
        c.drawPath(sp2, Paint()..color = tint);
        c.drawPath(sp3, Paint()..color = tint);
      case MbMoodKind.anxious:
        // Bamboo-segment lantern (3 stacked ellipses).
        c.translate(0, 4);
        for (var i = 0; i < 3; i++) {
          c.drawOval(
            Rect.fromCenter(center: Offset(0, i * 4.0), width: 6, height: 4),
            Paint()..color = tint.withValues(alpha: 0.95 - i * 0.1),
          );
        }
    }
  }
}

// ---------------------------------------------------------------------------
// 04 - Constellation (line + dot star shapes).
// Ported verbatim from `ConstellationPlant` in `skins.jsx`.
// ---------------------------------------------------------------------------

class _ConstellationPainter extends _SkinPlantPainterBase {
  const _ConstellationPainter({
    required super.mood,
    required super.intensity,
    required super.color,
    required super.grass,
  });

  @override
  void paint(Canvas canvas, Size size) {
    scaleToViewBox(canvas, size);
    final tint = boostedColor();

    // Dashed stem - tinted with the mood colour to read as a constellation
    // line rather than a stem of grass.
    _drawDashedPath(
      canvas,
      stemPath(),
      Paint()
        ..color = tint.withValues(alpha: 0.55)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
      dashWidth: 2,
      dashSpace: 2,
    );

    final anchor = bloomAnchor();
    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    _paintStars(canvas, tint);
    canvas.restore();
  }

  void _paintStars(Canvas c, Color tint) {
    switch (mood) {
      case MbMoodKind.happy:
        // Sun constellation: center star + 6 outer stars.
        c.translate(0, -2);
        for (var i = 0; i < 6; i++) {
          final a = i * math.pi / 3;
          final dx = math.cos(a) * 8;
          final dy = math.sin(a) * 8;
          c.drawLine(
            Offset.zero,
            Offset(dx, dy),
            Paint()
              ..color = tint.withValues(alpha: 0.7)
              ..strokeWidth = 0.6
              ..style = PaintingStyle.stroke,
          );
          _star(c, Offset(dx, dy), 1.6, tint);
        }
        _star(c, Offset.zero, 2.4, tint, bright: true);
      case MbMoodKind.calm:
        // Vertical 3-star line.
        c.drawLine(
          const Offset(0, -8),
          const Offset(0, 6),
          Paint()
            ..color = tint.withValues(alpha: 0.6)
            ..strokeWidth = 0.6
            ..style = PaintingStyle.stroke,
        );
        _star(c, const Offset(0, -8), 1.4, tint);
        _star(c, const Offset(0, -1), 2, tint, bright: true);
        _star(c, const Offset(0, 6), 1.4, tint);
      case MbMoodKind.okay:
        // Triangle constellation.
        c.translate(0, 4);
        final tri = Path()
          ..moveTo(-6, 4)
          ..lineTo(0, -6)
          ..lineTo(6, 4)
          ..lineTo(-6, 4);
        c.drawPath(
          tri,
          Paint()
            ..color = tint.withValues(alpha: 0.6)
            ..strokeWidth = 0.6
            ..style = PaintingStyle.stroke,
        );
        _star(c, const Offset(-6, 4), 1.6, tint);
        _star(c, const Offset(0, -6), 1.6, tint);
        _star(c, const Offset(6, 4), 1.6, tint);
      case MbMoodKind.sad:
        // Falling-droplet constellation.
        c.translate(0, 2);
        c.drawLine(
          const Offset(-6, -4),
          const Offset(0, 8),
          Paint()
            ..color = tint.withValues(alpha: 0.6)
            ..strokeWidth = 0.6
            ..style = PaintingStyle.stroke,
        );
        _star(c, const Offset(-6, -4), 1.6, tint);
        _star(c, const Offset(-2, 3), 1.2, tint);
        _star(c, const Offset(0, 8), 2, tint, bright: true);
      case MbMoodKind.angry:
        // Jagged W constellation.
        c.translate(0, 2);
        final w = Path()
          ..moveTo(-7, 4)
          ..lineTo(-3, -6)
          ..lineTo(0, 2)
          ..lineTo(3, -6)
          ..lineTo(7, 4);
        c.drawPath(
          w,
          Paint()
            ..color = tint.withValues(alpha: 0.6)
            ..strokeWidth = 0.6
            ..style = PaintingStyle.stroke,
        );
        _star(c, const Offset(-7, 4), 1.4, tint);
        _star(c, const Offset(-3, -6), 1.4, tint);
        _star(c, const Offset(0, 2), 1.4, tint);
        _star(c, const Offset(3, -6), 1.4, tint);
        _star(c, const Offset(7, 4), 1.4, tint);
      case MbMoodKind.anxious:
        // Ear-of-wheat stars: 4 paired dots + vertical line.
        c.translate(0, -4);
        for (var i = 0; i < 4; i++) {
          final dy = i * 5.0;
          _star(c, Offset(-3, dy), 1.2, tint);
          _star(c, Offset(3, dy), 1.2, tint);
        }
        c.drawLine(
          const Offset(0, -3),
          const Offset(0, 17),
          Paint()
            ..color = tint.withValues(alpha: 0.5)
            ..strokeWidth = 0.5
            ..style = PaintingStyle.stroke,
        );
    }
  }

  /// Draws a single star (filled dot, plus optional bright halo + white core).
  void _star(
    Canvas c,
    Offset center,
    double r,
    Color color, {
    bool bright = false,
  }) {
    if (bright) {
      c.drawCircle(
        center,
        r * 2.5,
        Paint()..color = color.withValues(alpha: 0.18),
      );
    }
    c.drawCircle(center, r, Paint()..color = color);
    if (bright) {
      c.drawCircle(center, r * 0.4, Paint()..color = Colors.white);
    }
  }
}

/// Manual dashed-stroke path renderer. Flutter's `Path` API has no
/// `strokeDasharray` so we walk the path metrics and stamp short
/// segments by hand.
void _drawDashedPath(
  Canvas canvas,
  Path path,
  Paint paint, {
  required double dashWidth,
  required double dashSpace,
}) {
  for (final m in path.computeMetrics()) {
    double dist = 0;
    while (dist < m.length) {
      final next = math.min(dist + dashWidth, m.length);
      canvas.drawPath(m.extractPath(dist, next), paint);
      dist = next + dashSpace;
    }
  }
}

// ---------------------------------------------------------------------------
// 05 - Crystal (faceted geometric gems).
// Ported verbatim from `CrystalPlant` in `skins.jsx`.
// ---------------------------------------------------------------------------

class _CrystalPainter extends _SkinPlantPainterBase {
  const _CrystalPainter({
    required super.mood,
    required super.intensity,
    required super.color,
    required super.grass,
  });

  @override
  void paint(Canvas canvas, Size size) {
    scaleToViewBox(canvas, size);
    final tint = boostedColor();

    final stemPaint = Paint()
      ..color = grass
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(stemPath(), stemPaint);

    final anchor = bloomAnchor();
    canvas.save();
    canvas.translate(anchor.dx, anchor.dy + 2);
    _paintGem(canvas, tint);
    canvas.restore();
  }

  void _paintGem(Canvas c, Color tint) {
    const whiteHl = Color(0xFFFFFFFF);
    final blackShade = Colors.black;

    switch (mood) {
      case MbMoodKind.happy:
        // Pentagonal gem with white facet + dark facet.
        final outer = Path()
          ..moveTo(0, -10)
          ..lineTo(8, -3)
          ..lineTo(5, 8)
          ..lineTo(-5, 8)
          ..lineTo(-8, -3)
          ..close();
        c.drawPath(outer, Paint()..color = tint);
        final hl = Path()
          ..moveTo(0, -10)
          ..lineTo(0, 8)
          ..lineTo(-8, -3)
          ..close();
        c.drawPath(hl, Paint()..color = whiteHl.withValues(alpha: 0.25));
        final shade = Path()
          ..moveTo(0, -10)
          ..lineTo(5, 8)
          ..lineTo(8, -3)
          ..close();
        c.drawPath(shade, Paint()..color = blackShade.withValues(alpha: 0.08));
      case MbMoodKind.calm:
        // Slim diamond.
        final diamond = Path()
          ..moveTo(0, -9)
          ..lineTo(5, -2)
          ..lineTo(0, 8)
          ..lineTo(-5, -2)
          ..close();
        c.drawPath(diamond, Paint()..color = tint);
        final hl = Path()
          ..moveTo(0, -9)
          ..lineTo(-5, -2)
          ..lineTo(0, 8)
          ..close();
        c.drawPath(hl, Paint()..color = whiteHl.withValues(alpha: 0.25));
      case MbMoodKind.okay:
        // House-shaped gem.
        final house = Path()
          ..moveTo(-6, -3)
          ..lineTo(0, -7)
          ..lineTo(6, -3)
          ..lineTo(6, 5)
          ..lineTo(-6, 5)
          ..close();
        c.drawPath(house, Paint()..color = tint);
        final hl = Path()
          ..moveTo(-6, -3)
          ..lineTo(0, -7)
          ..lineTo(0, 5)
          ..lineTo(-6, 5)
          ..close();
        c.drawPath(hl, Paint()..color = whiteHl.withValues(alpha: 0.2));
      case MbMoodKind.sad:
        // Offset diamond.
        c.translate(-5, 4);
        final diamond = Path()
          ..moveTo(0, -9)
          ..lineTo(4, -3)
          ..lineTo(0, 8)
          ..lineTo(-4, -3)
          ..close();
        c.drawPath(diamond, Paint()..color = tint);
        final hl = Path()
          ..moveTo(0, -9)
          ..lineTo(-4, -3)
          ..lineTo(0, 8)
          ..close();
        c.drawPath(hl, Paint()..color = whiteHl.withValues(alpha: 0.2));
      case MbMoodKind.angry:
        // Spiked gem with side spikes.
        final outer = Path()
          ..moveTo(0, -11)
          ..lineTo(7, -4)
          ..lineTo(5, 3)
          ..lineTo(-5, 3)
          ..lineTo(-7, -4)
          ..close();
        c.drawPath(outer, Paint()..color = tint);
        final innerS = Path()
          ..moveTo(0, -4)
          ..lineTo(4, 2)
          ..lineTo(-4, 2)
          ..close();
        c.drawPath(innerS, Paint()..color = blackShade.withValues(alpha: 0.2));
        final hl = Path()
          ..moveTo(0, -11)
          ..lineTo(0, 3)
          ..lineTo(-7, -4)
          ..close();
        c.drawPath(hl, Paint()..color = whiteHl.withValues(alpha: 0.18));
        final spikeL = Path()
          ..moveTo(-7, -4)
          ..lineTo(-10, -7)
          ..lineTo(-8, -3)
          ..close();
        final spikeR = Path()
          ..moveTo(7, -4)
          ..lineTo(10, -7)
          ..lineTo(8, -3)
          ..close();
        c.drawPath(spikeL, Paint()..color = tint);
        c.drawPath(spikeR, Paint()..color = tint);
      case MbMoodKind.anxious:
        // Three stacked elongated crystals.
        for (var i = 0; i < 3; i++) {
          final dy = i * 4.0;
          final p = Path()
            ..moveTo(0, dy - 4)
            ..lineTo(3, dy)
            ..lineTo(0, dy + 4)
            ..lineTo(-3, dy)
            ..close();
          c.drawPath(
            p,
            Paint()..color = tint.withValues(alpha: 0.95 - i * 0.1),
          );
        }
    }
  }
}
