import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../mood/domain/entities/mood_type.dart';

/// Hand-drawn garden flora — a Flutter port of the prototype's
/// `flora.jsx` SVG primitives. Each sprite is a `CustomPaint` (so we
/// avoid pulling in `flutter_svg`) wrapped in a small
/// `_AnimatedFlora` host that drives a slow idle animation.
///
/// Sizing matches the prototype: each painter draws into a 100×100 logical
/// box (centered on x=0, y=0..90) and the parent host scales by
/// `0.55 + intensity * 0.12`. Anchor for sway / scale is bottom-center so
/// stems pivot from the soil.
///
/// Decorative — the surrounding `SkyHeader` exposes one aggregate
/// Semantics label, so individual sprites are excluded from the a11y tree.

/// Mapping from the domain `MoodType` to the design-system `MbMoodKind`.
/// Lives in the garden feature (not in `domain/`) because `MbMoodKind`
/// is a presentation concept; the domain layer must not know about it.
MbMoodKind moodKindOf(MoodType m) => switch (m) {
  MoodType.happy => MbMoodKind.happy,
  MoodType.calm => MbMoodKind.calm,
  MoodType.okay => MbMoodKind.okay,
  MoodType.sad => MbMoodKind.sad,
  MoodType.angry => MbMoodKind.angry,
  MoodType.anxious => MbMoodKind.anxious,
};

/// Visual treatment for a single entry on the garden canvas. Mirrors
/// the prototype's `renderKind` rule:
///  * positive (`happy`, `calm`) → flower
///  * neutral (`okay`) → flower
///  * negative @ intensity ≤ 3 → wilting plant
///  * negative @ intensity ≥ 4 → rain cloud (rendered separately)
enum FloraKind { flower, bud, wilt }

/// Pure mapping from (mood, intensity) to a sprite kind. Mirrors the
/// prototype's `renderKind` and the existing
/// `ComputeGardenStateUseCase.kind` rule, with the small twist that
/// intensity-1 positives render as a smaller `Bud` rather than a full
/// `Flower`.
FloraKind floraKindFor(MoodType mood, int intensity) {
  switch (mood.category) {
    case MoodCategory.positive:
      return intensity <= 1 ? FloraKind.bud : FloraKind.flower;
    case MoodCategory.negativeMild:
    case MoodCategory.negativeStrong:
      // Negatives at i≥4 are rain clouds — those are handled by
      // `RainCloud` directly, not by this enum. Callers must already
      // have filtered those out before reaching here.
      return FloraKind.wilt;
  }
}

/// One full flower (positive moods, intensity ≥ 2). 6 petals, leaves,
/// center pollen dot, slow sway from the bottom-center pivot.
class Flower extends StatelessWidget {
  const Flower({
    super.key,
    required this.mood,
    required this.intensity,
    required this.seed,
    this.size = 100,
  });

  final MbMoodKind mood;
  final int intensity;

  /// Deterministic per-entry seed (typically `entry.id.hashCode.abs()`).
  /// Drives sway period + phase so neighbouring sprites do not animate
  /// in lockstep.
  final int seed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return _AnimatedFlora(
      seed: seed,
      maxRotationDeg: 1.5,
      basePeriod: 5,
      periodSpread: 7,
      child: Transform.scale(
        scale: 0.55 + intensity * 0.12,
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _FlowerPainter(mood: mood)),
        ),
      ),
    );
  }
}

/// Small bud — positive mood at intensity 1.
class Bud extends StatelessWidget {
  const Bud({
    super.key,
    required this.mood,
    required this.seed,
    this.size = 100,
  });

  final MbMoodKind mood;
  final int seed;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Buds also sway, gently — same spec as flowers.
    return _AnimatedFlora(
      seed: seed,
      maxRotationDeg: 1.5,
      basePeriod: 5,
      periodSpread: 7,
      child: Transform.scale(
        scale: 0.55,
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _BudPainter(mood: mood)),
        ),
      ),
    );
  }
}

/// Drooping plant — negative moods at intensity 1..3.
class WiltingPlant extends StatelessWidget {
  const WiltingPlant({
    super.key,
    required this.mood,
    required this.intensity,
    required this.seed,
    this.size = 100,
  }) : assert(
         intensity >= 1 && intensity <= 3,
         'WiltingPlant is for negative intensity 1..3; '
         'use RainCloud for intensity 4..5.',
       );

