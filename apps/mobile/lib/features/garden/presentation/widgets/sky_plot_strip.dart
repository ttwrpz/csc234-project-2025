import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../mood/domain/entities/mood_entry.dart';
import '../../../mood/domain/entities/mood_type.dart';
import '../../../mood/presentation/widgets/mood_kind_adapter.dart';
import '../../domain/entities/plant_tier.dart';

/// 7 narrow daily plots that line the bottom of the [SkyHeader]. Each
/// plot stacks an optional `+N` overflow pill, a mood-keyed mini-plant
/// cluster (front row up to 3 plants, back row up to 2 plants at 78% /
/// 62% scale), and a day-letter label. Ports the prototype's inline
/// `Plant` + `SkyHeader` columns one-for-one - stem heights scale with
/// intensity, the per-tier `heightBoost` modulates the plant scale, and
/// the mini-plant geometry varies per mood.
///
/// Pure presentation - the caller passes [weekEntries] + the
/// Monday-aligned [weekStart] and the strip buckets entries by day.
class SkyPlotStrip extends StatelessWidget {
  const SkyPlotStrip({
    super.key,
    required this.weekEntries,
    required this.weekStart,
    required this.tier,
    this.compact = false,
    this.labelColor,
    this.labelOpacity = 0.7,
    this.darkOverlay = false,
    this.showDayLabels = true,
    this.onPlantTap,
    this.onOverflowTap,
  });

  /// When `false`, the per-day weekday letters are hidden. The home
  /// SkyHeader keeps them; the harvest history mini-garden hides them
  /// (it's a snapshot, not a calendar).
  final bool showDayLabels;

  /// Tapping a plant dispatches its [MoodEntry] - the home strip wires
  /// this to open the entry-detail sheet so the user can see which
  /// flower maps to which entry. Null leaves plants non-interactive
  /// (harvest snapshots).
  final void Function(MoodEntry entry)? onPlantTap;

  /// Tapping a day's `+N` overflow pill dispatches that day + its full
  /// entry list - the home strip wires this to the day-entries sheet.
  /// Null leaves the pill non-interactive.
  final void Function(DateTime day, List<MoodEntry> entries)? onOverflowTap;

  /// All entries falling within the active week. Need not be sorted;
  /// the strip buckets by `createdAt.toLocal()` local-midnight.
  final List<MoodEntry> weekEntries;

  /// Local-midnight Monday of the active week. The 7 plots are
  /// `weekStart`, `weekStart + 1d`, ..., `weekStart + 6d`.
  final DateTime weekStart;

  /// Plant-height boost source. Flourishing reads larger; Storm Season
  /// reads more contracted but plants are still rendered (alive in
  /// every tier - the "weather is around them, not damage to them"
  /// rule from CLAUDE.md).
  final PlantTier tier;

  /// Phone-class compaction. Pulls stem heights down ~16dp and font
  /// sizes down ~1dp so the strip fits a 320dp SkyHeader without
  /// overlapping the title above it.
  final bool compact;

  /// Day-label color override. Defaults to the theme's text color.
  /// Storm Season / dark themes pass white so labels stay legible over
  /// a deep sky.
  final Color? labelColor;

  /// Day-label opacity. Storm Season uses ~0.85 (high contrast over
  /// dark sky); other tiers use the default 0.7.
  final double labelOpacity;

  /// When `true`, the overflow `+N` pill switches to the dark sky
  /// variant (translucent white-on-dark instead of dark-on-white). Set
  /// this when the SkyHeader's gradient lands a deep navy / storm
  /// behind the strip.
  final bool darkOverlay;

  /// Maximum plants per day before the overflow pill kicks in. 3 in
  /// the front row + 2 in the back row = 5 visible.
  static const int _maxFront = 3;
  static const int _maxBack = 2;
  static const int _maxTotal = _maxFront + _maxBack;

