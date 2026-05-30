import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../mood/domain/entities/mood_entry.dart';
import '../../../mood/presentation/widgets/mood_kind_adapter.dart';
import '../../data/providers.dart' show resolvedPlantSkinProvider;
import '../../domain/entities/flower_species.dart';
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
    required this.compact,
    this.onPlantTap,
  });

  final List<_PlantSpec> front;
  final List<_PlantSpec> back;
  final bool compact;
  final void Function(MoodEntry entry)? onPlantTap;

  @override
  Widget build(BuildContext context) {
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
                child: _Row(specs: back, onPlantTap: onPlantTap),
              ),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _Row(specs: front, onPlantTap: onPlantTap),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.specs, this.onPlantTap});

  final List<_PlantSpec> specs;
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
    final plant = _SkinnedPlant(entry: spec.entry, height: spec.height);
    if (tap == null) return plant;
    // Tappable plant - opaque hit-test over the plant's box so the
    // user can tap a flower to open the entry it represents.
    return Semantics(
      button: true,
      label: '${spec.entry.mood.name} entry, open',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => tap(spec.entry),
        child: plant,
      ),
    );
  }
}

/// A single strip plant that honours the currently-equipped skin. Reads
/// [resolvedPlantSkinProvider] for the entry's species and renders the
/// resolved shape style via [MbSkinPlant] - so the home strip + harvest
/// snapshots reflect the global OR per-species skin the user equipped
/// (falling back to the classic meadow shape).
///
/// The box is ASPECT-LOCKED to the painter's 36:60 viewBox: the width is
/// derived from [height] so `MbSkinPlant` scales uniformly. A non-square
/// box would scale the design's x and y independently, squashing the
/// bloom into an oval and shifting the stem base off the ground line.
/// The enclosing row's `FittedBox(scaleDown)` shrinks the whole cluster
/// to fit the narrow day column, so locking the aspect here never
/// overflows.
class _SkinnedPlant extends ConsumerWidget {
  const _SkinnedPlant({required this.entry, required this.height});

  final MoodEntry entry;
  final double height;

  /// Painter viewBox aspect (width / height) from `MbSkinPlant` (36x60).
  static const double _aspect = 36 / 60;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = Theme.of(context).extension<MbMoodPalette>()!;
    final mood = entry.mood.mbKind;
    final species = FlowerSpecies.forMood(entry.mood);
    final resolved = ref.watch(resolvedPlantSkinProvider(species));
    final accent = resolved.accentArgb;
    final color = accent != null ? Color(accent) : palette.colorOf(mood);
    return MbSkinPlant(
      skinId: resolved.style,
      mood: mood,
      intensity: entry.intensity,
      color: color,
      size: Size(height * _aspect, height),
    );
  }
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
    // Use the dark treatment for storm skies (`dark`) OR whenever the app
    // is in dark mode. The light variant's near-white fill washes out the
    // light `mb.text` glyph under a dark theme - the "too bright" bug.
    final isDark = dark || Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.70);
    final fg = isDark ? Colors.white : mb.text;
    final border = isDark
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