  final MbMoodKind mood;
  final int intensity;
  final int seed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return _AnimatedFlora(
      seed: seed,
      maxRotationDeg: 0.5,
      basePeriod: 8,
      periodSpread: 9,
      child: Transform.scale(
        scale: 0.7 + intensity * 0.06,
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _WiltingPlantPainter(mood: mood, intensity: intensity),
          ),
        ),
      ),
    );
  }
}

/// Drives the slow rotation tween for any flora sprite. Period is
/// derived from [seed] so the canvas reads as a calm, hand-planted
/// scene rather than a metronome.
class _AnimatedFlora extends StatefulWidget {
  const _AnimatedFlora({
    required this.child,
    required this.seed,
    required this.maxRotationDeg,
    required this.basePeriod,
    required this.periodSpread,
  });

  final Widget child;
  final int seed;
  final double maxRotationDeg;

  /// Lower bound of the period in seconds (e.g. 5 for flowers, 8 for wilt).
  final int basePeriod;

  /// Modulus added to [basePeriod] (e.g. 7 for flowers → 5..11 s,
  /// 9 for wilt → 8..16 s).
  final int periodSpread;

  @override
  State<_AnimatedFlora> createState() => _AnimatedFloraState();
}

class _AnimatedFloraState extends State<_AnimatedFlora>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _angle;

  @override
  void initState() {
    super.initState();
    final periodSec = widget.basePeriod + (widget.seed % widget.periodSpread);
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: periodSec),
    )..repeat(reverse: true);
    final maxRad = widget.maxRotationDeg * math.pi / 180;
    _angle = Tween<double>(
      begin: -maxRad,
      end: maxRad,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _angle,
        builder: (context, child) => Transform.rotate(
          angle: _angle.value,
          alignment: Alignment.bottomCenter,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Translates the painter's logical SVG-style coordinates (centered
/// horizontally, y growing downward, pivot at bottom) into Flutter's
/// canvas (origin top-left). Caller passes a 100×100 [Size]; we shift
/// `x = canvas.x - 50`, `y = canvas.y` so paths from the prototype
/// (e.g. "M0 90 …") line up.
extension on Canvas {
  void withSvgFrame(Size size, void Function(Canvas) fn) {
    save();
    translate(size.width / 2, 0);
    fn(this);
    restore();
  }
}

class _FlowerPainter extends CustomPainter {
  _FlowerPainter({required this.mood});

  final MbMoodKind mood;

  static const _stemColor = Color(0xFF4C8B6A);
  static const _leafColor = Color(0xFF6FA587);
  static const _centerColor = Color(0xFFE8A23B);
  static const _highlightColor = Color(0xFFFFE9B8);

  @override
  void paint(Canvas canvas, Size size) {
    final base = MbMoodPalette.shared.colorOf(mood);
    canvas.withSvgFrame(size, (c) {
      // Stem: M0 90 C -3 70, -2 50, 0 10
      final stemPaint = Paint()
        ..color = _stemColor
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final stem = Path()
        ..moveTo(0, 90)
        ..cubicTo(-3, 70, -2, 50, 0, 10);
      c.drawPath(stem, stemPaint);

      // Two leaves
      final leafPaint = Paint()
        ..color = _leafColor.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill;
      final leafLeft = Path()
        ..moveTo(0, 55)
        ..cubicTo(-10, 50, -14, 42, -14, 38)
        ..cubicTo(-8, 38, -2, 44, 0, 52)
        ..close();
      c.drawPath(leafLeft, leafPaint);

      final leafRight = Path()
        ..moveTo(0, 42)
        ..cubicTo(10, 38, 16, 30, 14, 24)
        ..cubicTo(8, 26, 2, 32, 0, 40)
        ..close();
      c.drawPath(leafRight, leafPaint);

      // Petals — 6 ellipses arranged around the bloom center. The
      // prototype draws each ellipse at (cx, cy) and rotates it about
      // (0, -2) (the bloom center). We replicate by translating to
      // the bloom center, rotating, then drawing the ellipse offset
      // by `petalR` along the +x axis (which after rotation becomes
      // the petal's outward direction).
      final petalPaint = Paint()
        ..color = base.withValues(alpha: 0.95)
        ..style = PaintingStyle.fill;
      const petals = 6;
      const petalR = 10.0;
      for (var i = 0; i < petals; i += 1) {
        final rotation = (i / petals) * 2 * math.pi;
        c.save();
        c.translate(0, -2);
        c.rotate(rotation);
        final rect = Rect.fromCenter(
          center: const Offset(petalR, 0),
          width: 16,
          height: 22,
        );
        c.drawOval(rect, petalPaint);
        c.restore();
      }

      // Center pollen + highlight.
      c.drawCircle(const Offset(0, -2), 5.2, Paint()..color = _centerColor);
      c.drawCircle(
        const Offset(-1.2, -3),
        1.3,
        Paint()..color = _highlightColor,
      );
    });
  }

  @override
  bool shouldRepaint(covariant _FlowerPainter oldDelegate) =>
      oldDelegate.mood != mood;
}

class _BudPainter extends CustomPainter {
  _BudPainter({required this.mood});

  final MbMoodKind mood;

  static const _stemColor = Color(0xFF4C8B6A);
  static const _leafColor = Color(0xFF6FA587);

  @override
  void paint(Canvas canvas, Size size) {
    final base = MbMoodPalette.shared.colorOf(mood);
    canvas.withSvgFrame(size, (c) {
      // Stem: M0 90 C -2 70, -1 45, 0 20
      final stemPaint = Paint()
        ..color = _stemColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final stem = Path()
        ..moveTo(0, 90)
        ..cubicTo(-2, 70, -1, 45, 0, 20);
      c.drawPath(stem, stemPaint);

      // Bud body
      c.drawOval(
        Rect.fromCenter(center: const Offset(0, 14), width: 12, height: 18),
        Paint()..color = base,
      );

      // Tiny leaf curl
      final leafPaint = Paint()
        ..color = _leafColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final leaf = Path()
        ..moveTo(-6, 18)
        ..cubicTo(-8, 14, -8, 10, -4, 8);
      c.drawPath(leaf, leafPaint);
    });
  }

  @override
  bool shouldRepaint(covariant _BudPainter oldDelegate) =>
      oldDelegate.mood != mood;
}

class _WiltingPlantPainter extends CustomPainter {
  _WiltingPlantPainter({required this.mood, required this.intensity});

  final MbMoodKind mood;
  final int intensity;

  // Tan-brown stems for wilting plants — distinct from green flower stems.
  static const _stemColor = Color(0xFF8C7B4F);
  static const _tearColor = Color(0xFF9EC3DB);

  @override
  void paint(Canvas canvas, Size size) {
    final leaf = MbMoodPalette.shared.colorOf(mood);
    final droop = intensity; // 1..3
    final curve = 40 + droop * 12;

    canvas.withSvgFrame(size, (c) {
      // Drooping main stem: M0 90 C 4 60, 10 (90-curve), 18 (110-curve)
      final stemPaint = Paint()
        ..color = _stemColor
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final stem = Path()
        ..moveTo(0, 90)
        ..cubicTo(4, 60, 10, 90 - curve.toDouble(), 18, 110 - curve.toDouble());
      c.drawPath(stem, stemPaint);

      // Secondary upright stem
      final stem2Paint = Paint()
        ..color = _stemColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final stem2 = Path()
        ..moveTo(0, 90)
        ..cubicTo(-2, 70, -6, 50, -2, 35);
      c.drawPath(stem2, stem2Paint);

      // Drooping leaves
      final leafPaint = Paint()
        ..color = leaf.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill;
      final leafLeft = Path()
        ..moveTo(-2, 60)
        ..cubicTo(-14, 62, -18, 70, -14, 74)
        ..cubicTo(-8, 72, -4, 66, -2, 62)
        ..close();
      c.drawPath(leafLeft, leafPaint);

      final leafRight = Paint()
        ..color = leaf.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;
      final leafR = Path()
        ..moveTo(3, 48)
        ..cubicTo(14, 48, 18, 56, 16, 62)
        ..cubicTo(10, 60, 5, 52, 3, 50)
        ..close();
      c.drawPath(leafR, leafRight);

      // Tip leaf curl following the drooping stem
      final tipPaint = Paint()
        ..color = leaf
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final tipPath = Path()
        ..moveTo(18, 110 - curve.toDouble())
        ..cubicTo(
          24,
          110 - curve.toDouble(),
          28,
          118 - curve.toDouble(),
          22,
          124 - curve.toDouble(),
        );
      c.drawPath(tipPath, tipPaint);

      // Tear for sad mood specifically (matches prototype: only `sad`).
      if (mood == MbMoodKind.sad) {
        c.drawCircle(
          Offset(6, (108 - curve).toDouble()),
          1.8,
          Paint()..color = _tearColor,
        );
      }
    });
  }

  @override
  bool shouldRepaint(covariant _WiltingPlantPainter oldDelegate) =>
      oldDelegate.mood != mood || oldDelegate.intensity != intensity;
}
