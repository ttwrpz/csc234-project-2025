import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../tokens/domain/entities/flower_skin.dart' show FlowerPetalShape;
import '../../domain/entities/flower_species.dart';

/// A small (default 24×24) iconic sprite for one of the six
/// [FlowerSpecies]. Rendered as a [CustomPaint] so we avoid pulling in
/// SVG / image asset dependencies.
///
/// Unlike the larger `Flower` / `WiltingPlant` sprites in
/// `flora_sprite.dart`, this widget paints **just the bloom head** (or
/// the leaf silhouette for `fern`) — there's no stem, no leaves, and no
/// idle animation. It is meant to be dropped into list tiles, chips,
/// and harvest-week thumbnails as a glanceable cue alongside the mood
/// label and intensity dots.
///
/// All six species are visually distinct in light + dark themes by way
/// of their petal shape, count, and color. The default tint is the
/// design-system mood color associated with the species (e.g.
/// sunflower → `MbMoodKind.happy` swatch). Pass [tint] to override.
class FlowerSprite extends StatelessWidget {
  const FlowerSprite({
    super.key,
    required this.species,
    this.size = 24,
    this.tint,
    this.excludeSemantics = true,
    this.petalShape = FlowerPetalShape.classic,
  });

  final FlowerSpecies species;
  final double size;
  final Color? tint;

  /// Petal geometry override from the user's selected [FlowerSkin].
  /// `classic` (default) preserves the species' original shape
  /// pixel-for-pixel; alternates render via the shared radial petal
  /// painter so skins read visually distinct, not just colour swaps.
  final FlowerPetalShape petalShape;

  /// When `true` (the default) the sprite is hidden from the a11y tree
  /// — the parent widget (e.g. `MoodEntryTile`) typically already
  /// announces the mood. Set `false` if the sprite is the only label.
  final bool excludeSemantics;

  /// No-op today; kept for parity with the larger sprites in
  /// `flora_sprite.dart` so future polish that animates these icons
  /// can flip the flag without changing call-sites.
  @visibleForTesting
  static const bool animate = false;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<MbMoodPalette>()!;
    final color = tint ?? palette.colorOf(_speciesMoodKind(species));
    final painter = _FlowerSpritePainter(
      species: species,
      color: color,
      petalShape: petalShape,
    );
    final paint = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: painter),
    );

    if (excludeSemantics) {
      return ExcludeSemantics(child: paint);
    }
    return Semantics(label: semanticLabelOf(species), child: paint);
  }

  /// Stable label format used by tests and screen readers when the
  /// sprite is the sole label for its row. Fern uses "leaf" rather than
  /// "flower" because that's what the silhouette actually depicts.
  static String semanticLabelOf(FlowerSpecies species) => switch (species) {
    FlowerSpecies.sunflower => 'sunflower flower',
    FlowerSpecies.forgetMeNot => 'forget-me-not flower',
    FlowerSpecies.daisy => 'daisy flower',
    FlowerSpecies.poppy => 'poppy flower',
    FlowerSpecies.fern => 'fern leaf',
    FlowerSpecies.lavender => 'lavender flower',
  };
}

/// Maps each [FlowerSpecies] back to the design-system mood it
/// represents, so that a sprite without an explicit `tint` picks up
/// the same swatch the rest of the surface uses for that mood.
MbMoodKind _speciesMoodKind(FlowerSpecies species) => switch (species) {
  FlowerSpecies.sunflower => MbMoodKind.happy,
  FlowerSpecies.forgetMeNot => MbMoodKind.sad,
  FlowerSpecies.daisy => MbMoodKind.okay,
  FlowerSpecies.poppy => MbMoodKind.angry,
  FlowerSpecies.fern => MbMoodKind.anxious,
  FlowerSpecies.lavender => MbMoodKind.calm,
};

/// Paints into a logical 100×100 box centered on (0, 0..100) so each
/// species' geometry can be expressed in fixed coordinates regardless
/// of the actual `size` the caller chose. The canvas is scaled
/// uniformly by [paintingScale]. Mirrors the `withSvgFrame` extension
/// in `flora_sprite.dart`.
class _FlowerSpritePainter extends CustomPainter {
  _FlowerSpritePainter({
    required this.species,
    required this.color,
    this.petalShape = FlowerPetalShape.classic,
  });

  final FlowerSpecies species;
  final Color color;
  final FlowerPetalShape petalShape;

