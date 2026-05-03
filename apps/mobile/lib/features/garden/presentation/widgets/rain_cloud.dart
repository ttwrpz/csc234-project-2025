import 'package:flutter/material.dart';

import '../../../mood/domain/entities/mood_type.dart';

/// Rain-cloud sprite for the garden canvas. Used for negative moods at
/// intensity ≥ 4 (per ADR-0006). A Flutter port of the prototype's
/// `RainCloud` SVG with three drifting cloud bobs and a ring of
/// staggered rain drops.
///
/// The cloud drifts horizontally across the sky header (-60 → +360 dp
/// over `period`) on a repeating linear loop; each drop animates on its
/// own faster sub-controller so rainfall appears continuous without all
/// drops firing in lockstep.
///
/// Decorative — `SkyHeader` carries the aggregate Semantics announcement
/// for the scene; individual clouds are excluded from the a11y tree.
class RainCloud extends StatefulWidget {
  const RainCloud({
    super.key,
    required this.entryId,
    required this.mood,
    required this.intensity,
    this.indexInScene = 0,
    this.animate = true,
    this.size = 80,
  });

  /// Stable identifier of the underlying entry. Drives the seed for the
  /// per-cloud phase offset so two clouds with the same id render at the
  /// same point in their drift cycle.
  final String entryId;
  final MoodType mood;
  final int intensity;

  /// Position of this cloud within the scene's cloud list. Period is
  /// `18 + indexInScene * 4` seconds (see prototype `screens.jsx`).
  final int indexInScene;

  /// When `false`, the cloud renders at its starting position with no
  /// timers. Used by the rain-cloud cap on long histories and by golden
  /// tests that need a deterministic frame.
  final bool animate;

  /// Logical box size; the painter draws into it. The cloud body itself
  /// is roughly 60×30 dp; the rest is reserved for drops below.
  final double size;

  @override
  State<RainCloud> createState() => _RainCloudState();
}

class _RainCloudState extends State<RainCloud> with TickerProviderStateMixin {
  AnimationController? _drift;
  late final List<AnimationController> _drops;

  /// Number of rain drops in the cloud — `intensity + 2` per the prototype.
  late final int _dropCount;

  @override
  void initState() {
    super.initState();
    _dropCount = widget.intensity + 2;
    if (widget.animate) {
      final periodSec = 18 + widget.indexInScene * 4;
      _drift = AnimationController(
        vsync: this,
        duration: Duration(seconds: periodSec),
      )..repeat();
      _drops = List.generate(_dropCount, (i) {
        final ms = ((1.2 + (i % 3) * 0.2) * 1000).round();
        return AnimationController(
          vsync: this,
          duration: Duration(milliseconds: ms),
        )..repeat();
      });
      // Start each drop at a staggered phase (0.15 s apart) so the
      // rainfall looks continuous from frame zero.
      for (var i = 0; i < _drops.length; i += 1) {
        _drops[i].value = ((i * 0.15) % 1.0).clamp(0.0, 1.0);
      }
    } else {
      _drops = const [];
    }
  }

  @override
  void dispose() {
    _drift?.dispose();
    for (final c in _drops) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cloud = ExcludeSemantics(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          // When animate is false, _drops is empty; we still want the
          // CustomPaint to paint once.
          animation: widget.animate
              ? Listenable.merge([_drift!, ..._drops])
              : const AlwaysStoppedAnimation<double>(0),
          builder: (context, _) {
            return CustomPaint(
              painter: _CloudPainter(
                mood: widget.mood,
                drops: List<double>.generate(
                  _dropCount,
                  (i) => widget.animate ? _drops[i].value : 0.0,
                ),
              ),
            );
          },
        ),
      ),
    );

    if (!widget.animate) return cloud;

    // Drift: translate x from -60 → +360 over the period; opacity envelope
    // 0 → 0.85 (10%) → 0.85 (80%) → 0 (100%).
    return AnimatedBuilder(
      animation: _drift!,
      builder: (context, child) {
        final t = _drift!.value;
        final dx = -60.0 + t * (360 - -60);
        final opacity = _envelope(t);
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Opacity(opacity: opacity, child: child),
        );
      },
      child: cloud,
    );
  }

  /// Opacity envelope per the brief:
  ///   0 → 0.85 over t∈[0, 0.1]
  ///   0.85           t∈[0.1, 0.8]
  ///   0.85 → 0       t∈[0.8, 1.0]
  static double _envelope(double t) {
    if (t < 0.1) return (t / 0.1) * 0.85;
    if (t < 0.8) return 0.85;
    return ((1.0 - t) / 0.2).clamp(0.0, 1.0) * 0.85;
  }
}

class _CloudPainter extends CustomPainter {
  _CloudPainter({required this.mood, required this.drops});

  final MoodType mood;

  /// One value per drop in the cloud, each in [0, 1] driven by its
  /// per-drop AnimationController. Used to fade + translate the drop
  /// downward.
  final List<double> drops;

  @override
  void paint(Canvas canvas, Size size) {
    // Cloud center: just below the top of the box, horizontally centered.
    final cx = size.width / 2;
    final cy = size.height * 0.35;
    final dark1 = mood == MoodType.angry
        ? const Color(0xFF8A7A75)
        : const Color(0xFFAEB6BD);
    final dark2 = mood == MoodType.angry
        ? const Color(0xFF6E5E59)
        : const Color(0xFF8A949E);
    final dropCol = mood == MoodType.angry
        ? const Color(0xFFB79B8B)
        : const Color(0xFF9EC3DB);

    canvas.save();
    canvas.translate(cx, cy);

    // Three stacked ellipses for the cloud body.
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 60, height: 28),
      Paint()..color = dark1,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-16, 4), width: 36, height: 24),
      Paint()..color = dark2,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(16, 4), width: 40, height: 24),
      Paint()..color = dark2,
    );
    // Highlight ellipse.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-4, -8), width: 32, height: 20),
      Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.35),
    );

    // Drops — one short stroke per drop, fading + translating per its
    // controller value.
    final dropPaint = Paint()
      ..color = dropCol
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < drops.length; i += 1) {
      final t = drops[i];
      // Per the brief: opacity 0 → 1 over [0, 0.4] then back to 0.
      final opacity = t < 0.4 ? t / 0.4 : ((1 - t) / 0.6).clamp(0.0, 1.0);
      // Drop slides downward: dy from -4 to 10 across the cycle.
      final dy = -4 + t * 14;
      dropPaint.color = dropCol.withValues(alpha: opacity);
      final x = -22.0 + i * 7;
      canvas.drawLine(
        Offset(x, 12 + dy),
        Offset(x - 2, 20 + (i % 2) * 4 + dy),
        dropPaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CloudPainter oldDelegate) {
    if (oldDelegate.mood != mood) return true;
    if (oldDelegate.drops.length != drops.length) return true;
    for (var i = 0; i < drops.length; i += 1) {
      if (oldDelegate.drops[i] != drops[i]) return true;
    }
    return false;
  }
}
