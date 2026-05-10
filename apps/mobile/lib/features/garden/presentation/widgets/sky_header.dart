import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/atmosphere.dart';
import '../../domain/entities/garden_state.dart';
import '../../domain/entities/plant_tier.dart';
import 'atmosphere_overlay.dart';
import 'plant_tier_group.dart';

/// 320 dp gradient sky header that doubles as the garden canvas.
/// Hosts the greeting + entries pill (top), sun (right), `CustomPaint`
/// ground (bottom 60 dp), the [PlantTierGroup] driven by
/// [GardenState.plantTier], an [AtmosphereOverlay] driven by
/// [GardenState.atmosphere], and the "View patterns →" footer row.
///
/// ADR-0010 redesign: the previous per-entry sprite dispatch (flowers /
/// buds / wilting plants / rain clouds) is gone. The canvas now reads
/// two signals on different timescales — the slow weekly EWMA (plant
/// tier) and the fast today-only mood mean (atmosphere overlay).
/// Plants are alive in every tier; rain belongs to the atmosphere
/// layer, not the plant layer.
class SkyHeader extends StatelessWidget {
  const SkyHeader({super.key, required this.state, required this.greetingName});

  /// Computed garden snapshot — drives both the plant tier and the
  /// atmosphere overlay.
  final GardenState state;

  /// First-name used in the greeting. Falls back to a friendly default
  /// when the user has not set a display name.
  final String greetingName;

  static const double _height = 320;

  /// Height of the plant row anchored above the ground line.
  static const double _plantRowHeight = 100;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mb = theme.extension<MbColors>()!;

    final dateLabel = _humanDate(DateTime.now());
    final entriesThisWeek = _countEntriesThisWeek(state.last7Days);

    return Semantics(
      container: true,
      label:
          'Garden canvas — ${state.plantTier.name} tier, '
          '${state.atmosphere.name} sky.',
      child: SizedBox(
        height: _height,
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
                      colors: _skyColorsFor(state.atmosphere, mb),
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
                  opacity: _sunOpacity(state.atmosphere),
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
              // Plant tier wrapped in atmosphere overlay. The plant
              // group is the bottom layer; the overlay paints rain /
              // sun rays above it. Plants are NOT children of the
              // overlay so rain visually falls AROUND them.
              Positioned(
                left: 0,
                right: 0,
                bottom: 30,
                height: _plantRowHeight,
                child: AtmosphereOverlay(
                  atmosphere: state.atmosphere,
                  child: PlantTierGroup(
                    tier: state.plantTier,
                    entryCount: entriesThisWeek,
                  ),
                ),
              ),
              // Top bar: greeting + entries-this-week pill.
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
              // Footer row inside the sky.
              Positioned(
                left: MoodBloomSpacing.pagePadding,
                right: MoodBloomSpacing.pagePadding,
                bottom: 14,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        _tierTagline(state),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: mb.textDim,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    _ViewPatternsPill(onTap: () => context.go('/analytics')),
                  ],
                ),
              ),
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
  static String _tierTagline(GardenState state) {
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

class _ViewPatternsPill extends StatelessWidget {
  const _ViewPatternsPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Semantics(
      button: true,
      label: 'View patterns',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusFull),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusFull),
            border: Border.all(
              color: primary.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Text(
            'View patterns →',
            style: theme.textTheme.labelMedium?.copyWith(
              color: primary,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the two-layer ground + grass blades along the horizon.
/// Reproduces the prototype's `viewBox="0 0 400 320"` paths in Flutter.
class _GroundPainter extends CustomPainter {
  _GroundPainter({
    required this.ground,
    required this.ground2,
    required this.grass,
  });

  final Color ground;
  final Color ground2;
  final Color grass;

  @override
  void paint(Canvas canvas, Size size) {
    // Map prototype's 400-wide viewBox onto the actual width.
    final scale = size.width / 400.0;
    canvas.save();
    canvas.scale(scale, scale);

    // Ground layer 1.
    final p1 = Path()
      ..moveTo(0, 260)
      ..cubicTo(80, 248, 160, 272, 240, 258)
      ..cubicTo(320, 246, 380, 268, 400, 260)
      ..lineTo(400, 320)
      ..lineTo(0, 320)
      ..close();
    canvas.drawPath(p1, Paint()..color = ground);

    // Ground layer 2 — slightly lower wave, 70% opacity.
    final p2 = Path()
      ..moveTo(0, 280)
      ..cubicTo(80, 270, 160, 288, 240, 278)
      ..cubicTo(320, 270, 380, 286, 400, 280)
      ..lineTo(400, 320)
      ..lineTo(0, 320)
      ..close();
    canvas.drawPath(p2, Paint()..color = ground2.withValues(alpha: 0.7));

    // 22 grass blades along the horizon.
    final grassPaint = Paint()
      ..color = grass.withValues(alpha: 0.6)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 22; i += 1) {
      final x = 8 + i * 18.0;
      final y = 260 + (i % 3) * 4.0;
      canvas.drawLine(Offset(x, y), Offset(x + 2, y - 8), grassPaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GroundPainter old) =>
      old.ground != ground || old.ground2 != ground2 || old.grass != grass;
}
