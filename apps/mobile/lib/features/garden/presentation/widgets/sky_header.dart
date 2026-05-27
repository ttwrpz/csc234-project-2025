import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../mood/domain/entities/mood_entry.dart';
import '../../domain/entities/atmosphere.dart';
import '../../domain/entities/garden_state.dart';
import '../../domain/entities/plant_tier.dart';
import 'atmosphere_overlay.dart';
import 'sky_plot_strip.dart';

/// Atmospheric hero that opens the Garden screen. Per the v1.6
/// prototype the SkyHeader carries:
///
///   * Sky gradient (atmosphere-aware AND tier-aware - 5 tiers x
///     light/dark variants).
///   * Per-tier atmosphere painter (sun/moon, clouds, butterflies,
///     bats, fireflies, aurora, leaves, rain, lightning).
///   * Ground layer along the bottom.
///   * Rain overlay (`AtmosphereOverlay`) above the ground when the
///     tier-gated atmosphere resolves to rain/storm.
///   * `YOUR GARDEN, TODAY` eyebrow + serif tier tagline in the
///     top-left of the canvas.
///   * `SkyPlotStrip` at the bottom - 7 daily plots (Mon..Sun) with
///     mood-keyed mini-plants, overflow pills, day-letter labels.
///
/// The strip replaces the v1.5 `GardenBed` single-row painter so the
/// 7-day visualisation lives inside the hero (matching the prototype's
/// `GardenScreen` composition - see `.tmp-handoff/.../screens.jsx`).
class SkyHeader extends StatelessWidget {
  const SkyHeader({
    super.key,
    required this.state,
    required this.weekEntries,
    required this.weekStart,
    this.height = 320,
  });

  /// Computed garden snapshot - drives both the plant tier and the
  /// atmosphere overlay.
  final GardenState state;

  /// All mood entries falling within the active week. Forwarded to
  /// the inner [SkyPlotStrip] which buckets them into 7 daily plots.
  /// Need not be sorted.
  final List<MoodEntry> weekEntries;

  /// Monday-aligned local-midnight of the active week. The strip's
  /// 7 plots are `weekStart`, `weekStart + 1d`, ..., `weekStart + 6d`.
  final DateTime weekStart;

  /// Total canvas height. 320 dp is the phone-class default; desktop
  /// callers pass ~420 dp so the canvas reads as a hero on a wide
  /// viewport instead of a thin band.
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mb = theme.extension<MbColors>()!;
    final compact = height <= 340;

    // Tier-gated atmosphere (see [_atmosphereForTier] docstring) -
    // used for the sky gradient, sun dim AND the rain overlay so all
    // three weather signals stay consistent with the plant tier.
    final atmosphere = _atmosphereForTier(state.plantTier, state.atmosphere);

    final darkOverlay =
        theme.brightness == Brightness.dark ||
        state.plantTier == PlantTier.stormSeason;
    final eyebrowColor = _eyebrowColor(state.plantTier, theme.brightness, mb);
    final titleColor = _titleColor(state.plantTier, theme.brightness, mb);
    final labelColor = _labelColor(state.plantTier, theme.brightness, mb);
    final labelOpacity = state.plantTier == PlantTier.stormSeason ? 0.85 : 0.7;