  static const double _logicalSize = 100;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final scale = size.shortestSide / _logicalSize;
    canvas.scale(scale, scale);
    canvas.translate(_logicalSize / 2, _logicalSize / 2);
    // Non-classic skins use the shared shaped-petal painter so the
    // geometry difference is consistent across the catalog. Fern
    // (a frond, not a bloom) never honours the override.
    if (petalShape != FlowerPetalShape.classic &&
        species != FlowerSpecies.fern) {
      _paintShapedPetals(canvas);
      canvas.restore();
      return;
    }
    switch (species) {
      case FlowerSpecies.sunflower:
        _paintSunflower(canvas);
      case FlowerSpecies.forgetMeNot:
        _paintForgetMeNot(canvas);
      case FlowerSpecies.daisy:
        _paintDaisy(canvas);
      case FlowerSpecies.poppy:
        _paintPoppy(canvas);
      case FlowerSpecies.fern:
        _paintFern(canvas);
      case FlowerSpecies.lavender:
        _paintLavender(canvas);
    }
    canvas.restore();
  }

  /// Shared radial petal painter used by all non-classic skins. Each
  /// shape uses 6 petals around a centre disk so the silhouette reads
  /// distinct without needing per-species tuning. The centre dot keeps
  /// the species' mood-tint signature so skins still feel "owned" by
  /// the species they unlock for.
  void _paintShapedPetals(Canvas c) {
    final petalPaint = Paint()..color = color;
    const petalCount = 6;
    for (var i = 0; i < petalCount; i += 1) {
      final theta = (i / petalCount) * 2 * math.pi;
      c.save();
      c.rotate(theta);
      _drawPetal(c, petalPaint, petalShape);
      c.restore();
    }
    // Centre disk in a deeper neutral so the petal hue carries the
    // skin's identity instead of the centre overwhelming it.
    c.drawCircle(Offset.zero, 10, Paint()..color = const Color(0xFF6B4A1F));
  }

  void _drawPetal(Canvas c, Paint paint, FlowerPetalShape shape) {
    switch (shape) {
      case FlowerPetalShape.classic:
        c.drawOval(
          Rect.fromCenter(center: const Offset(26, 0), width: 18, height: 28),
          paint,
        );
      case FlowerPetalShape.rounded:
        c.drawCircle(const Offset(28, 0), 14, paint);
      case FlowerPetalShape.pointed:
        final p = Path()
          ..moveTo(10, 0)
          ..quadraticBezierTo(20, 14, 42, 0)
          ..quadraticBezierTo(20, -14, 10, 0)
          ..close();
        c.drawPath(p, paint);
      case FlowerPetalShape.star:
        final p = Path()
          ..moveTo(12, 0)
          ..lineTo(28, 10)
          ..lineTo(46, 0)
          ..lineTo(28, -10)
          ..close();
        c.drawPath(p, paint);
      case FlowerPetalShape.heart:
        final p = Path()
          ..moveTo(14, 0)
          ..cubicTo(14, -16, 38, -16, 30, 0)
          ..cubicTo(38, 16, 14, 16, 14, 0)
          ..close();
        c.drawPath(p, paint);
    }
  }

  /// Round disk + 12 narrow radiating petals — the warm yellow/amber
  /// signature of a sunflower.
  void _paintSunflower(Canvas c) {
    final petalPaint = Paint()..color = color;
    const petalCount = 12;
    for (var i = 0; i < petalCount; i += 1) {
      final theta = (i / petalCount) * 2 * math.pi;
      c.save();
      c.rotate(theta);
      final rect = Rect.fromCenter(
        center: const Offset(28, 0),
        width: 18,
        height: 30,
      );
      c.drawOval(rect, petalPaint);
      c.restore();
    }
    c.drawCircle(Offset.zero, 18, Paint()..color = const Color(0xFF6B4A1F));
    c.drawCircle(
      const Offset(-3, -3),
      4,
      Paint()..color = const Color(0xFF8C6532),
    );
  }

  /// Tiny 5-petal flower with a yellow dot center — the muted-blue
  /// signature shape of a forget-me-not.
  void _paintForgetMeNot(Canvas c) {
    final petalPaint = Paint()..color = color;
    const petalCount = 5;
    for (var i = 0; i < petalCount; i += 1) {
      final theta = (i / petalCount) * 2 * math.pi - math.pi / 2;
      final cx = 22 * math.cos(theta);
      final cy = 22 * math.sin(theta);
      c.drawCircle(Offset(cx, cy), 16, petalPaint);
    }
    c.drawCircle(Offset.zero, 8, Paint()..color = const Color(0xFFE8C04A));
  }

  /// 8 white petals on a yellow disk — the cleanest, most iconic of
  /// the bunch.
  void _paintDaisy(Canvas c) {
    final petalPaint = Paint()..color = const Color(0xFFFAFAF0);
    const petalCount = 8;
    for (var i = 0; i < petalCount; i += 1) {
      final theta = (i / petalCount) * 2 * math.pi;
      c.save();
      c.rotate(theta);
      final rect = Rect.fromCenter(
        center: const Offset(26, 0),
        width: 14,
        height: 28,
      );
      c.drawOval(rect, petalPaint);
      c.restore();
    }
    // The mood-tinted "okay" color goes on the center disk so the
    // sprite still picks up the surface's mood swatch.
    c.drawCircle(Offset.zero, 14, Paint()..color = color);
    c.drawCircle(
      Offset.zero,
      14,
      Paint()
        ..color = const Color(0xFFE8A23B)
        ..style = PaintingStyle.fill
        ..blendMode = BlendMode.modulate,
    );
  }

  /// 4 large petals with a dark center — deep red tint, evoking poppy.
  void _paintPoppy(Canvas c) {
    final petalPaint = Paint()..color = const Color(0xFFC8423A);
    const petalCount = 4;
    for (var i = 0; i < petalCount; i += 1) {
      final theta = (i / petalCount) * 2 * math.pi + math.pi / 4;
      c.save();
      c.rotate(theta);
      final rect = Rect.fromCenter(
        center: const Offset(20, 0),
        width: 36,
        height: 28,
      );
      c.drawOval(rect, petalPaint);
      c.restore();
    }
    // Mood-tinted ring around the dark center carries the "angry"
    // swatch through to the otherwise-fixed poppy palette.
    c.drawCircle(Offset.zero, 11, Paint()..color = color);
    c.drawCircle(Offset.zero, 7, Paint()..color = const Color(0xFF1F1A18));
  }

  /// Frond silhouette — fern is anxious's pick. Drawn as a vertical
  /// rachis with paired pinnae descending in size to a tapered tip,
  /// rendered in muted green.
  void _paintFern(Canvas c) {
    final leafColor = const Color(0xFF4C8B6A);
    final rachisPaint = Paint()
      ..color = leafColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final rachis = Path()
      ..moveTo(0, 38)
      ..cubicTo(2, 18, -2, -10, 0, -38);
    c.drawPath(rachis, rachisPaint);

    final pinnaePaint = Paint()..color = leafColor;
    // Six pairs of pinnae, decreasing in length toward the tip.
    final lengths = <double>[22, 20, 18, 14, 10, 6];
    for (var i = 0; i < lengths.length; i += 1) {
      final y = 28.0 - i * 12.0;
      final len = lengths[i];
      final leftRect = Rect.fromCenter(
        center: Offset(-len / 2 - 2, y),
        width: len,
        height: 7,
      );
      final rightRect = Rect.fromCenter(
        center: Offset(len / 2 + 2, y - 4),
        width: len,
        height: 7,
      );
      c.drawOval(leftRect, pinnaePaint);
      c.drawOval(rightRect, pinnaePaint);
    }
    // Mood-tinted dot at the base so the sprite still picks up the
    // surface's "anxious" swatch even though the fronds are fixed
    // green.
    c.drawCircle(const Offset(0, 38), 4, Paint()..color = color);
  }

  /// Vertical stalk with 4 small flower buds — muted purple lavender.
  void _paintLavender(Canvas c) {
    final stalkPaint = Paint()
      ..color = const Color(0xFF4C8B6A)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final stalk = Path()
      ..moveTo(0, 40)
      ..lineTo(0, -32);
    c.drawPath(stalk, stalkPaint);

    final budPaint = Paint()..color = color;
    // Four offset buds climbing the stalk.
    final budCenters = <Offset>[
      const Offset(-6, -18),
      const Offset(6, -8),
      const Offset(-6, 4),
      const Offset(6, 16),
    ];
    for (final cBud in budCenters) {
      c.drawOval(
        Rect.fromCenter(center: cBud, width: 16, height: 22),
        budPaint,
      );
    }
    // Top bud
    c.drawOval(
      Rect.fromCenter(center: const Offset(0, -28), width: 12, height: 18),
      budPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FlowerSpritePainter oldDelegate) =>
      oldDelegate.species != species ||
      oldDelegate.color != color ||
      oldDelegate.petalShape != petalShape;
}
