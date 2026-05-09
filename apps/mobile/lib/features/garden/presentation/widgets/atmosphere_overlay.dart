import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/atmosphere.dart';

/// Wraps [child] (typically a [PlantTierGroup]) with a weather treatment
/// driven by [Atmosphere]. The plant layer is the visual base; this
/// overlay adds:
///   * `calmSunny`   — subtle warm gradient, no rain, no clouds.
///   * `brightSunny` — stronger warm gradient + faint sun rays.
///   * `lightRain`   — cool blue-grey gradient + a few falling drops;
///                     plants stay visible underneath.
///   * `storm`       — deeper grey gradient + heavier drops; rain falls
///                     AROUND the plants (the plant tier paints its own
///                     shelter so plants are never struck directly).
///
/// Z-order (bottom → top): [child] → weather gradient → drops/rays.
/// The overlay is `IgnorePointer` so it never steals taps from the
/// plant layer.
///
/// See ADR-0010 §5 for the no-wilt copy/visual rule.
class AtmosphereOverlay extends StatefulWidget {
  const AtmosphereOverlay({
    super.key,
    required this.atmosphere,
    required this.child,
    @visibleForTesting this.animate = true,
  });

  final Atmosphere atmosphere;
  final Widget child;

  /// Disable falling-drop / sun-ray animations. Tests pass `false` so
  /// frames are deterministic and `pumpAndSettle` returns.
  final bool animate;

  @override
  State<AtmosphereOverlay> createState() => _AtmosphereOverlayState();
}

class _AtmosphereOverlayState extends State<AtmosphereOverlay>
    with TickerProviderStateMixin {
  AnimationController? _ctrl;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
      )..repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AtmosphereOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ignore atmosphere changes here — gradient swap happens via build.
    if (widget.animate != oldWidget.animate) {
      _ctrl?.dispose();
      _ctrl = widget.animate
          ? (AnimationController(
              vsync: this,
              duration: const Duration(seconds: 2),
            )..repeat())
          : null;
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: _AtmosphereLayer(
              atmosphere: widget.atmosphere,
              animation: _ctrl,
            ),
          ),
        ),
      ],
    );
  }
}

class _AtmosphereLayer extends StatelessWidget {
  const _AtmosphereLayer({required this.atmosphere, required this.animation});

  final Atmosphere atmosphere;
  final Animation<double>? animation;

  @override
  Widget build(BuildContext context) {
    final gradient = _gradientFor(atmosphere);
    if (animation == null) {
      return CustomPaint(
        painter: _AtmospherePainter(
          atmosphere: atmosphere,
          gradient: gradient,
          phase: 0,
        ),
      );
    }
    return AnimatedBuilder(
      animation: animation!,
      builder: (context, _) => CustomPaint(
        painter: _AtmospherePainter(
          atmosphere: atmosphere,
          gradient: gradient,
          phase: animation!.value,
        ),
      ),
    );
  }

  static LinearGradient _gradientFor(Atmosphere a) => switch (a) {
    Atmosphere.calmSunny => const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x33FFE9C7), Color(0x00FFFFFF)],
    ),
    Atmosphere.brightSunny => const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x4DFFD9A6), Color(0x00FFFFFF)],
    ),
    Atmosphere.lightRain => const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x33A6B2C2), Color(0x00FFFFFF)],
    ),
    Atmosphere.storm => const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x66555F6A), Color(0x00FFFFFF)],
    ),
  };
}

class _AtmospherePainter extends CustomPainter {
  _AtmospherePainter({
    required this.atmosphere,
    required this.gradient,
    required this.phase,
  });

  final Atmosphere atmosphere;
  final LinearGradient gradient;

  /// 0..1 animation phase used for falling drops and sun-ray angle.
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    // Gradient.
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    switch (atmosphere) {
      case Atmosphere.calmSunny:
        // No further treatment.
        break;
      case Atmosphere.brightSunny:
        _paintSunRays(canvas, size);
      case Atmosphere.lightRain:
        _paintDrops(canvas, size, dropCount: 6, opacity: 0.55);
      case Atmosphere.storm:
        _paintDrops(canvas, size, dropCount: 14, opacity: 0.78);
    }
  }

  void _paintSunRays(Canvas canvas, Size size) {
    // 5 faint rays radiating from the upper-right corner. Subtle —
    // accents the gradient rather than dominating it.
    final origin = Offset(size.width * 0.78, 18);
    final paint = Paint()
      ..color = MoodBloomColors.amber.withValues(alpha: 0.18)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 5; i += 1) {
      final t = (i / 4) * (math.pi / 3) + (phase * 0.05);
      final endX = origin.dx + math.cos(t + math.pi) * 64;
      final endY = origin.dy + math.sin(t + math.pi) * 64;
      canvas.drawLine(origin, Offset(endX, endY), paint);
    }
  }

  void _paintDrops(
    Canvas canvas,
    Size size, {
    required int dropCount,
    required double opacity,
  }) {
    // Deterministic xs derived from a fixed seed so two consecutive
    // builds on the same atmosphere render at the same x positions.
    final paint = Paint()
      ..color = const Color(0xFF9EC3DB).withValues(alpha: opacity)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < dropCount; i += 1) {
      final x = ((i + 1) / (dropCount + 1)) * size.width;
      // Each drop has its own phase offset so they don't fall in lockstep.
      final dropPhase = (phase + i * 0.137) % 1.0;
      final y = dropPhase * size.height;
      canvas.drawLine(Offset(x, y), Offset(x - 1.5, y + 6), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter old) =>
      old.atmosphere != atmosphere || old.phase != phase;
}