  /// Per-tier plant-height boost. Flourishing pushes up 10%; Storm
  /// Season pulls back to 65%. Plants are still rendered with full
  /// stem + petals at every boost.
  static double heightBoostFor(PlantTier tier) => switch (tier) {
    PlantTier.flourishing => 1.10,
    PlantTier.thriving => 1.0,
    PlantTier.resting => 0.85,
    PlantTier.weathering => 0.80,
    PlantTier.stormSeason => 0.65,
  };

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final palette = Theme.of(context).extension<MbMoodPalette>()!;
    final buckets = _bucketByDay(weekEntries, weekStart);
    final boost = heightBoostFor(tier);
    final labelTint = labelColor ?? mb.text;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        for (var i = 0; i < 7; i += 1)
          Expanded(
            child: _DayPlot(
              date: weekStart.add(Duration(days: i)),
              entries: buckets[i],
              palette: palette,
              compact: compact,
              heightBoost: boost,
              labelColor: labelTint,
              labelOpacity: labelOpacity,
              darkOverlay: darkOverlay,
              showLabel: showDayLabels,
              onPlantTap: onPlantTap,
              onOverflowTap: onOverflowTap,
            ),
          ),
      ],
    );
  }

  /// Buckets [entries] into 7 lists keyed by `weekStart + dayIndex`,
  /// newest-first so the lead plant in each cluster represents the
  /// most-recent entry.
  static List<List<MoodEntry>> _bucketByDay(
    List<MoodEntry> entries,
    DateTime weekStart,
  ) {
    final out = List<List<MoodEntry>>.generate(7, (_) => <MoodEntry>[]);
    for (final e in entries) {
      final local = e.createdAt.toLocal();
      final dayKey = DateTime(local.year, local.month, local.day);
      final diff = dayKey.difference(weekStart).inDays;
      if (diff < 0 || diff > 6) continue;
      out[diff].add(e);
    }
    for (final list in out) {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return out;
  }
}

class _DayPlot extends StatelessWidget {
  const _DayPlot({
    required this.date,
    required this.entries,
    required this.palette,
    required this.compact,
    required this.heightBoost,
    required this.labelColor,
    required this.labelOpacity,
    required this.darkOverlay,
    required this.showLabel,
    this.onPlantTap,
    this.onOverflowTap,
  });

  final DateTime date;
  final List<MoodEntry> entries;
  final MbMoodPalette palette;
  final bool compact;
  final double heightBoost;
  final Color labelColor;
  final double labelOpacity;
  final bool darkOverlay;
  final bool showLabel;
  final void Function(MoodEntry entry)? onPlantTap;
  final void Function(DateTime day, List<MoodEntry> entries)? onOverflowTap;

  static const List<String> _dayLetters = <String>[
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];

  @override
  Widget build(BuildContext context) {
    final baseH = compact ? 48.0 : 64.0;
    final perIntensity = compact ? 6.0 : 8.0;

    final visible = entries
        .take(SkyPlotStrip._maxTotal)
        .toList(growable: false);
    final overflow = (entries.length - visible.length).clamp(0, 99);

    final specs = <_PlantSpec>[];
    for (var i = 0; i < visible.length; i += 1) {
      final entry = visible[i];
      // Lead plant in the front row renders full-size; subsequent
      // front-row siblings scale to 78%; back-row plants to 62%.
      final sizeScale = i == 0
          ? 1.0
          : i < SkyPlotStrip._maxFront
          ? 0.78
          : 0.62;
      final h =
          (baseH + entry.intensity * perIntensity) * heightBoost * sizeScale;
      specs.add(
        _PlantSpec(
          entry: entry,
          height: h,
          inFrontRow: i < SkyPlotStrip._maxFront,
        ),
      );
    }
    final front = specs.where((s) => s.inFrontRow).toList(growable: false);
    final back = specs.where((s) => !s.inFrontRow).toList(growable: false);
    final maxH = specs.isEmpty
        ? (compact ? 16.0 : 20.0)
        : specs.map((s) => s.height).fold<double>(0, math.max);

    final overflowPillHeight = compact ? 14.0 : 16.0;
    final overflowTap = onOverflowTap;
    Widget pill = overflow > 0
        ? _OverflowPill(count: overflow, compact: compact, dark: darkOverlay)
        : const SizedBox.shrink();
    if (overflow > 0 && overflowTap != null) {
      pill = Semantics(
        button: true,
        label: '$overflow more entries this day',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => overflowTap(date, entries),
          child: pill,
        ),
      );
    }
    final pillSlot = SizedBox(height: overflowPillHeight, child: pill);

