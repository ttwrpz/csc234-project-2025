import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../mood/domain/entities/mood_entry.dart';
import '../../domain/entities/atmosphere.dart';
import '../../domain/entities/flower_species.dart';
import '../../domain/entities/garden_state.dart';
import '../../domain/entities/plant_tier.dart';
import 'atmosphere_overlay.dart';
import 'garden_bed.dart';

/// 320 dp gradient sky header that doubles as the garden canvas.
/// Hosts the greeting + entries pill (top), sun (right), `CustomPaint`
/// ground (bottom 60 dp), a [GardenBed] driven by this week's mood
/// entries, an [AtmosphereOverlay] driven by [GardenState.atmosphere],
/// and the "View patterns →" footer row.
///
/// ADR-0010 redesign: the previous per-entry sprite dispatch (flowers /
/// buds / wilting plants / rain clouds) is gone. The canvas now reads
/// two signals on different timescales — the slow weekly EWMA (plant
/// tier) and the fast today-only mood mean (atmosphere overlay).
/// Plants are alive in every tier; rain belongs to the atmosphere
/// layer, not the plant layer.
///
/// v1.0 polish (2026-05-10): the prior `PlantTierGroup` + `_WeeklyFlowerScatter`
/// pair was replaced by a single entry-driven [GardenBed]. The bed paints
/// one full plant per entry (stem + leaves + petals at canvas scale) and
/// uses tier only as an ambient modulator (butterflies / cloud shadow /
/// lanterns AROUND the plants). Empty entries paints ground+grass only,
/// closing the wipe-still-shows-3-flowers bug at the source.
class SkyHeader extends StatelessWidget {
  const SkyHeader({
    super.key,
    required this.state,
    required this.greetingName,
    this.recentEntries = const <MoodEntry>[],
    this.height = 320,
    this.onFlowerTap,
    this.speciesAccent,
  });

  /// Computed garden snapshot — drives both the plant tier and the
  /// atmosphere overlay.
  final GardenState state;

  /// First-name used in the greeting. Falls back to a friendly default
  /// when the user has not set a display name.
  final String greetingName;

  /// This week's mood entries (any order). Forwarded to [GardenBed],
  /// which sorts newest-first internally, caps at 6, and paints one
  /// full plant per entry. Empty list yields a bare bed (ground +
  /// grass only) so the wipe-account-data flow no longer leaves
  /// ghost flowers behind.
  ///
  /// User feedback v1.0 polish (2026-05-10): the previous design relied
  /// on a tier-driven `PlantTierGroup` that painted 3 generic buds even
  /// when the user had zero entries, plus a `_WeeklyFlowerScatter` overlay
  /// of 22 dp head-only sprites. Replacing both with an entry-driven
  /// [GardenBed] makes the per-entry render the canonical visual and
  /// closes the empty-state regression at the source.
  final List<MoodEntry> recentEntries;

  /// Total canvas height. 320 dp is the phone-class default; desktop
  /// callers pass ~420 dp so the canvas reads as a hero on a wide
  /// viewport instead of a thin band.
  final double height;

  /// Per-flower tap router — TC-7 (S5 flower-skin Day 1). Forwarded
  /// to the inner [GardenBed]; null disables the overlay so non-
  /// interactive call-sites (harvest archive thumbnails) keep the
  /// canvas tap-free.
  final void Function(MoodEntry entry)? onFlowerTap;

  /// Per-species accent override — TC-6 (flower-skin Day 1).
  /// Forwarded to the inner [GardenBed]'s painter so plants whose
  /// species has an alternate skin selected render with the chosen
  /// petal tint. Null leaves the species' built-in palette intact.
  final Map<FlowerSpecies, Color>? speciesAccent;

  /// Height of the garden bed anchored above the ground line. Bumped
  /// from 100 dp to 140 dp so the tallest species (sunflower at ~110 dp
  /// incl. petals) renders at full height without clipping.
  static const double _plantRowHeight = 140;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mb = theme.extension<MbColors>()!;

    final dateLabel = _humanDate(DateTime.now());
    final entriesThisWeek = _countEntriesThisWeek(state.last7Days);
    // Tier-gated atmosphere (see _atmosphereForTier docstring) — used
    // for the sky gradient, sun dim and the rain overlay so all three
    // weather signals stay consistent with the plant tier.
    final atmosphere = _atmosphereForTier(state.plantTier, state.atmosphere);

