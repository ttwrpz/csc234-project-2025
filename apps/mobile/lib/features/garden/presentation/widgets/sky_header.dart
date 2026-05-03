import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../mood/domain/entities/mood_entry.dart';
import '../../../mood/domain/entities/mood_type.dart';
import 'flora_sprite.dart';
import 'rain_cloud.dart';

/// 320 dp gradient sky header that doubles as the garden canvas.
/// Hosts the greeting + streak pill (top), sun (right), `CustomPaint`
/// ground (bottom 60 dp), positioned flora and rain-cloud sprites, and
/// the "View patterns →" footer row.
///
/// All entry → sprite mapping happens here (the previous
/// `_GardenCanvas` dispatcher is folded in). The screen passes the raw
/// entry list and a few aggregate caps; the header owns the layout.
class SkyHeader extends StatelessWidget {
  const SkyHeader({
    super.key,
    required this.entries,
    required this.streakDays,
    required this.greetingName,
    this.maxPlants = 8,
    this.maxClouds = 3,
  });

  /// Most-recent-first list of entries to render. Caller is responsible
  /// for filtering by recency window (e.g. last 7 days) and total cap.
  final List<MoodEntry> entries;
  final int streakDays;

  /// First-name used in the greeting. Falls back to a friendly default
  /// when the user has not set a display name.
  final String greetingName;

  /// Cap on the number of flowers/buds/wilting plants positioned in
  /// the scene. Beyond this they're dropped (never crowded).
  final int maxPlants;

  /// Cap on the number of drifting rain clouds. The fourth-and-up
  /// cloud is dropped — three clouds is already a heavy sky.
  final int maxClouds;

  static const double _height = 320;

  /// Fixed plant-row y position — anchors the sprites' bottom-center
  /// pivot to the soil line.
  static const double _plantY = 258;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mb = theme.extension<MbColors>()!;

    final plants = <_PositionedSprite>[];
    final clouds = <_PositionedSprite>[];

    for (final e in entries) {
      final seed = e.id.hashCode.abs();
      // Negative @ intensity ≥ 4 → rain cloud.
      final isNegative =
          e.mood.category != MoodCategory.positive && e.mood != MoodType.okay;
      if (isNegative && e.intensity >= 4) {
        if (clouds.length >= maxClouds) continue;
        final idx = clouds.length;
        clouds.add(
          _PositionedSprite(
            x: (60 + (idx * 120) % 320).toDouble(),
            y: 80 + idx * 20,
            child: RainCloud(
              entryId: e.id,
              mood: e.mood,
              intensity: e.intensity,
              indexInScene: idx,
            ),
          ),
        );
        continue;
      }
      // Otherwise a plant of some kind.
      if (plants.length >= maxPlants) continue;
      final idx = plants.length;
      // x = 30 + (idx*50 + (seed*13)%340) % 340 — port of the
      // prototype's deterministic positioning.
      final x = (30 + (idx * 50 + (seed * 13) % 340) % 340).toDouble();
      final kind = floraKindFor(e.mood, e.intensity);
      late final Widget sprite;
      switch (kind) {
        case FloraKind.flower:
          sprite = Flower(
            mood: moodKindOf(e.mood),
            intensity: e.intensity,
            seed: seed,
          );
        case FloraKind.bud:
          sprite = Bud(mood: moodKindOf(e.mood), seed: seed);
        case FloraKind.wilt:
          sprite = WiltingPlant(
            mood: moodKindOf(e.mood),
            intensity: e.intensity.clamp(1, 3),
            seed: seed,
          );
      }
      plants.add(_PositionedSprite(x: x, y: _plantY, child: sprite));
    }

    final dateLabel = _humanDate(DateTime.now());

    return Semantics(
      container: true,
      label:
          'Sky header. ${plants.length} plants and ${clouds.length} '
          'passing clouds.',
      child: SizedBox(
        height: _height,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(MoodBloomSpacing.radiusSky),
            bottomRight: Radius.circular(MoodBloomSpacing.radiusSky),
          ),
          child: Stack(
            children: [
              // Sky gradient.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0, 0.55, 1],
                      colors: [mb.skyTop, mb.skyMid, mb.skyBot],
                    ),
                  ),
                ),
              ),
              // Sun, top-right.
              Positioned(
                top: 60,
                right: 34,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [mb.sun1, mb.sun2, mb.sun2.withValues(alpha: 0)],
                      stops: const [0, 0.7, 1],
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
              // Rain clouds layer.
              for (final c in clouds)
                Positioned(left: c.x, top: c.y, child: c.child),
              // Plant layer — sprites are 100×100 logical, anchor at
              // their bottom-center, so we left-shift by 50 to center on
              // their target x.
              for (final p in plants)
                Positioned(
                  left: p.x - 50,
                  top: p.y - 100,
                  child: SizedBox(width: 100, height: 100, child: p.child),
                ),
              // Top bar: greeting + streak pill.
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
                    _StreakPill(streakDays: streakDays),
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
                        '${plants.length} plant${plants.length == 1 ? '' : 's'}'
                        ' · ${clouds.length} passing '
                        'cloud${clouds.length == 1 ? '' : 's'}',
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

class _PositionedSprite {
  const _PositionedSprite({
    required this.x,
    required this.y,
    required this.child,
  });

  final double x;
  final double y;
  final Widget child;
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.streakDays});

  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

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
                '$streakDays day${streakDays == 1 ? '' : 's'}',
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
    // Vertical: prototype paints into a 320-tall box that matches our
    // SkyHeader height; if the rendered height differs we still paint
    // at the prototype's y coordinates (the gradient + sun absorb any
    // letterboxing).

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

    // Suppress lint about unused import for ui.ImageFilter (we use it
    // in the streak pill above; no-op here).
    assert(_groundHeight == 60);
  }

  static const double _groundHeight = 60;

  @override
  bool shouldRepaint(covariant _GroundPainter old) =>
      old.ground != ground || old.ground2 != ground2 || old.grass != grass;
}
