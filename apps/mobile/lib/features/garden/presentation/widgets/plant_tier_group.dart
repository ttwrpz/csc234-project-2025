import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/plant_tier.dart';

/// Renders the garden's plants for a given [PlantTier]. Five distinct
/// scenes - every one renders plants alive, sheltered, and intact even
/// in `stormSeason`. Rain belongs to [AtmosphereOverlay] (the weather
/// layer above the plants); this widget never paints rain itself.
///
/// Per-tier visual palette (composed from `MoodBloomColors`):
///   * Flourishing - many large blossoms + butterflies, brightest greens.
///   * Thriving    - fewer-but-tall blossoms, full leafy stems.
///   * Resting     - closed buds + small leaves, calm muted palette.
///   * Weathering  - closed buds + a soft cloud shadow ABOVE (not over)
///                   the plants; vertical stems, leaves intact.
///   * Storm Season - closed buds + brighter lanterns + an implied
///                    shelter; plants vertical, leaves intact, no rain.
class PlantTierGroup extends StatelessWidget {
  const PlantTierGroup({
    super.key,
    required this.tier,
    required this.entryCount,
    this.size = const Size(320, 100),
    @visibleForTesting this.animate = true,
  });

  final PlantTier tier;

  /// Total entries this week. Used by callers wanting to surface a
  /// diagnostic line ("12 entries this week"). The widget itself only
  /// uses the value for an aggregate Semantics label.
  final int entryCount;

  /// Logical size of the planter row. Defaults to the SkyHeader's
  /// usable canvas width.
  final Size size;

  /// Disable lantern glow / butterfly drift animations. Tests pass
  /// `false` so frames are deterministic.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;

    return Semantics(
      container: true,
      label: _semanticsLabel(tier, entryCount),
      child: ExcludeSemantics(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: CustomPaint(
            painter: _PlantTierPainter(tier: tier, palette: mb),
          ),
        ),
      ),
    );
  }

  static String _semanticsLabel(PlantTier tier, int entryCount) {
    final entries = entryCount == 1 ? '1 entry' : '$entryCount entries';
    return switch (tier) {
      PlantTier.flourishing =>
        'Flourishing garden - full blossoms across the row. $entries this week.',
      PlantTier.thriving =>
        'Thriving garden - tall stems with bright blossoms. $entries this week.',
      PlantTier.resting =>
        'Resting garden - closed buds and gentle greens. $entries this week.',
      PlantTier.weathering =>
        'Weathering garden - buds sheltered, plants intact. $entries this week.',
      PlantTier.stormSeason =>
        'Storm Season - plants sheltered, lanterns lit. $entries this week.',
    };
  }
}

/// Single painter for all 5 tiers. Keeps the widget tree shallow and
/// deterministic for goldens - tier-specific drawing is dispatched in
/// [paint] via a switch.
class _PlantTierPainter extends CustomPainter {
  _PlantTierPainter({required this.tier, required this.palette});

  final PlantTier tier;
  final MbColors palette;

  // Stem + leaf tones are reused across tiers; tier shifts the saturation
  // via the leaf alpha so each scene reads distinctly without changing
  // the overall warm-cream identity.
  static const _stemColor = Color(0xFF4C8B6A);

  // Extra stem palettes push tiers visually further apart. _stemBright
  // lifts Flourishing into a vivid meadow green; _stemCream is the
  // warm-cream Resting/Storm stem that reads as "alive but quiet"
  // without dropping into a desaturated gray that would look dormant.
  static const _stemBright = Color(0xFF3F8259);
  static const _stemCream = Color(0xFFB8A878);

  @override
  void paint(Canvas canvas, Size size) {
    switch (tier) {
      case PlantTier.flourishing:
        _paintFlourishing(canvas, size);
      case PlantTier.thriving:
        _paintThriving(canvas, size);
      case PlantTier.resting:
        _paintResting(canvas, size);
      case PlantTier.weathering:
        _paintWeathering(canvas, size);
      case PlantTier.stormSeason:
        _paintStormSeason(canvas, size);
    }
  }