    final cluster = SizedBox(
      height: maxH,
      width: double.infinity,
      child: specs.isEmpty
          ? Center(
              child: SizedBox(
                width: compact ? 12 : 14,
                height: compact ? 12 : 14,
                child: CustomPaint(
                  painter: _EmptySeedlingPainter(
                    line: labelColor.withValues(alpha: 0.55),
                    grass: palette
                        .colorOf(MbMoodKind.calm)
                        .withValues(alpha: 0.7),
                  ),
                ),
              ),
            )
          : _PlantCluster(
              front: _arrangeLeadCenter(front),
              back: back,
              palette: palette,
              compact: compact,
              onPlantTap: onPlantTap,
            ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        pillSlot,
        cluster,
        if (showLabel) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            _dayLetters[(date.weekday - 1).clamp(0, 6)],
            style: MbFonts.nunito(
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w700,
              color: labelColor.withValues(alpha: labelOpacity),
              letterSpacing: 0.4,
            ),
          ),
        ],
      ],
    );
  }

  /// Mirrors the prototype's `frontArranged` shuffle: lead plant in
  /// the middle, second sibling to the left, third sibling to the right.
  /// Keeps a 3-plant cluster visually balanced around the lead.
  static List<_PlantSpec> _arrangeLeadCenter(List<_PlantSpec> front) {
    if (front.length <= 1) return front;
    final out = <_PlantSpec>[front[0]];
    for (var idx = 1; idx < front.length; idx += 1) {
      if (idx.isOdd) {
        out.insert(0, front[idx]);
      } else {
        out.add(front[idx]);
      }
    }
    return out;
  }
}

class _PlantSpec {
  const _PlantSpec({
    required this.entry,
    required this.height,
    required this.inFrontRow,
  });

  final MoodEntry entry;
  final double height;
  final bool inFrontRow;
}

class _PlantCluster extends StatelessWidget {
  const _PlantCluster({
    required this.front,
    required this.back,
    required this.palette,
    required this.compact,
    this.onPlantTap,
  });

  final List<_PlantSpec> front;
  final List<_PlantSpec> back;
  final MbMoodPalette palette;
  final bool compact;
  final void Function(MoodEntry entry)? onPlantTap;

  @override
  Widget build(BuildContext context) {
    // Front-row plant width. The back row renders at 78% of this so it
    // visually nestles behind without crowding the front row.
    final frontWidth = compact ? 22.0 : 28.0;
    final backWidth = frontWidth * 0.78;
    return Stack(
      alignment: Alignment.bottomCenter,
      children: <Widget>[
        if (back.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: compact ? 4 : 6,
            child: Opacity(
              opacity: 0.65,
              child: Transform.translate(
                offset: Offset(compact ? -6 : -8, 0),
                child: _Row(
                  specs: back,
                  width: backWidth,
                  palette: palette,
                  onPlantTap: onPlantTap,
                ),
              ),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _Row(
            specs: front,
            width: frontWidth,
            palette: palette,
            onPlantTap: onPlantTap,
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.specs,
    required this.width,
    required this.palette,
    this.onPlantTap,
  });

  final List<_PlantSpec> specs;
  final double width;
  final MbMoodPalette palette;
  final void Function(MoodEntry entry)? onPlantTap;

  @override
  Widget build(BuildContext context) {
    // FittedBox + BoxFit.scaleDown lets a 3-plant cluster shrink to
    // fit the narrow per-day column width without overflowing - at
    // the 800-wide tablet layout each column is ~58dp wide and a
    // natural 3 x 28dp row would overflow by ~25dp. scaleDown keeps
    // wider plots at their natural size.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.bottomCenter,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final spec in specs) _plant(spec),
        ],
      ),
    );
  }

  Widget _plant(_PlantSpec spec) {
    final tap = onPlantTap;
    final painted = SizedBox(
      width: width,
      height: spec.height,
      child: CustomPaint(
        painter: _MiniPlantPainter(
          mood: spec.entry.mood,
          intensity: spec.entry.intensity,
          color: palette.colorOf(spec.entry.mood.mbKind),
          grass: palette.colorOf(MbMoodKind.calm),
        ),
      ),
    );
    if (tap == null) return painted;
    // Tappable plant - opaque hit-test over the plant's box so the
    // user can tap a flower to open the entry it represents.
    return Semantics(
      button: true,
      label: '${spec.entry.mood.name} entry, open',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => tap(spec.entry),
        child: painted,
      ),
    );
  }
}