    return Semantics(
      container: true,
      label:
          'Garden canvas — ${state.plantTier.name} tier, '
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
              // Sky gradient. Atmosphere-aware: the base palette comes
              // from the theme's MbColors (warm-cream in light, cool
              // navy in dark), and a per-atmosphere blend pulls the
              // sky toward grey on lightRain and a deep storm-blue on
              // storm so the entire canvas — not just the plant-row
              // overlay — reads as rainy. Sunny atmospheres pass the
              // theme palette through unchanged.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0, 0.55, 1],
                      colors: _skyColorsFor(atmosphere, mb),
                    ),
                  ),
                ),
              ),
              // Sun, top-right. Dimmed under rain/storm so the weather
              // treatment reads. Plants stay vivid in every tier.
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
              // Garden bed at its dedicated row above the ground line.
              // No longer wrapped in the AtmosphereOverlay — rain now
              // falls across the full canvas via the dedicated
              // Positioned.fill layer below. v1.0 polish (2026-05-10):
              // user reported rain only filled half the canvas because
              // the overlay was scoped to the 140dp bed slot. Splitting
              // the layers fixes the half-canvas rain at the source.
              Positioned(
                left: 0,
                right: 0,
                bottom: 30,
                height: _plantRowHeight,
                child: LayoutBuilder(
                  builder: (context, constraints) => Center(
                    child: GardenBed(
                      entries: recentEntries,
                      tier: state.plantTier,
                      size: Size(constraints.maxWidth, _plantRowHeight),
                      onFlowerTap: onFlowerTap,
                      speciesAccent: speciesAccent,
                    ),
                  ),
                ),
              ),
              // Atmosphere overlay covers the FULL sky canvas. Rain
              // falls from the top of the canvas through to the ground
              // line so storm reads as a whole-sky event, not a
              // ground-level mist.
              //
              // v1.0 polish (2026-05-10): the atmosphere is gated by
              // plant tier so the user never sees rain over a
              // Resting/Thriving/Flourishing tier. The original spec
              // computed atmosphere from `avg_S_today` independently
              // of the weekly EWMA, but the resulting "rain on Resting
              // plants" reads as a contradiction in the UI. We pin
              // the atmosphere to the tier — rain only when the bed
              // is also visually weathering.
              Positioned.fill(
                child: AtmosphereOverlay(
                  atmosphere: atmosphere,
                  child: const SizedBox.expand(),
                ),
              ),
              // Top bar: greeting + entries-this-week pill.
              // v1.0 polish (2026-05-10): the floating tier-tagline
              // and "View patterns" pill that previously sat in the
              // bottom of the canvas were moved out into a dedicated
              // section below the SkyHeader (see [GardenSummaryRow])
              // so the canvas reads as a clean visual hero.
              Positioned(
                top: 16,
                left: MoodBloomSpacing.pagePadding,
                right: MoodBloomSpacing.pagePadding,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: mb.textDim,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Hello, $greetingName',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: mb.text,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _EntriesPill(entriesThisWeek: entriesThisWeek),
                  ],
                ),
              ),
              // (Tagline + View patterns pill moved out — see
              // GardenSummaryRow rendered below the SkyHeader.)
            ],
          ),
        ),
      ),
    );
  }

  static int _countEntriesThisWeek(List<DayScore> last7Days) {
    var total = 0;
    for (final d in last7Days) {
      total += d.entryCount;
    }
    return total;
  }

  /// Reconciles the use case's [Atmosphere] (computed from today's
  /// mean) with the bed's [PlantTier]. Negative tiers may keep the
  /// raw atmosphere (rain belongs there visually); positive/neutral
  /// tiers force a sunny atmosphere so the user never sees rain over
  /// flowering plants. v1.0 polish (2026-05-10) — addresses "why is
  /// it raining but the tier is Resting?" feedback.
  static Atmosphere _atmosphereForTier(PlantTier tier, Atmosphere raw) {
    switch (tier) {
      case PlantTier.stormSeason:
      case PlantTier.weathering:
        return raw;
      case PlantTier.resting:
        // Resting is a quiet baseline — rain reads as inconsistent.
        // Soften lightRain → calmSunny; storm → lightRain at most.
        return switch (raw) {
          Atmosphere.storm => Atmosphere.lightRain,
          Atmosphere.lightRain => Atmosphere.calmSunny,
          _ => raw,
        };
      case PlantTier.thriving:
      case PlantTier.flourishing:
        // Positive tiers never show rain — the bed is in bloom.
        return switch (raw) {
          Atmosphere.storm || Atmosphere.lightRain => Atmosphere.calmSunny,
          _ => raw,
        };
    }
  }

  /// Sun visibility tapers in rainy atmospheres so the weather
  /// treatment reads. Plants stay visible in every tier — only the
  /// sun fades.
  static double _sunOpacity(Atmosphere a) => switch (a) {
    Atmosphere.calmSunny || Atmosphere.brightSunny => 1.0,
    Atmosphere.lightRain => 0.40,
    Atmosphere.storm => 0.10,
  };

  /// Sky gradient colours per atmosphere. Sunny atmospheres pass the
  /// theme's `MbColors` palette through unchanged. Rainy atmospheres
  /// blend the palette toward stormy greys so the whole canvas — not
  /// just the falling drops + plant-row overlay — reads as rainy.
  /// User feedback (v1.0 polish) was that subtle drop animations on
  /// the warm cream sky were easy to miss; this pulls the sky itself
  /// into the weather.
  static List<Color> _skyColorsFor(Atmosphere a, MbColors mb) {
    switch (a) {
      case Atmosphere.calmSunny:
      case Atmosphere.brightSunny:
        return [mb.skyTop, mb.skyMid, mb.skyBot];
      case Atmosphere.lightRain:
        return [
          Color.lerp(mb.skyTop, const Color(0xFFB6C0CC), 0.55)!,
          Color.lerp(mb.skyMid, const Color(0xFFC8D2DD), 0.45)!,
          Color.lerp(mb.skyBot, const Color(0xFFD8DFE7), 0.35)!,
        ];
      case Atmosphere.storm:
        return [
          Color.lerp(mb.skyTop, const Color(0xFF3D454F), 0.78)!,
          Color.lerp(mb.skyMid, const Color(0xFF555F6A), 0.65)!,
          Color.lerp(mb.skyBot, const Color(0xFF8590A0), 0.45)!,
        ];
    }
  }

  /// Compassionate, no-streak-shaming caption per the plant tier and
  /// total entry count. Empty-state copy ("plant your first mood")
  /// kicks in when the user has logged nothing at all. Matches the
  /// no-wilt copy rule in CLAUDE.md.
  ///
  /// Public so [GardenSummaryRow] (in `garden_summary_row.dart`) can
  /// render the same tagline in the page flow below the canvas.
  static String tierTagline(GardenState state) {
    if (state.isEmpty) return 'Plant your first mood — a fresh canvas awaits.';
    return switch (state.plantTier) {
      PlantTier.flourishing => 'A flourishing week.',
      PlantTier.thriving => 'Thriving — the garden has grown.',
      PlantTier.resting => 'Resting — quiet days for the soil.',
      PlantTier.weathering => 'Weathering a soft week — roots hold.',
      PlantTier.stormSeason => 'Storms pass. The roots hold.',
    };
  }

  static String _humanDate(DateTime now) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[now.weekday - 1]}, '
        '${months[now.month - 1]} ${now.day}';
  }
}