  // Bloom palette pulled apart per tier so the three positive tiers
  // don't all read as "green stems + small color dot". Flourishing =
  // warm sun (amber + coral mix). Thriving = soft pink. Resting =
  // misty lavender. Each one occupies a distinct hue family.
  static const _bloomFlourishingA = Color(0xFFE8A23B); // amber
  static const _bloomFlourishingB = Color(0xFFE77A8C); // coral
  static const _bloomFlourishingC = Color(0xFFF6C45A); // warm yellow
  static const _bloomThrivingA = Color(0xFFF6A86B); // peach
  static const _bloomThrivingB = Color(0xFFE6A4B4); // dusty pink
  static const _bloomRestingA = Color(0xFFB8A1C9); // soft lavender

  void _paintFlourishing(Canvas canvas, Size size) {
    // 9 tall blossoms in a riot of warm sun colors, varying heights to
    // break the "row of identical tulips" silhouette, bud satellites,
    // ground micro-clusters, sun glow at top-right, and 3 butterflies.
    // The clear-sky reading dominates the panel.
    const palette = [
      _bloomFlourishingA,
      _bloomFlourishingB,
      _bloomFlourishingC,
    ];
    final centers = _evenlySpaced(size.width, 9);
    for (var i = 0; i < centers.length; i += 1) {
      final cx = centers[i];
      // Stagger height so the bed reads as natural growth, not a fence.
      final h = i.isEven ? 90.0 : 80.0;
      final color = palette[i % palette.length];
      _drawStem(canvas, cx, size.height, height: h, color: _stemBright);
      _drawBlossom(
        canvas,
        Offset(cx, size.height - h),
        radius: 13,
        color: color,
      );
      // Tiny bud satellites flanking the main blossom.
      _drawSatellite(canvas, Offset(cx - 12, size.height - h + 14), color);
      _drawSatellite(canvas, Offset(cx + 12, size.height - h + 8), color);
    }
    // Sun glow in the top-right corner - only Flourishing has it.
    canvas.drawCircle(
      Offset(size.width - 18, 16),
      14,
      Paint()..color = _bloomFlourishingC.withValues(alpha: 0.7),
    );
    canvas.drawCircle(
      Offset(size.width - 18, 16),
      8,
      Paint()..color = const Color(0xFFFFF1B8),
    );
    // Ground-level micro flower clusters.
    _drawGroundCluster(canvas, Offset(size.width * 0.08, size.height - 4));
    _drawGroundCluster(canvas, Offset(size.width * 0.50, size.height - 4));
    _drawGroundCluster(canvas, Offset(size.width * 0.92, size.height - 4));
    _drawButterfly(canvas, Offset(size.width * 0.22, 22), _bloomFlourishingB);
    _drawButterfly(canvas, Offset(size.width * 0.50, 14), _bloomFlourishingA);
    _drawButterfly(canvas, Offset(size.width * 0.78, 28), _bloomFlourishingC);
  }

  void _paintThriving(Canvas canvas, Size size) {
    // 5 medium blossoms in peach + dusty-pink, mid-height stems, double
    // leaves on every stem. One butterfly. No sun, no clusters, no
    // satellites - the visual delta vs Flourishing is clear at a glance
    // (different colors, fewer blooms, no ground decoration).
    const palette = [_bloomThrivingA, _bloomThrivingB];
    final centers = _evenlySpaced(size.width, 5);
    for (var i = 0; i < centers.length; i += 1) {
      final cx = centers[i];
      _drawStem(canvas, cx, size.height, height: 66);
      _drawLeaf(
        canvas,
        Offset(cx - 6, size.height - 36),
        Offset(cx - 16, size.height - 48),
      );
      _drawLeaf(
        canvas,
        Offset(cx + 6, size.height - 48),
        Offset(cx + 16, size.height - 58),
      );
      _drawBlossom(
        canvas,
        Offset(cx, size.height - 66),
        radius: 9,
        color: palette[i % palette.length],
      );
    }
    _drawButterfly(canvas, Offset(size.width * 0.65, 18), _bloomThrivingB);
  }