/// One-plant mini painter. Each mood draws a slightly different stem
/// path + a unique head decoration, mirroring the prototype's per-mood
/// stem character (`stems[kind]`). Intentionally simple geometry - the
/// strip plants are small (~28dp wide x 60..100dp tall) and read at a
/// glance, not as detailed flora.
class _MiniPlantPainter extends CustomPainter {
  const _MiniPlantPainter({
    required this.mood,
    required this.intensity,
    required this.color,
    required this.grass,
  });

  final MoodType mood;
  final int intensity;
  final Color color;
  final Color grass;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final stemBot = h;
    final stemTop = h * 0.28;

    final stemPaint = Paint()
      ..color = grass
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Per-mood stem path - mirrors the prototype's `stems[kind]` map.
    final stemPath = _stemPath(mood, cx, stemTop, stemBot, h);
    canvas.drawPath(stemPath, stemPaint);

    switch (mood) {
      case MoodType.happy:
        _paintHappy(canvas, cx, stemTop, h);
      case MoodType.calm:
        _paintCalm(canvas, cx, stemTop, h);
      case MoodType.okay:
        _paintOkay(canvas, cx, stemBot, h);
      case MoodType.sad:
        _paintSad(canvas, cx, stemTop, h);
      case MoodType.angry:
        _paintAngry(canvas, cx, stemTop, h);
      case MoodType.anxious:
        _paintAnxious(canvas, cx, stemTop);
    }
  }

  Path _stemPath(MoodType m, double cx, double top, double bot, double h) {
    switch (m) {
      case MoodType.happy:
        return Path()
          ..moveTo(cx, bot)
          ..quadraticBezierTo(cx - 1.2, (bot + top) / 2, cx, top + 2);
      case MoodType.calm:
        return Path()
          ..moveTo(cx, bot)
          ..lineTo(cx, top);
      case MoodType.okay:
        return Path()
          ..moveTo(cx, bot)
          ..lineTo(cx, top + h * 0.18);
      case MoodType.sad:
        return Path()
          ..moveTo(cx, bot)
          ..quadraticBezierTo(cx, (bot + top) / 2, cx - 7, top + 4);
      case MoodType.angry:
        return Path()
          ..moveTo(cx, bot)
          ..lineTo(cx + 2.5, bot - h * 0.30)
          ..lineTo(cx - 2, bot - h * 0.55)
          ..lineTo(cx + 1.5, top + 2);
      case MoodType.anxious:
        return Path()
          ..moveTo(cx, bot)
          ..lineTo(cx, top - 4);
    }
  }

  // Happy - two leaves + 10-petal sunflower head.
  void _paintHappy(Canvas c, double cx, double top, double h) {
    final leafPaint = Paint()..color = grass;
    _drawRotatedOval(
      c,
      cx: cx - 7,
      cy: h * 0.68,
      rx: 5,
      ry: 2.4,
      rotateDeg: -30,
      paint: leafPaint,
    );
    _drawRotatedOval(
      c,
      cx: cx + 7,
      cy: h * 0.52,
      rx: 5,
      ry: 2.4,
      rotateDeg: 30,
      paint: leafPaint,
    );
    c.save();
    c.translate(cx, top - 2);
    final petal = Paint()..color = color;
    for (var i = 0; i < 10; i += 1) {
      c.save();
      c.rotate(i * (2 * math.pi / 10));
      c.drawOval(
        Rect.fromCenter(center: const Offset(0, -6), width: 4, height: 9),
        petal,
      );
      c.restore();
    }
    final diskDark = HSLColor.fromColor(color).withLightness(0.30).toColor();
    c.drawCircle(Offset.zero, 4, Paint()..color = diskDark);
    c.drawCircle(
      const Offset(-1, -1),
      1.2,
      Paint()..color = color.withValues(alpha: 0.8),
    );
    c.restore();
  }

  // Calm - paired leaves at three heights + a small bud at the apex.
  void _paintCalm(Canvas c, double cx, double top, double h) {
    final leaf = Paint()..color = grass.withValues(alpha: 0.92);
    for (final y in const <double>[0.72, 0.55, 0.4]) {
      _drawRotatedOval(
        c,
        cx: cx - 5,
        cy: h * y,
        rx: 4.5,
        ry: 2,
        rotateDeg: -32,
        paint: leaf,
      );
      _drawRotatedOval(
        c,
        cx: cx + 5,
        cy: h * y,
        rx: 4.5,
        ry: 2,
        rotateDeg: 32,
        paint: leaf,
      );
    }
    c.drawOval(
      Rect.fromCenter(center: Offset(cx, top - 1), width: 6, height: 10),
      Paint()..color = color,
    );
    c.drawOval(
      Rect.fromCenter(center: Offset(cx, top - 1), width: 3, height: 7),
      Paint()..color = grass.withValues(alpha: 0.45),
    );
  }

  // Okay - tuft of grass blades growing from the ground. No flower head.
  void _paintOkay(Canvas c, double cx, double bot, double h) {
    final blades = const <double>[-10, -6, -2, 2, 6, 10];
    for (var i = 0; i < blades.length; i += 1) {
      final dx = blades[i];
      final blade = h * (0.4 + (i % 3) * 0.06);
      final sway = (i % 2 == 0) ? -3.0 : 3.0;
      final paint = Paint()
        ..color = (i % 2 == 0 ? grass : color).withValues(alpha: 0.85)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      c.drawPath(
        Path()
          ..moveTo(cx + dx, bot)
          ..quadraticBezierTo(
            cx + dx + sway,
            bot - blade / 2,
            cx + dx + sway * 1.5,
            bot - blade,
          ),
        paint,
      );
    }
  }

  // Sad - drooping bell flower + a small leaf + a falling droplet.
  void _paintSad(Canvas c, double cx, double top, double h) {
    c.save();
    c.translate(cx - 7, top + 4);
    final bell = Path()
      ..moveTo(-3.5, 0)
      ..quadraticBezierTo(-4.5, 7, 0, 7)
      ..quadraticBezierTo(4.5, 7, 3.5, 0)
      ..close();
    c.drawPath(bell, Paint()..color = color);
    final stamen = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    c.drawLine(const Offset(-1.5, 7), const Offset(0, 10), stamen);
    c.drawLine(const Offset(0, 10), const Offset(1.5, 7), stamen);
    c.restore();
    _drawRotatedOval(
      c,
      cx: cx + 4,
      cy: h * 0.7,
      rx: 4,
      ry: 2,
      rotateDeg: 20,
      paint: Paint()..color = grass,
    );
    // Droplet falling beside the bell.
    final dropletColor = color.withValues(alpha: 0.85);
    final droplet = Path()
      ..moveTo(cx + 8, h * 0.55)
      ..quadraticBezierTo(cx + 6, h * 0.62, cx + 8, h * 0.66)
      ..quadraticBezierTo(cx + 10, h * 0.62, cx + 8, h * 0.55)
      ..close();
    c.drawPath(droplet, Paint()..color = dropletColor);
  }

  // Angry - spiky leaves + thistle pod with 8 spikes.
  void _paintAngry(Canvas c, double cx, double top, double h) {
    final spike = Paint()..color = color.withValues(alpha: 0.88);
    c.drawPath(
      Path()
        ..moveTo(cx - 9, h * 0.72)
        ..lineTo(cx - 1, h * 0.68)
        ..lineTo(cx - 9, h * 0.62)
        ..close(),
      spike,
    );
    c.drawPath(
      Path()
        ..moveTo(cx + 9, h * 0.55)
        ..lineTo(cx + 1, h * 0.52)
        ..lineTo(cx + 9, h * 0.46)
        ..close(),
      spike,
    );
    c.save();
    c.translate(cx, top + 2);
    c.drawCircle(Offset.zero, 4, Paint()..color = color);
    final spikePaint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 8; i += 1) {
      c.save();
      c.rotate(i * (math.pi / 4));
      c.drawLine(const Offset(0, -4), const Offset(0, -8), spikePaint);
      c.restore();
    }
    c.restore();
  }

  // Anxious - pairs of wheat grains ascending the top of the stem + a
  // wispy fork at the apex.
  void _paintAnxious(Canvas c, double cx, double top) {
    final paint = Paint()..color = color.withValues(alpha: 0.92);
    for (var i = 0; i < 5; i += 1) {
      final dy = i * 4.0;
      _drawRotatedOval(
        c,
        cx: cx - 2.6,
        cy: top - 2 + dy,
        rx: 1.4,
        ry: 2.8,
        rotateDeg: -22,
        paint: paint,
      );
      _drawRotatedOval(
        c,
        cx: cx + 2.6,
        cy: top - 2 + dy,
        rx: 1.4,
        ry: 2.8,
        rotateDeg: 22,
        paint: paint,
      );
    }
    final wisp = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    c.drawLine(Offset(cx, top - 4), Offset(cx - 1.5, top - 10), wisp);
    c.drawLine(Offset(cx, top - 4), Offset(cx + 1.5, top - 10), wisp);
  }

  /// Draws an oval rotated [rotateDeg] degrees around its centre.
  static void _drawRotatedOval(
    Canvas c, {
    required double cx,
    required double cy,
    required double rx,
    required double ry,
    required double rotateDeg,
    required Paint paint,
  }) {
    c.save();
    c.translate(cx, cy);
    c.rotate(rotateDeg * math.pi / 180.0);
    c.drawOval(
      Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
      paint,
    );
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _MiniPlantPainter old) =>
      old.mood != mood ||
      old.intensity != intensity ||
      old.color != color ||
      old.grass != grass;
}