    return Semantics(
      container: true,
      label:
          'Garden canvas - ${state.plantTier.name} tier, '
          '${state.atmosphere.name} sky.',
      child: SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(MoodBloomSpacing.radiusSky),
            bottomRight: Radius.circular(MoodBloomSpacing.radiusSky),
          ),
          child: Stack(
            children: [
              // Sky gradient - atmosphere-aware + tier-tinted.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0, 0.55, 1],
                      colors: _skyColorsFor(atmosphere, state.plantTier, mb),
                    ),
                  ),
                ),
              ),
              // Per-tier atmospheric extras (clouds, sun/moon, aurora,
              // fireflies, leaves, rain, lightning). Sits above the
              // gradient but below the ground + strip.
              Positioned.fill(
                child: CustomPaint(
                  painter: _TierAtmospherePainter(
                    tier: state.plantTier,
                    isDark: theme.brightness == Brightness.dark,
                    sun1: mb.sun1,
                    sun2: mb.sun2,
                  ),
                ),
              ),
              // Legacy sun glow on the Thriving baseline only - the
              // tier painter handles the sun on all other tiers.
              if (state.plantTier == PlantTier.thriving)
                Positioned(
                  top: 60,
                  right: 34,
                  child: Opacity(
                    opacity: _sunOpacity(atmosphere),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            mb.sun1,
                            mb.sun2,
                            mb.sun2.withValues(alpha: 0),
                          ],
                          stops: const [0, 0.7, 1],
                        ),
                      ),
                    ),
                  ),
                ),
              // Ground (CustomPaint at the bottom).
              Positioned.fill(
                child: CustomPaint(
                  painter: _GroundPainter(
                    ground: mb.ground,
                    ground2: mb.ground2,
                    grass: mb.grass,
                  ),
                ),
              ),
              // Atmosphere overlay covers the FULL sky canvas. Rain
              // falls from the top of the canvas through to the
              // ground line so storm reads as a whole-sky event, not
              // a ground-level mist.
              Positioned.fill(
                child: AtmosphereOverlay(
                  atmosphere: atmosphere,
                  child: const SizedBox.expand(),
                ),
              ),
              // YOUR GARDEN, TODAY eyebrow + tier tagline.
              Positioned(
                top: compact ? 22 : 28,
                left: compact ? 18 : 24,
                right: compact ? 18 : 24,
                child: _CanvasTitleBlock(
                  eyebrow: 'YOUR GARDEN, TODAY',
                  title: tierTagline(state),
                  eyebrowColor: eyebrowColor,
                  titleColor: titleColor,
                  compact: compact,
                  shadowed:
                      state.plantTier == PlantTier.stormSeason ||
                      theme.brightness == Brightness.dark,
                ),
              ),
              // 7-day plot strip across the bottom of the canvas.
              Positioned(
                left: compact ? 10 : 16,
                right: compact ? 10 : 16,
                bottom: compact ? 16 : 22,
                child: SkyPlotStrip(
                  weekEntries: weekEntries,
                  weekStart: weekStart,
                  tier: state.plantTier,
                  compact: compact,
                  labelColor: labelColor,
                  labelOpacity: labelOpacity,
                  darkOverlay: darkOverlay,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Reconciles the use case's [Atmosphere] (computed from today's
  /// mean) with the bed's [PlantTier]. Negative tiers may keep the
  /// raw atmosphere; positive/neutral tiers force a sunny atmosphere
  /// so the user never sees rain over flowering plants.
  static Atmosphere _atmosphereForTier(PlantTier tier, Atmosphere raw) {
    switch (tier) {
      case PlantTier.stormSeason:
      case PlantTier.weathering:
        return raw;
      case PlantTier.resting:
        return switch (raw) {
          Atmosphere.storm => Atmosphere.lightRain,
          Atmosphere.lightRain => Atmosphere.calmSunny,
          _ => raw,
        };
      case PlantTier.thriving:
      case PlantTier.flourishing:
        return switch (raw) {
          Atmosphere.storm || Atmosphere.lightRain => Atmosphere.calmSunny,
          _ => raw,
        };
    }
  }

  static double _sunOpacity(Atmosphere a) => switch (a) {
    Atmosphere.calmSunny || Atmosphere.brightSunny => 1.0,
    Atmosphere.lightRain => 0.40,
    Atmosphere.storm => 0.10,
  };

  /// Sky gradient colours per atmosphere + plant tier. The atmosphere
  /// drives the base palette; the tier then applies a soft directional
  /// tint so the five tier states read as distinct skies at a glance.
  static List<Color> _skyColorsFor(Atmosphere a, PlantTier tier, MbColors mb) {
    final base = switch (a) {
      Atmosphere.calmSunny ||
      Atmosphere.brightSunny => [mb.skyTop, mb.skyMid, mb.skyBot],
      Atmosphere.lightRain => [
        Color.lerp(mb.skyTop, const Color(0xFFB6C0CC), 0.55)!,
        Color.lerp(mb.skyMid, const Color(0xFFC8D2DD), 0.45)!,
        Color.lerp(mb.skyBot, const Color(0xFFD8DFE7), 0.35)!,
      ],
      Atmosphere.storm => [
        Color.lerp(mb.skyTop, const Color(0xFF3D454F), 0.78)!,
        Color.lerp(mb.skyMid, const Color(0xFF555F6A), 0.65)!,
        Color.lerp(mb.skyBot, const Color(0xFF8590A0), 0.45)!,
      ],
    };
    return _applyTierTint(base, tier);
  }

  static List<Color> _applyTierTint(List<Color> base, PlantTier tier) {
    final (Color tint, double t) = switch (tier) {
      PlantTier.flourishing => (const Color(0xFFFFE9B0), 0.22),
      PlantTier.thriving => (const Color(0xFFD8EBD0), 0.16),
      PlantTier.resting => (Colors.transparent, 0.0),
      PlantTier.weathering => (const Color(0xFFB6BFC9), 0.18),
      PlantTier.stormSeason => (const Color(0xFF5A6470), 0.22),
    };
    if (t == 0) return base;
    return [for (final c in base) Color.lerp(c, tint, t)!];
  }

  /// Compassionate, no-streak-shaming caption per the plant tier and
  /// total entry count. Empty-state copy ("plant your first mood")
  /// kicks in when the user has logged nothing at all.
  static String tierTagline(GardenState state) {
    if (state.isEmpty) return 'Plant your first mood - a fresh canvas awaits.';
    return switch (state.plantTier) {
      PlantTier.flourishing => 'A flourishing week.',
      PlantTier.thriving => 'Thriving - the garden has grown.',
      PlantTier.resting => 'Resting - quiet days for the soil.',
      PlantTier.weathering => 'Weathering a soft week - roots hold.',
      PlantTier.stormSeason => 'Storms pass. The roots hold.',
    };
  }

  // ---------- canvas text colour picks ----------

  static Color _eyebrowColor(
    PlantTier tier,
    Brightness brightness,
    MbColors mb,
  ) {
    if (brightness == Brightness.dark) {
      return Colors.white.withValues(alpha: 0.8);
    }
    if (tier == PlantTier.stormSeason) {
      return Colors.white.withValues(alpha: 0.85);
    }
    return mb.text.withValues(alpha: 0.7);
  }

  static Color _titleColor(PlantTier tier, Brightness brightness, MbColors mb) {
    if (brightness == Brightness.dark) return const Color(0xFFF0F3F7);
    if (tier == PlantTier.stormSeason) return Colors.white;
    return mb.text;
  }

  static Color _labelColor(PlantTier tier, Brightness brightness, MbColors mb) {
    if (brightness == Brightness.dark) return const Color(0xFFF0F3F7);
    if (tier == PlantTier.stormSeason) return Colors.white;
    return mb.text;
  }
}

/// `YOUR GARDEN, TODAY` eyebrow + serif tier tagline. Constrained to
/// the left ~68% of the canvas so the sun/moon decoration in the
/// top-right (drawn by the atmosphere painter) doesn't collide with
/// the tagline at narrower widths.
class _CanvasTitleBlock extends StatelessWidget {
  const _CanvasTitleBlock({
    required this.eyebrow,
    required this.title,
    required this.eyebrowColor,
    required this.titleColor,
    required this.compact,
    required this.shadowed,
  });

  final String eyebrow;
  final String title;
  final Color eyebrowColor;
  final Color titleColor;
  final bool compact;
  final bool shadowed;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: 0.68,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            eyebrow,
            style: MbFonts.nunito(
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w600,
              color: eyebrowColor,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: MbFonts.fraunces(
              fontSize: compact ? 22 : 30,
              fontWeight: FontWeight.w600,
              color: titleColor,
              height: 1.1,
              shadows: shadowed
                  ? <Shadow>[
                      const Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3,
                        color: Color(0x66000000),
                      ),
                    ]
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints the two-layer ground + grass blades along the horizon.
class _GroundPainter extends CustomPainter {
  _GroundPainter({
    required this.ground,
    required this.ground2,
    required this.grass,
  });

  final Color ground;
  final Color ground2;
  final Color grass;

  static const double _horizonFromBottom = 36;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final horizonY = size.height - _horizonFromBottom;

    final p1 = Path()
      ..moveTo(0, horizonY)
      ..cubicTo(
        w * 0.20,
        horizonY - 10,
        w * 0.40,
        horizonY + 8,
        w * 0.60,
        horizonY - 6,
      )
      ..cubicTo(w * 0.80, horizonY - 14, w * 0.95, horizonY + 4, w, horizonY)
      ..lineTo(w, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(p1, Paint()..color = ground);

    final p2 = Path()
      ..moveTo(0, horizonY + 16)
      ..cubicTo(
        w * 0.25,
        horizonY + 6,
        w * 0.50,
        horizonY + 22,
        w * 0.70,
        horizonY + 14,
      )
      ..cubicTo(
        w * 0.85,
        horizonY + 8,
        w * 0.95,
        horizonY + 22,
        w,
        horizonY + 16,
      )
      ..lineTo(w, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(p2, Paint()..color = ground2.withValues(alpha: 0.7));

    final grassPaint = Paint()
      ..color = grass.withValues(alpha: 0.6)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final blades = (w / 18).clamp(16, 64).toInt();
    for (var i = 0; i < blades; i += 1) {
      final x = 8 + i * (w - 16) / blades;
      final y = horizonY - 1 + (i % 3) * 1.5;
      canvas.drawLine(Offset(x, y), Offset(x + 2, y - 8), grassPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GroundPainter old) =>
      old.ground != ground || old.ground2 != ground2 || old.grass != grass;
}

/// Per-tier atmosphere painter. Ports the prototype's
/// `FlourishingSky / ThrivingSky / RestingSky / WeatheringSky /
/// StormSky` SVG groups (light + dark) to `Canvas` ops.
///
/// All shapes are expressed in a 400x200 logical viewBox (the
/// prototype's SVG viewbox) and the painter scales the canvas to the
/// actual size so positions stay consistent regardless of how wide
/// the SkyHeader gets. The y range above ~150 is the "sky band"
/// (everything above the horizon); the painter never draws below
/// ~y=170 so it can't collide with the ground layer.
class _TierAtmospherePainter extends CustomPainter {
  const _TierAtmospherePainter({
    required this.tier,
    required this.isDark,
    required this.sun1,
    required this.sun2,
  });

  final PlantTier tier;
  final bool isDark;
  final Color sun1;
  final Color sun2;

  static const double _vw = 400;
  static const double _vh = 200;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _vw, size.height / _vh);
    canvas.clipRect(const Rect.fromLTWH(0, 0, _vw, _vh));
    switch (tier) {
      case PlantTier.flourishing:
        isDark ? _flourishingDark(canvas) : _flourishingLight(canvas);
      case PlantTier.thriving:
        isDark ? _thrivingDark(canvas) : _thrivingLight(canvas);
      case PlantTier.resting:
        isDark ? _restingDark(canvas) : _restingLight(canvas);
      case PlantTier.weathering:
        isDark ? _weatheringDark(canvas) : _weatheringLight(canvas);
      case PlantTier.stormSeason:
        isDark ? _stormDark(canvas) : _stormLight(canvas);
    }
    canvas.restore();
  }

  // -------------------------------------------------------------
  // FLOURISHING
  // -------------------------------------------------------------

  void _flourishingLight(Canvas c) {
    _drawSunWithRays(
      c,
      center: const Offset(340, 60),
      glowR: 68,
      coreR: 24,
      midR: 30,
      rayCount: 14,
      rayInnerR: 36,
      rayOuterR: 58,
      rayOpacity: 0.5,
    );
    _drawClouds(c, [
      _Cloud(60, 42, 22, 8, 0.7),
      _Cloud(75, 38, 14, 7, 0.7),
      _Cloud(50, 40, 11, 5, 0.7),
      _Cloud(190, 30, 20, 7, 0.55),
      _Cloud(200, 26, 11, 5, 0.55),
      _Cloud(135, 72, 14, 5, 0.5),
    ], color: Colors.white);
    _drawButterfly(
      c,
      const Offset(115, 100),
      colorA: const Color(0xFFF6C45A),
      colorB: const Color(0xFFF4A78C),
    );
    _drawButterfly(
      c,
      const Offset(245, 115),
      colorA: const Color(0xFFF4A78C),
      colorB: const Color(0xFFF6C45A),
    );
    // Two small "M"-shaped birds drifting in the middle band.
    _drawBirdStroke(c, const Offset(250, 70));
    _drawBirdStroke(c, const Offset(270, 86));
  }

  void _flourishingDark(Canvas c) {
    _drawStarfield(c, count: 28, seed: 3);
    _drawMoon(c, const Offset(340, 56), 26);
    final aurora1 = Paint()
      ..color = const Color(0xFF5BA38B).withValues(alpha: 0.22)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    c.drawPath(
      Path()
        ..moveTo(-20, 90)
        ..quadraticBezierTo(80, 70, 200, 80)
        ..quadraticBezierTo(320, 90, 420, 75),
      aurora1,
    );
    final aurora2 = Paint()
      ..color = const Color(0xFFD88FB0).withValues(alpha: 0.18)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    c.drawPath(
      Path()
        ..moveTo(-20, 110)
        ..quadraticBezierTo(100, 95, 220, 105)
        ..quadraticBezierTo(340, 115, 420, 100),
      aurora2,
    );
    _drawFirefly(c, const Offset(70, 130));
    _drawFirefly(c, const Offset(120, 120), opacity: 0.7);
    _drawFirefly(c, const Offset(185, 140));
    _drawFirefly(c, const Offset(245, 125), opacity: 0.6);
    _drawFirefly(c, const Offset(305, 138), opacity: 0.8);
  }

  // -------------------------------------------------------------
  // THRIVING
  // -------------------------------------------------------------

  void _thrivingLight(Canvas c) {
    _drawClouds(c, [
      _Cloud(70, 50, 26, 9, 0.55),
      _Cloud(85, 44, 16, 8, 0.55),
      _Cloud(55, 46, 12, 6, 0.55),
      _Cloud(200, 32, 22, 7, 0.45),
      _Cloud(210, 28, 13, 6, 0.45),
      _Cloud(155, 78, 16, 5, 0.4),
      _Cloud(162, 75, 9, 4, 0.4),
    ], color: Colors.white);
    // Two small "M"-shaped birds drifting in the middle band.
    _drawBirdStroke(c, const Offset(110, 95));
    _drawBirdStroke(c, const Offset(245, 86));
  }

  void _thrivingDark(Canvas c) {
    _drawStarfield(c, count: 22, seed: 1);
    _drawMoon(c, const Offset(340, 60), 22);
    _drawClouds(c, [
      _Cloud(70, 50, 26, 6, 0.6),
      _Cloud(85, 44, 14, 5, 0.6),
      _Cloud(200, 36, 22, 5, 0.5),
    ], color: const Color(0xFF3A4A60));
    // Two bat silhouettes - same "M" path as the daytime birds, but
    // near-black with higher opacity so they read as bats against
    // the night-time gradient.
    _drawBirdStroke(
      c,
      const Offset(110, 95),
      color: const Color(0xFF0E1622),
      opacity: 0.65,
    );
    _drawBirdStroke(
      c,
      const Offset(245, 86),
      color: const Color(0xFF0E1622),
      opacity: 0.65,
    );
  }

  // -------------------------------------------------------------
  // RESTING
  // -------------------------------------------------------------

  void _restingLight(Canvas c) {
    _drawSunDisc(c, const Offset(320, 60), 18, sun1.withValues(alpha: 0.85));
    _drawSunGlow(c, const Offset(320, 60), 40, 0.4);
    _drawClouds(c, [
      _Cloud(290, 64, 28, 11, 0.75),
      _Cloud(320, 56, 22, 11, 0.75),
      _Cloud(345, 62, 20, 10, 0.75),
      _Cloud(310, 72, 34, 6, 0.75),
      _Cloud(80, 40, 32, 9, 0.5),
      _Cloud(105, 34, 16, 7, 0.5),
      _Cloud(55, 36, 14, 6, 0.5),
      _Cloud(175, 68, 22, 6, 0.35),
    ], color: Colors.white);
    // Single distant bird - thinner stroke + lower opacity.
    _drawBirdStroke(c, const Offset(140, 95), strokeWidth: 1.2, opacity: 0.3);
  }

  void _restingDark(Canvas c) {
    _drawStarfield(c, count: 14, seed: 2);
    _drawCrescentMoon(c, const Offset(320, 58), 20);
    _drawClouds(c, [
      _Cloud(290, 64, 28, 11, 0.7),
      _Cloud(320, 56, 22, 11, 0.7),
      _Cloud(345, 62, 20, 10, 0.7),
      _Cloud(310, 72, 34, 6, 0.7),
      _Cloud(80, 40, 32, 8, 0.6),
      _Cloud(105, 34, 16, 6, 0.6),
      _Cloud(55, 36, 14, 5, 0.6),
      _Cloud(175, 68, 22, 6, 0.45),
    ], color: const Color(0xFF403A52));
  }

  // -------------------------------------------------------------
  // WEATHERING
  // -------------------------------------------------------------

  void _weatheringLight(Canvas c) {
    _drawSunDisc(c, const Offset(350, 50), 30, sun1.withValues(alpha: 0.4));
    _drawClouds(c, [
      _Cloud(340, 50, 44, 14, 0.85),
      _Cloud(370, 42, 22, 11, 0.85),
      _Cloud(310, 44, 22, 11, 0.85),
    ], color: const Color(0xFFE6E4DA));
    _drawClouds(c, [
      _Cloud(100, 50, 50, 14, 0.85),
      _Cloud(130, 42, 22, 11, 0.85),
      _Cloud(70, 42, 22, 11, 0.85),
    ], color: const Color(0xFFDDDBD0));
    _drawClouds(c, [
      _Cloud(220, 68, 42, 12, 0.7),
      _Cloud(200, 62, 18, 9, 0.7),
    ], color: const Color(0xFFE0DED4));
    _drawLeaf(
      c,
      const Offset(80, 120),
      const Color(0xFF8B6F63),
      rotateDeg: 25,
      opacity: 0.7,
    );
    _drawLeaf(
      c,
      const Offset(170, 138),
      const Color(0xFF8B6F63),
      rotateDeg: -15,
      opacity: 0.7,
    );
    _drawLeaf(
      c,
      const Offset(260, 108),
      const Color(0xFF8B6F63),
      rotateDeg: 40,
      opacity: 0.6,
    );
    final wisp = Paint()
      ..color = const Color(0xFF8B6F63).withValues(alpha: 0.35)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    c.drawPath(
      Path()
        ..moveTo(50, 130)
        ..quadraticBezierTo(62, 127, 74, 130)
        ..quadraticBezierTo(86, 133, 98, 129),
      wisp,
    );
    c.drawPath(
      Path()
        ..moveTo(200, 145)
        ..quadraticBezierTo(212, 142, 224, 145)
        ..quadraticBezierTo(236, 148, 248, 144),
      wisp,
    );
  }

  void _weatheringDark(Canvas c) {
    _drawClouds(c, [
      _Cloud(340, 50, 44, 14, 0.85),
      _Cloud(370, 42, 22, 11, 0.85),
      _Cloud(310, 44, 22, 11, 0.85),
    ], color: const Color(0xFF2C3239));
    _drawClouds(c, [
      _Cloud(100, 50, 50, 14, 0.85),
      _Cloud(130, 42, 22, 11, 0.85),
      _Cloud(70, 42, 22, 11, 0.85),
    ], color: const Color(0xFF2A3138));
    _drawClouds(c, [
      _Cloud(220, 68, 42, 12, 0.7),
      _Cloud(200, 62, 18, 9, 0.7),
    ], color: const Color(0xFF2E353C));
    c.drawCircle(
      const Offset(200, 22),
      1.2,
      Paint()..color = const Color(0xFFF0F3F7).withValues(alpha: 0.7),
    );
    _drawLeaf(
      c,
      const Offset(80, 120),
      const Color(0xFF5C4A40),
      rotateDeg: 25,
      opacity: 0.85,
    );
    _drawLeaf(
      c,
      const Offset(170, 138),
      const Color(0xFF5C4A40),
      rotateDeg: -15,
      opacity: 0.85,
    );
    _drawLeaf(
      c,
      const Offset(260, 108),
      const Color(0xFF5C4A40),
      rotateDeg: 40,
      opacity: 0.75,
    );
  }

  // -------------------------------------------------------------
  // STORM SEASON
  // -------------------------------------------------------------

  void _stormLight(Canvas c) {
    _drawClouds(c, [
      _Cloud(80, 40, 58, 16, 0.85),
      _Cloud(115, 30, 26, 13, 0.85),
      _Cloud(40, 30, 24, 12, 0.85),
    ], color: const Color(0xFF3F4D5E));
    _drawClouds(c, [
      _Cloud(280, 40, 62, 16, 0.85),
      _Cloud(320, 30, 28, 13, 0.85),
      _Cloud(240, 32, 24, 12, 0.85),
    ], color: const Color(0xFF46566A));
    _drawClouds(c, [
      _Cloud(200, 60, 50, 12, 0.7),
    ], color: const Color(0xFF3F4D5E));
    _drawRainLines(c, color: const Color(0xFFA0B6C8), opacity: 0.8);
    final rainbow = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          Color(0xB3F4A78C),
          Color(0xB3F6C45A),
          Color(0xB35BA38B),
          Color(0xB37A96AE),
          Color(0xB3A493C8),
        ],
      ).createShader(const Rect.fromLTWH(30, 130, 340, 30))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    c.drawPath(
      Path()
        ..moveTo(30, 160)
        ..quadraticBezierTo(200, 130, 370, 160),
      rainbow,
    );
  }

  void _stormDark(Canvas c) {
    _drawClouds(c, [
      _Cloud(80, 40, 58, 16, 0.9),
      _Cloud(115, 30, 26, 13, 0.9),
      _Cloud(40, 30, 24, 12, 0.9),
    ], color: const Color(0xFF0A111A));
    _drawClouds(c, [
      _Cloud(280, 40, 62, 16, 0.9),
      _Cloud(320, 30, 28, 13, 0.9),
      _Cloud(240, 32, 24, 12, 0.9),
    ], color: const Color(0xFF101A26));
    _drawClouds(c, [
      _Cloud(200, 60, 50, 12, 0.75),
    ], color: const Color(0xFF0A111A));
    // Jagged lightning bolt - two passes per the prototype: filled
    // warm-yellow body at opacity 0.85, plus a thin near-white stroke
    // at opacity 0.6 for the highlight along the path edges.
    final boltPath = Path()
      ..moveTo(220, 40)
      ..lineTo(210, 70)
      ..lineTo(220, 70)
      ..lineTo(205, 100)
      ..lineTo(224, 70)
      ..lineTo(214, 70)
      ..lineTo(224, 40)
      ..close();
    c.drawPath(
      boltPath,
      Paint()..color = const Color(0xFFF6E89A).withValues(alpha: 0.85),
    );
    c.drawPath(
      boltPath,
      Paint()
        ..color = const Color(0xFFFFFAD0).withValues(alpha: 0.6)
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke,
    );
    _drawRainLines(c, color: const Color(0xFF6F87A0), opacity: 0.85);
  }

  // -------------------------------------------------------------
  // Drawing helpers
  // -------------------------------------------------------------

  void _drawSunDisc(Canvas c, Offset center, double r, Color color) {
    c.drawCircle(center, r, Paint()..color = color);
  }

  void _drawSunGlow(Canvas c, Offset center, double r, double opacity) {
    final gradient = RadialGradient(
      colors: <Color>[
        sun1.withValues(alpha: opacity),
        sun2.withValues(alpha: opacity * 0.55),
        sun2.withValues(alpha: 0),
      ],
      stops: const <double>[0.0, 0.55, 1.0],
    );
    final rect = Rect.fromCircle(center: center, radius: r);
    c.drawCircle(center, r, Paint()..shader = gradient.createShader(rect));
  }

  void _drawSunWithRays(
    Canvas c, {
    required Offset center,
    required double glowR,
    required double coreR,
    required double midR,
    required int rayCount,
    required double rayInnerR,
    required double rayOuterR,
    required double rayOpacity,
  }) {
    _drawSunGlow(c, center, glowR, 0.65);
    final rayPaint = Paint()
      ..color = sun1.withValues(alpha: rayOpacity)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    c.save();
    c.translate(center.dx, center.dy);
    for (var i = 0; i < rayCount; i += 1) {
      c.save();
      c.rotate(i * 2 * math.pi / rayCount);
      c.drawLine(Offset(0, -rayInnerR), Offset(0, -rayOuterR), rayPaint);
      c.restore();
    }
    c.restore();
    c.drawCircle(center, midR, Paint()..color = sun2.withValues(alpha: 0.65));
    c.drawCircle(center, coreR, Paint()..color = sun1);
  }

  void _drawClouds(Canvas c, List<_Cloud> clouds, {required Color color}) {
    for (final cl in clouds) {
      c.drawOval(
        Rect.fromCenter(
          center: Offset(cl.cx, cl.cy),
          width: cl.rx * 2,
          height: cl.ry * 2,
        ),
        Paint()..color = color.withValues(alpha: cl.opacity),
      );
    }
  }

  void _drawButterfly(
    Canvas c,
    Offset at, {
    required Color colorA,
    required Color colorB,
  }) {
    final paintA = Paint()..color = colorA.withValues(alpha: 0.85);
    final paintB = Paint()..color = colorB.withValues(alpha: 0.85);
    c.drawOval(
      Rect.fromCenter(center: at.translate(-4, -2), width: 8, height: 6),
      paintA,
    );
    c.drawOval(
      Rect.fromCenter(center: at.translate(4, -2), width: 8, height: 6),
      paintA,
    );
    c.drawOval(
      Rect.fromCenter(center: at.translate(-3, 3), width: 6, height: 5),
      paintB,
    );
    c.drawOval(
      Rect.fromCenter(center: at.translate(3, 3), width: 6, height: 5),
      paintB,
    );
    c.drawLine(
      at.translate(0, -3),
      at.translate(0, 4),
      Paint()
        ..color = const Color(0xFF1F2937)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawStarfield(Canvas c, {required int count, required int seed}) {
    final star = Paint()..color = const Color(0xFFF0F3F7);
    for (var i = 0; i < count; i += 1) {
      final x = ((i * 37 + seed * 13) % 400).toDouble();
      final y = ((i * 23 + seed * 7) % 90 + 8).toDouble();
      final r = (i % 4 == 0) ? 1.2 : 0.6;
      final op = 0.4 + ((i * 17) % 6) / 10;
      c.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = star.color.withValues(alpha: op),
      );
    }
  }

  void _drawMoon(Canvas c, Offset center, double r) {
    final glow = RadialGradient(
      colors: <Color>[
        const Color(0xFFF0F3F7).withValues(alpha: 0.5),
        const Color(0xFFC9D2DE).withValues(alpha: 0.5),
        const Color(0xFFC9D2DE).withValues(alpha: 0),
      ],
      stops: const <double>[0, 0.55, 1.0],
    );
    final glowRect = Rect.fromCircle(center: center, radius: r + 12);
    c.drawCircle(center, r + 12, Paint()..shader = glow.createShader(glowRect));
    c.drawCircle(center, r, Paint()..color = const Color(0xFFF0EBD8));
    c.drawCircle(
      center.translate(-5, 4),
      2.2,
      Paint()..color = const Color(0xFFD5CFB8).withValues(alpha: 0.6),
    );
    c.drawCircle(
      center.translate(6, -5),
      1.6,
      Paint()..color = const Color(0xFFD5CFB8).withValues(alpha: 0.5),
    );
    c.drawCircle(
      center.translate(2, 8),
      1.2,
      Paint()..color = const Color(0xFFD5CFB8).withValues(alpha: 0.5),
    );
  }

  void _drawCrescentMoon(Canvas c, Offset center, double r) {
    c.drawCircle(center, r, Paint()..color = const Color(0xFFF0EBD8));
    final skyHue = isDark ? const Color(0xFF1B2942) : const Color(0xFFECDFD0);
    c.drawCircle(
      center.translate(-r * 0.35, 0),
      r * 0.95,
      Paint()..color = skyHue,
    );
  }

  void _drawFirefly(Canvas c, Offset at, {double opacity = 0.85}) {
    c.drawCircle(
      at,
      5,
      Paint()
        ..color = const Color(0xFFF6C45A).withValues(alpha: 0.18 * opacity),
    );
    c.drawCircle(
      at,
      2,
      Paint()
        ..color = const Color(0xFFF6C45A).withValues(alpha: 0.55 * opacity),
    );
    c.drawCircle(
      at,
      0.9,
      Paint()..color = const Color(0xFFFFF6D6).withValues(alpha: opacity),
    );
  }

  void _drawLeaf(
    Canvas c,
    Offset at,
    Color color, {
    required double rotateDeg,
    required double opacity,
  }) {
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(rotateDeg * math.pi / 180.0);
    c.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 6, height: 2.8),
      Paint()..color = color.withValues(alpha: opacity),
    );
    c.restore();
  }

  /// Paints a single "M"-shaped flying-creature squiggle - the
  /// prototype's `q 4 -3 7 0 q 3 -3 7 0` two-bump curve used for
  /// distant birds in the day tiers and bat silhouettes in
  /// thrivingDark. Defaults match the daytime bird styling
  /// (theme-text colour, opacity 0.35); callers override [color] and
  /// [opacity] for the bat variant.
  void _drawBirdStroke(
    Canvas c,
    Offset at, {
    Color? color,
    double opacity = 0.35,
    double strokeWidth = 1.4,
  }) {
    final paint = Paint()
      ..color = (color ?? const Color(0xFF1F2937)).withValues(alpha: opacity)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    // The prototype's path is two quadratic-bezier humps:
    //   M x y q 4 -3 7 0 q 3 -3 7 0
    // Translated to absolute coords from the start point [at].
    final path = Path()
      ..moveTo(at.dx, at.dy)
      ..relativeQuadraticBezierTo(4, -3, 7, 0)
      ..relativeQuadraticBezierTo(3, -3, 7, 0);
    c.drawPath(path, paint);
  }

  void _drawRainLines(
    Canvas c, {
    required Color color,
    required double opacity,
  }) {
    final rain = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 36; i += 1) {
      final x = ((i * 12) % 400).toDouble();
      final y = (60 + (i * 17) % 100).toDouble();
      c.drawLine(Offset(x, y), Offset(x - 3, y + 8), rain);
    }
  }

  @override
  bool shouldRepaint(covariant _TierAtmospherePainter old) =>
      old.tier != tier ||
      old.isDark != isDark ||
      old.sun1 != sun1 ||
      old.sun2 != sun2;
}

class _Cloud {
  const _Cloud(this.cx, this.cy, this.rx, this.ry, this.opacity);
  final double cx;
  final double cy;
  final double rx;
  final double ry;
  final double opacity;
}