  void _paintResting(Canvas canvas, Size size) {
    // 3 closed lavender buds on cream stems, distinctive curved-wing
    // pose so they read clearly as "not open yet", plus a wide
    // morning-mist band that fills the upper third. The lavender hue
    // separates Resting from the warmer Thriving palette unambiguously.
    final centers = _evenlySpaced(size.width, 3);

    // Wide mist band makes the "quiet morning" reading unmistakable.
    // Two stacked ovals at decreasing alpha give it depth without
    // consuming the bed.
    final mistFar = Paint()
      ..color = _bloomRestingA.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;
    final mistNear = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, 22),
        width: size.width * 0.85,
        height: 18,
      ),
      mistFar,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, 26),
        width: size.width * 0.65,
        height: 10,
      ),
      mistNear,
    );

    for (final cx in centers) {
      _drawStem(canvas, cx, size.height, height: 52, color: _stemCream);
      _drawLeaf(
        canvas,
        Offset(cx - 4, size.height - 28),
        Offset(cx - 14, size.height - 38),
      );
      _drawClosedBud(
        canvas,
        Offset(cx, size.height - 52),
        color: _bloomRestingA,
      );
    }
  }

  void _paintWeathering(Canvas canvas, Size size) {
    // 3 closed buds, leaves intact, soft cloud shadow ABOVE the plants
    // (NOT covering them) - the cloud floats in the upper third of the
    // panel, plants stay vertical and visible underneath.
    final centers = _evenlySpaced(size.width, 3);

    // Soft cloud shadow - single soft ellipse, low alpha.
    final cloudPaint = Paint()
      ..color = palette.textDim.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.45, 22),
        width: 110,
        height: 22,
      ),
      cloudPaint,
    );

    for (final cx in centers) {
      _drawStem(canvas, cx, size.height, height: 56);
      _drawLeaf(
        canvas,
        Offset(cx - 4, size.height - 30),
        Offset(cx - 12, size.height - 40),
      );
      _drawClosedBud(
        canvas,
        Offset(cx, size.height - 56),
        color: MoodBloomColors.moodSad,
      );
    }

    // A single small fallen leaf on the soil signals "weather" without
    // doom: a tilted oval at the bottom-center in low-alpha stem color,
    // so the bed still reads as cared-for.
    canvas.save();
    canvas.translate(size.width / 2 - 6, size.height - 6);
    canvas.rotate(-0.4);
    canvas.drawOval(
      const Rect.fromLTWH(0, 0, 14, 6),
      Paint()..color = _stemColor.withValues(alpha: 0.7),
    );
    canvas.restore();
  }

  void _paintStormSeason(Canvas canvas, Size size) {
    // 3 closed buds, plants sheltered + intact. Two lanterns brighter
    // than usual sit between the plants. Rain is NOT in this widget -
    // AtmosphereOverlay paints it. The "shelter" is implied by an
    // arched roof line above the plants.
    final centers = _evenlySpaced(size.width, 3);

    // Implied shelter - a flat arch at the top of the panel.
    final shelterPaint = Paint()
      ..color = palette.textDim.withValues(alpha: 0.18)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final shelter = Path()
      ..moveTo(size.width * 0.10, 8)
      ..quadraticBezierTo(size.width / 2, 0, size.width * 0.90, 8);
    canvas.drawPath(shelter, shelterPaint);

    for (final cx in centers) {
      _drawStem(canvas, cx, size.height, height: 56);
      _drawLeaf(
        canvas,
        Offset(cx - 4, size.height - 30),
        Offset(cx - 12, size.height - 40),
      );
      _drawClosedBud(
        canvas,
        Offset(cx, size.height - 56),
        color: MoodBloomColors.moodAnxious,
      );
    }

    // Two lanterns - brighter glow than the usual mood swatches so
    // they read as a hopeful focal point in the storm tier.
    _drawLantern(canvas, Offset(size.width * 0.20, size.height - 30));
    _drawLantern(canvas, Offset(size.width * 0.80, size.height - 30));
  }

  // ───── primitives ─────

  static List<double> _evenlySpaced(double width, int count) {
    final spacing = width / (count + 1);
    return [for (var i = 1; i <= count; i += 1) spacing * i];
  }

  void _drawStem(
    Canvas canvas,
    double cx,
    double bottom, {
    required double height,
    Color? color,
  }) {
    final paint = Paint()
      ..color = color ?? _stemColor
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, bottom), Offset(cx, bottom - height), paint);
  }

  // Tiny opening-bud satellite used in the Flourishing tier.
  void _drawSatellite(Canvas canvas, Offset center, [Color? color]) {
    canvas.drawCircle(
      center,
      3.5,
      Paint()
        ..color = (color ?? MoodBloomColors.moodHappy).withValues(alpha: 0.85),
    );
  }

  // Ground-level micro flower cluster (3 small circles) used to give
  // Flourishing a "lush bed" feel without overcrowding the row.
  void _drawGroundCluster(Canvas canvas, Offset center) {
    final p = Paint()..color = MoodBloomColors.moodCalm.withValues(alpha: 0.7);
    canvas.drawCircle(center.translate(-4, 0), 2.4, p);
    canvas.drawCircle(center.translate(4, -1), 2.4, p);
    canvas.drawCircle(center.translate(0, -3), 2.4, p);
  }

  void _drawLeaf(Canvas canvas, Offset attach, Offset tip) {
    final leafColor = const Color(0xFF6FA587).withValues(alpha: 0.85);
    final p = Path()
      ..moveTo(attach.dx, attach.dy)
      ..quadraticBezierTo((attach.dx + tip.dx) / 2, tip.dy - 4, tip.dx, tip.dy)
      ..quadraticBezierTo(
        (attach.dx + tip.dx) / 2,
        tip.dy + 4,
        attach.dx,
        attach.dy,
      )
      ..close();
    canvas.drawPath(p, Paint()..color = leafColor);
  }

  void _drawBlossom(
    Canvas canvas,
    Offset center, {
    required double radius,
    required Color color,
  }) {
    // 6 petals around the center.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    final petalPaint = Paint()..color = color.withValues(alpha: 0.95);
    for (var i = 0; i < 6; i += 1) {
      canvas.save();
      canvas.rotate((i / 6) * 2 * math.pi);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(radius, 0),
          width: radius * 1.6,
          height: radius * 2.2,
        ),
        petalPaint,
      );
      canvas.restore();
    }
    canvas.drawCircle(
      Offset.zero,
      radius * 0.5,
      Paint()..color = const Color(0xFFE8A23B),
    );
    canvas.restore();
  }

  void _drawClosedBud(Canvas canvas, Offset top, {required Color color}) {
    canvas.drawOval(
      Rect.fromCenter(center: top, width: 10, height: 16),
      Paint()..color = color.withValues(alpha: 0.9),
    );
  }

  void _drawButterfly(Canvas canvas, Offset center, Color color) {
    final wing = Paint()..color = color.withValues(alpha: 0.85);
    canvas.drawCircle(center.translate(-4, 0), 4, wing);
    canvas.drawCircle(center.translate(4, 0), 4, wing);
    canvas.drawCircle(center, 1.4, Paint()..color = palette.text);
  }

  void _drawLantern(Canvas canvas, Offset center) {
    // Brighter glow + slightly larger ring so "we're sheltered, light
    // still on" reads even on the dimmer Storm Season backdrop.
    final glow = Paint()..color = MoodBloomColors.amber.withValues(alpha: 0.5);
    canvas.drawCircle(center, 14, glow);
    final core = Paint()..color = const Color(0xFFFFE9B8);
    canvas.drawCircle(center, 6, core);
    final stroke = Paint()
      ..color = MoodBloomColors.amber
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 6, stroke);
  }

  @override
  bool shouldRepaint(covariant _PlantTierPainter old) =>
      old.tier != tier || old.palette != palette;
}