/// Tiny dotted "seedling cup" rendered when a day has no entries.
/// Mirrors the prototype's `EmptySeedling` SVG: a dashed half-cup arc
/// + a small two-leaf sprout. Sits subtle so empty days read as "still
/// fine" rather than "wilted slot".
class _EmptySeedlingPainter extends CustomPainter {
  const _EmptySeedlingPainter({required this.line, required this.grass});

  final Color line;
  final Color grass;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    // Dashed cup arc.
    final cup = Paint()
      ..color = line
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final cupPath = Path()
      ..moveTo(2, s * 0.5)
      ..quadraticBezierTo(s / 2, s * 0.4, s - 2, s * 0.5);
    _drawDashed(canvas, cupPath, cup, dashLength: 1.5, gapLength: 2);

    // Small sprout stem.
    canvas.drawLine(
      Offset(s / 2, s * 0.5),
      Offset(s / 2, s * 0.25),
      Paint()
        ..color = grass
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round,
    );
    // Two leaves.
    canvas.drawCircle(
      Offset(s / 2 - 1.5, s * 0.32),
      1.2,
      Paint()..color = grass.withValues(alpha: 0.7),
    );
    canvas.drawCircle(
      Offset(s / 2 + 1.5, s * 0.28),
      1.2,
      Paint()..color = grass.withValues(alpha: 0.7),
    );
  }

  /// Approximates SVG's `stroke-dasharray` by walking the path with a
  /// `PathMetric` and drawing alternating extracted segments.
  static void _drawDashed(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double dashLength,
    required double gapLength,
  }) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final next = distance + (draw ? dashLength : gapLength);
        if (draw) {
          final extract = metric.extractPath(
            distance,
            next.clamp(0.0, metric.length),
          );
          canvas.drawPath(extract, paint);
        }
        distance = next;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EmptySeedlingPainter old) =>
      old.line != line || old.grass != grass;
}

/// Translucent "+N" overflow pill rendered above the plant cluster on
/// days with more than 5 entries. The dark variant kicks in when the
/// sky behind the strip is deep navy / storm so the pill stays legible.
class _OverflowPill extends StatelessWidget {
  const _OverflowPill({
    required this.count,
    required this.compact,
    required this.dark,
  });

  final int count;
  final bool compact;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final bg = dark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.70);
    final fg = dark ? Colors.white : mb.text;
    final border = dark
        ? Colors.white.withValues(alpha: 0.30)
        : Colors.black.withValues(alpha: 0.18);
    return Center(
      child: Container(
        constraints: BoxConstraints(minWidth: compact ? 22 : 26),
        height: compact ? 14 : 16,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusFull),
          border: Border.all(color: border),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '+$count',
          style: MbFonts.nunito(
            fontSize: compact ? 9 : 10,
            fontWeight: FontWeight.w700,
            color: fg,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
