import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/plant_tier.dart';

/// Renders the garden's plants for a given [PlantTier]. Five distinct
/// scenes — every one renders plants alive, sheltered, and intact even
/// in `stormSeason`. Rain belongs to [AtmosphereOverlay] (the weather
/// layer above the plants); this widget never paints rain itself. See
/// ADR-0010 §4 for the visual contract and copy rules.
///
/// Per-tier visual palette (composed from `MoodBloomColors`):
///   * Flourishing — many large blossoms + butterflies, brightest greens.
///   * Thriving    — fewer-but-tall blossoms, full leafy stems.
///   * Resting     — closed buds + small leaves, calm muted palette.
///   * Weathering  — closed buds + a soft cloud shadow ABOVE (not over)
///                   the plants; vertical stems, leaves intact.
///   * Storm Season — closed buds + brighter lanterns + an implied
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
        'Flourishing garden — full blossoms across the row. $entries this week.',
      PlantTier.thriving =>
        'Thriving garden — tall stems with bright blossoms. $entries this week.',
      PlantTier.resting =>
        'Resting garden — closed buds and gentle greens. $entries this week.',
      PlantTier.weathering =>
        'Weathering garden — buds sheltered, plants intact. $entries this week.',
      PlantTier.stormSeason =>
        'Storm Season — plants sheltered, lanterns lit. $entries this week.',
    };
  }
}

/// Single painter for all 5 tiers. Keeps the widget tree shallow and
/// deterministic for goldens — tier-specific drawing is dispatched in
/// [paint] via a switch.
class _PlantTierPainter extends CustomPainter {
  _PlantTierPainter({required this.tier, required this.palette});

  final PlantTier tier;
  final MbColors palette;

  // Stem + leaf tones are reused across tiers; tier shifts the saturation
  // via the leaf alpha so each scene reads distinctly without changing
  // the overall warm-cream identity.
  static const _stemColor = Color(0xFF4C8B6A);

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

  void _paintFlourishing(Canvas canvas, Size size) {
    // 6 large blossoms, evenly spaced; 2 butterflies above the row.
    final centers = _evenlySpaced(size.width, 6);
    for (final cx in centers) {
      _drawStem(canvas, cx, size.height, height: 80);
      _drawBlossom(
        canvas,
        Offset(cx, size.height - 80),
        radius: 10,
        color: MoodBloomColors.moodHappy,
      );
    }
    _drawButterfly(
      canvas,
      Offset(size.width * 0.25, 14),
      MoodBloomColors.moodCalm,
    );
    _drawButterfly(
      canvas,
      Offset(size.width * 0.75, 22),
      MoodBloomColors.moodAnxious,
    );
  }

  void _paintThriving(Canvas canvas, Size size) {
    // 4 medium blossoms + tall leafy stems.
    final centers = _evenlySpaced(size.width, 4);
    for (final cx in centers) {
      _drawStem(canvas, cx, size.height, height: 70);
      _drawLeaf(
        canvas,
        Offset(cx - 6, size.height - 38),
        Offset(cx - 16, size.height - 50),
      );
      _drawLeaf(
        canvas,
        Offset(cx + 6, size.height - 50),
        Offset(cx + 16, size.height - 60),
      );
      _drawBlossom(
        canvas,
        Offset(cx, size.height - 70),
        radius: 8,
        color: MoodBloomColors.moodCalm,
      );
    }
  }

  void _paintResting(Canvas canvas, Size size) {
    // 3 closed buds, calm palette, modest height.
    final centers = _evenlySpaced(size.width, 3);
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
        color: MoodBloomColors.moodOkay,
      );
    }
  }

  void _paintWeathering(Canvas canvas, Size size) {
    // 3 closed buds, leaves intact, soft cloud shadow ABOVE the plants
    // (NOT covering them) — the cloud floats in the upper third of the
    // panel, plants stay vertical and visible underneath.
    final centers = _evenlySpaced(size.width, 3);

    // Soft cloud shadow — single soft ellipse, low alpha.
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
  }

  void _paintStormSeason(Canvas canvas, Size size) {
    // 3 closed buds, plants sheltered + intact. Two lanterns brighter
    // than usual sit between the plants. Rain is NOT in this widget —
    // AtmosphereOverlay paints it. The "shelter" is implied by an
    // arched roof line above the plants.
    final centers = _evenlySpaced(size.width, 3);

    // Implied shelter — a flat arch at the top of the panel.
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

    // Two lanterns — brighter glow than the usual mood swatches so
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
  }) {
    final paint = Paint()
      ..color = _stemColor
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, bottom), Offset(cx, bottom - height), paint);
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
    // Bright amber glow ring + warm core. Brighter than the mood
    // swatches so the storm tier still reads as hopeful.
    final glow = Paint()..color = MoodBloomColors.amber.withValues(alpha: 0.35);
    canvas.drawCircle(center, 12, glow);
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