class _EntriesPill extends StatelessWidget {
  const _EntriesPill({required this.entriesThisWeek});

  final int entriesThisWeek;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final label = entriesThisWeek == 1
        ? '1 entry this week'
        : '$entriesThisWeek entries this week';

    return ClipRRect(
      borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusFull),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusFull),
            border: Border.all(
              color: primary.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌿', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints the two-layer ground + grass blades along the horizon.
///
/// v1.0 polish (2026-05-10): rewritten to anchor the horizon at the
/// bed's groundY (canvas.height - 36) instead of the prototype's
/// hard-coded `viewBox y=260`. Previously the painter used
/// `canvas.scale(width/400)` which meant the y-coords scaled with
/// width — at 800 dp wide the ground rendered at `y=520` and fell
/// off-canvas, leaving flowers floating above empty sky. Anchoring to
/// the bottom keeps the ground line aligned with the [GardenBed]'s
/// groundY at every canvas size.
class _GroundPainter extends CustomPainter {
  _GroundPainter({
    required this.ground,
    required this.ground2,
    required this.grass,
  });

  final Color ground;
  final Color ground2;
  final Color grass;

  /// Y offset of the horizon from the bottom of the canvas. Matches
  /// [SkyHeader._plantRowHeight] minus the bed's internal `groundY`
  /// inset (6 dp) and the bed's `Positioned bottom` offset (30 dp) —
  /// the flowers' visible base sits exactly here.
  static const double _horizonFromBottom = 36;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final horizonY = size.height - _horizonFromBottom;

    // Ground layer 1 — gentle wave around the horizon line.
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

    // Ground layer 2 — slightly lower wave, semi-transparent for depth.
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

    // Grass blades along the horizon. Density scales with canvas width.
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
