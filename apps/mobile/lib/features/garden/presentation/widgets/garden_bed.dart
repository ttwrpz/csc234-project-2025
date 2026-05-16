import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../mood/domain/entities/mood_entry.dart';
import '../../domain/entities/flower_species.dart';
import '../../domain/entities/plant_tier.dart';

/// Real flower garden — replaces the prior `PlantTierGroup`. Renders one
/// full plant per recent mood entry, each with stem + leaves + petals
/// drawn at canvas scale. The garden visualisation is the most
/// load-bearing surface of the app, so the painters are intentionally
/// detailed: an 18-ray sunflower head with a brown disk, a 12-petal
/// daisy on a slender stem, a forget-me-not cluster of 5 flowers on
/// branched stems, a 4-petal poppy with stamens around a dark navy
/// centre, a fern with 10 alternating pinnae, and a lavender stalk
/// with 8 stacked bell buds.
///
/// **Empty `entries` paints ground+grass only** — no flowers, no buds,
/// nothing. Fixes the wipe-still-shows-3-flowers bug at the source
/// (the old `_paintResting` painted 3 buds unconditionally).
///
/// Plants are species-driven from the entries' moods (via
/// [FlowerSpecies.forMood]). Tier modulates AMBIENT extras only —
/// butterflies on flourishing, lanterns on storm season, a soft cloud
/// shadow on weathering. The plants themselves never change shape per
/// tier; tier is the weather around them, not damage to them
/// (ADR-0010 §4 "plants never die").
///
/// Caps at 6 plants to keep the bed readable. When entries > 6 the
/// most-recent six are shown.
class GardenBed extends StatefulWidget {
  const GardenBed({
    super.key,
    required this.entries,
    required this.tier,
    this.size = const Size(320, 140),
    this.showOverflowBadge = false,
    this.onFlowerTap,
    this.speciesAccent,
    @visibleForTesting this.animate = true,
  });

  /// This week's mood entries (any order). Internally the bed sorts
  /// by `createdAt` desc and takes the first six.
  final List<MoodEntry> entries;

  /// Ambient modifier — adds butterflies, cloud shadow, or lanterns
  /// AROUND the plants. Never changes the plants themselves.
  final PlantTier tier;

  /// Logical size of the bed. Default 320×140 — ~40dp taller than the
  /// prior PlantTierGroup so the tallest species (sunflower at 110dp)
  /// renders without clipping.
  final Size size;

  /// `@visibleForTesting`: callers in production never set this. Tests
  /// pass `false` so frame-deterministic goldens reproduce.
  final bool animate;

  /// Per-flower tap router — TC-7 (S5 — flower skin system Day 1).
  /// When non-null, the bed renders invisible hot-spots on top of each
  /// painted flower (using the same x-placement math the painter uses
  /// internally). Tapping a hot-spot dispatches the corresponding
  /// [MoodEntry] back to the caller, which typically opens
  /// `PerFlowerDetailModal`. Null disables the overlay entirely so
  /// existing call-sites (history thumbnails, harvest archive) keep
  /// their non-interactive canvas semantics.
  final void Function(MoodEntry entry)? onFlowerTap;

  /// Per-species petal-accent override — TC-6 (flower skin system).
  /// Maps a species to the accent colour the user picked for that
  /// species' alternate skin. Absent species fall back to the species'
  /// built-in default colour. The default-skin path keeps the existing
  /// look exactly; only alternates shift hue.
  ///
  /// Past harvested gardens never receive this override — the archive
  /// rendering surface passes `null` so historical weeks keep their
  /// snapshot look. Only the live home canvas opts in.
  final Map<FlowerSpecies, Color>? speciesAccent;

  /// When `true`, render a small "+N more" pill in the top-right
  /// corner whenever `entries.length > _maxPlants` so the user knows
  /// the bed is truncating their archive. Defaults to `false` so the
  /// live home garden stays clean (the cap is a soft "garden vs.
  /// thicket" rule there); harvest-archive surfaces opt in.
  final bool showOverflowBadge;

  /// Cap on the number of plants the bed can render at once. v1.0
  /// polish (2026-05-10): bumped from 6 → 25 after user feedback that
  /// a week of frequent logs (multiple entries per day) was being
  /// truncated mid-week. 25 fits comfortably across the canvas at
  /// desktop width without crowding; the per-entry x-jitter still
  /// keeps individual plants readable.
  static const int _maxPlants = 25;

  @override
  State<GardenBed> createState() => _GardenBedState();

  static String _semanticsLabel(List<MoodEntry> shown, PlantTier tier) {
    if (shown.isEmpty) {
      return 'Empty garden bed — ${tier.name} tier. Log a mood to plant '
          'your first flower.';
    }
    final species = shown
        .map((e) => FlowerSpecies.forMood(e.mood).name)
        .toSet()
        .join(', ');
    return 'Garden bed — ${shown.length} plant${shown.length == 1 ? "" : "s"} '
        '($species). ${tier.name} tier.';
  }
}

class _GardenBedState extends State<GardenBed> with TickerProviderStateMixin {
  AnimationController? _ctrl;

  @override
  void initState() {
    super.initState();
    _maybeStart();
  }

  @override
  void didUpdateWidget(covariant GardenBed old) {
    super.didUpdateWidget(old);
    if (widget.animate != old.animate) {
      _ctrl?.dispose();
      _ctrl = null;
      _maybeStart();
    }
  }

  void _maybeStart() {
    if (!widget.animate) return;
    // 6-second loop: long enough for the sway to read as gentle and
    // the butterfly drift to feel unhurried; short enough that two
    // butterflies don't drift to the same spot too often.
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final sorted = [...widget.entries]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final shown = sorted.take(GardenBed._maxPlants).toList(growable: false);
    final hidden = sorted.length - shown.length;

    _GardenBedPainter buildPainter(double phase) => _GardenBedPainter(
      entries: shown,
      tier: widget.tier,
      palette: mb,
      phase: phase,
      speciesAccent: widget.speciesAccent,
    );

    final canvas = SizedBox(
      width: widget.size.width,
      height: widget.size.height,
      child: _ctrl == null
          ? CustomPaint(painter: buildPainter(0))
          : AnimatedBuilder(
              animation: _ctrl!,
              builder: (_, _) =>
                  CustomPaint(painter: buildPainter(_ctrl!.value)),
            ),
    );

    final overlayChildren = <Widget>[];
    if (widget.onFlowerTap != null && shown.isNotEmpty) {
      // Per-flower hit-spots — TC-7 (S5). The placements use the same
      // math as the painter (`_PlantPlacement`) so the hit circles sit
      // directly over the rendered flowers regardless of canvas width.
      // v1.5 final polish — switched from a full-height rectangle to a
      // round hit-spot centred on the bloom. The rectangle caught taps
      // in the empty grass below each flower (and the empty sky above)
      // that felt unintentional; the circle matches the visual silhouette
      // so taps register where the user sees a flower.
      //
      // Diameter target: ≥ 48 dp (Material minimum), capped by the inter-
      // flower stride so dense rows stay per-plant addressable. The
      // circle's centre sits at ~35% of the bed height (where the bloom
      // is painted) rather than at vertical middle.
      final placements = _computeXPositions(shown, widget.size.width);
      final stride = widget.size.width / (shown.length + 1);
      // Diameter = min(64, stride - 4) clamped to ≥ 48. The -4 keeps a
      // 2-dp gap between adjacent circles so a tap "between flowers"
      // doesn't accidentally fire either.
      final diameter = math.max(48.0, math.min(64.0, stride - 4.0));
      final radius = diameter / 2;
      final centreY = widget.size.height * 0.35;
      for (var i = 0; i < placements.length; i += 1) {
        final cx = placements[i];
        final entry = shown[i];
        overlayChildren.add(
          Positioned(
            left: cx - radius,
            top: centreY - radius,
            width: diameter,
            height: diameter,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkResponse(
                onTap: () => widget.onFlowerTap?.call(entry),
                radius: radius,
                containedInkWell: true,
                customBorder: const CircleBorder(),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );
      }
    }
    if (widget.showOverflowBadge && hidden > 0) {
      overlayChildren.add(
        Positioned(top: 6, right: 6, child: _OverflowBadge(extra: hidden)),
      );
    }

    return Semantics(
      container: true,
      label: GardenBed._semanticsLabel(shown, widget.tier),
      child: ExcludeSemantics(
        child: overlayChildren.isEmpty
            ? canvas
            : Stack(children: [canvas, ...overlayChildren]),
      ),
    );
  }

  /// Mirrors the `_PlantPlacement` math in [_GardenBedPainter.paint].
  /// Kept in sync with the painter so per-flower hot-spots sit directly
  /// over the rendered plants. Returns the list in the SAME order as
  /// [shown] so callers can pair each x with its entry by index.
  static List<double> _computeXPositions(
    List<MoodEntry> shown,
    double canvasWidth,
  ) {
    final n = shown.length;
    final stride = canvasWidth / (n + 1);
    return [
      for (var i = 0; i < n; i += 1)
        () {
          final baseX = stride * (i + 1);
          final jitter = (shown[i].id.hashCode % 21) - 10;
          return (baseX + jitter).clamp(28.0, canvasWidth - 28.0);
        }(),
    ];
  }
}

/// Small pill rendered in the top-right of the bed when entries
/// outnumber [GardenBed._maxPlants]. Reads as "+12 more flowers" so
/// the user knows the visual is a sample of the archive, not the
/// whole story.
class _OverflowBadge extends StatelessWidget {
  const _OverflowBadge({required this.extra});

  final int extra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusFull),
        border: Border.all(color: primary.withValues(alpha: 0.25)),
      ),
      child: Text(
        '+$extra',
        style: MbFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
      ),
    );
  }
}

class _GardenBedPainter extends CustomPainter {
  _GardenBedPainter({
    required this.entries,
    required this.tier,
    required this.palette,
    required this.phase,
    this.speciesAccent,
  });

  final List<MoodEntry> entries;
  final PlantTier tier;
  final MbColors palette;

  /// 0..1 looped animation phase. Drives the sway / butterfly drift /
  /// lantern pulse — 0 in tests so goldens stay deterministic.
  final double phase;

  /// Optional per-species accent override (TC-6 flower skin system).
  /// `null` keeps the species' built-in palette; a non-null value
  /// recolours the petal/bud layer for plants of that species so the
  /// user's chosen alternate skin reads at canvas scale.
  final Map<FlowerSpecies, Color>? speciesAccent;

  // ───── shared species palette ─────
  static const _stemGreen = Color(0xFF4C8B6A);
  static const _stemDark = Color(0xFF356856);
  static const _leafGreen = Color(0xFF6FA587);
  static const _leafDark = Color(0xFF4A8267);
  static const _ferGreen = Color(0xFF5C9A78);
  static const _lavenderStem = Color(0xFF7E9A82);
  static const _lavenderLeaf = Color(0xFF9CB7A2);

  // Species-specific accents.
  static const _sunflowerYellow = Color(0xFFF6C45A);
  static const _sunflowerYellowDeep = Color(0xFFE8A23B);
  static const _sunflowerDisk = Color(0xFF6B3E1F);
  static const _sunflowerDiskRing = Color(0xFF4A2A14);

  static const _daisyWhite = Color(0xFFFAF7EE);
  static const _daisyDisk = Color(0xFFE8A23B);

  static const _forgetMeNotBlue = Color(0xFF7CA8D6);
  static const _forgetMeNotCenter = Color(0xFFF6C45A);

  static const _poppyRed = Color(0xFFE25C56);
  static const _poppyRedDeep = Color(0xFFB23D3A);
  static const _poppyCenter = Color(0xFF1F1A28);

  static const _lavenderPurple = Color(0xFFA493C8);
  static const _lavenderPurpleDeep = Color(0xFF7C6BA8);

  @override
  void paint(Canvas canvas, Size size) {
    final groundY = size.height - 6;

    // Empty state: just ground + grass blades, no plants. This is the
    // fix for the wipe-still-shows-3-flowers bug — the prior tier-
    // driven painter ignored entry count and always drew buds.
    _drawBackdropGrass(canvas, size, groundY);

    if (entries.isEmpty) {
      _drawTierAmbient(canvas, size, groundY);
      return;
    }

    // X-positions: evenly spaced with a per-entry hash jitter so two
    // builds with the same entry list always render at the same spots
    // (golden tests need that). For dense beds we also alternate
    // depth (back row + front row) so 20+ plants don't read as a
    // single regular line. Sort by depth so back-row plants paint
    // first and front-row plants overlap them (z-order = "closer to
    // the camera").
    final n = entries.length;
    // Use a back-row pass for n ≥ 8 — gives the bed visual depth
    // without making single-week views feel sparse. v1.0 polish
    // (2026-05-10) — earlier we lifted the back row's BASE 14 dp
    // above the ground to fake distance, but the resulting plants
    // looked like they were floating mid-air because the ground line
    // didn't follow them up. Both rows now share the same ground
    // baseline; back-row plants are smaller (0.85×) AND tucked
    // slightly behind the front row (paint order), which is enough
    // to read as depth without orphaning the stem from the soil.
    final useTwoRows = n >= 8;
    final stride = size.width / (n + 1);
    final placements = <_PlantPlacement>[];
    for (var i = 0; i < n; i += 1) {
      final entry = entries[i];
      final baseX = stride * (i + 1);
      final jitter = (entry.id.hashCode % 21) - 10;
      final cx = (baseX + jitter).clamp(28.0, size.width - 28.0);
      final isBackRow = useTwoRows && i.isEven;
      // `depth` is now a paint-order key only — it never offsets the
      // plant's Y position. Back-row plants render first (so the
      // front row visually sits on top of them) but stand on the
      // same ground line.
      placements.add(
        _PlantPlacement(entry: entry, cx: cx, depth: isBackRow ? 1.0 : 0.0),
      );
    }
    // Paint back-row first so front-row plants overlap them.
    placements.sort((a, b) => b.depth.compareTo(a.depth));

    // Per-tier vertical scale. Plants stay alive in every tier — this
    // is a "growth confidence" modulation, never a wilt. Flourishing
    // bumps the plant 10% larger; Storm Season pulls it back 8% so the
    // bed reads as more contracted/sheltered, but all stems + petals +
    // leaves are still rendered (ADR-0010 §4). The painter's growth
    // stage already drops petal counts on lower tiers; this scale is
    // an additional global multiplier on top of that, applied here at
    // the placement site so back-row depth scaling composes cleanly.
    final tierScale = _tierScaleFor(tier);
    for (final p in placements) {
      // Gentle plant sway — each plant has its own phase offset (from
      // entry id hash) so the bed doesn't oscillate in lockstep.
      final swayPhase =
          (phase + (p.entry.id.hashCode % 100) / 100.0) * 2 * math.pi;
      final swayDx = math.sin(swayPhase) * 1.6;
      // Back row 15% smaller AND tier scale stacked. Flourishing front
      // row → 1.10×; Storm Season back row → 0.85 × 0.92 ≈ 0.78×.
      final depthScale = p.depth > 0 ? 0.85 : 1.0;
      final scale = depthScale * tierScale;
      canvas.save();
      canvas.translate(p.cx + swayDx, groundY);
      canvas.scale(scale);
      // Plant painters expect (cx, groundY) in canvas coords. We've
      // translated to the plant's base, so paint at (0, 0).
      _drawPlant(canvas, p.entry, 0, 0);
      canvas.restore();
    }

    _drawTierAmbient(canvas, size, groundY);
  }

  // ───── ground + grass ─────

  void _drawBackdropGrass(Canvas canvas, Size size, double groundY) {
    // Subtle grass tufts along the ground line — every plant grows
    // out of grass. Faded so they don't compete with the plants.
    final grass = Paint()
      ..color = palette.grass.withValues(alpha: 0.55)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 16; i += 1) {
      final x = (size.width / 16) * i + 6;
      final y = groundY - (i % 3) * 1.2;
      canvas.drawLine(Offset(x, y), Offset(x + 1.5, y - 6), grass);
    }
  }

  // ───── plant dispatcher ─────

  /// Maps the bed's [PlantTier] (Storm Season → Flourishing) to a 5-step
  /// growth stage 0..4. Lower tiers render at earlier growth stages
  /// (closed bud / small) so a heavy week's garden reads as plants
  /// taking shelter, not blooming. The species itself never changes —
  /// stage tunes how much of the plant is visible.
  ///
  /// All stages are visually ALIVE (TC-24 — ADR-0010 §4 "plants never
  /// die"). Stage 0 (Storm Season) is a closed bud, never wilted; stage
  /// 4 (Flourishing) is full bloom.
  int get _growthStage => switch (tier) {
    PlantTier.stormSeason => 0,
    PlantTier.weathering => 1,
    PlantTier.resting => 2,
    PlantTier.thriving => 3,
    PlantTier.flourishing => 4,
  };

  /// Per-tier uniform scale factor applied to every plant in the bed.
  /// Stacks with the back-row depth scale (0.85×) at the placement
  /// site. Flourishing reads as larger and more present; Storm Season
  /// reads as more contracted/sheltered but is still rendered with
  /// stem + petals + leaves (ADR-0010 §4 "plants never die"). v1.5
  /// polish (2026-05-16) — tier differentiation pass; the bed used to
  /// only differ between tiers via petal count, which the user
  /// reported as too subtle on a glance.
  static double _tierScaleFor(PlantTier tier) => switch (tier) {
    PlantTier.flourishing => 1.10,
    PlantTier.thriving => 1.04,
    PlantTier.resting => 1.0,
    PlantTier.weathering => 0.95,
    PlantTier.stormSeason => 0.92,
  };

  void _drawPlant(Canvas canvas, MoodEntry entry, double cx, double groundY) {
    final species = FlowerSpecies.forMood(entry.mood);
    final stage = _growthStage;
    switch (species) {
      case FlowerSpecies.sunflower:
        _paintSunflower(canvas, cx, groundY, stage);
      case FlowerSpecies.daisy:
        _paintDaisy(canvas, cx, groundY, stage);
      case FlowerSpecies.forgetMeNot:
        _paintForgetMeNot(canvas, cx, groundY, stage);
      case FlowerSpecies.poppy:
        _paintPoppy(canvas, cx, groundY, stage);
      case FlowerSpecies.fern:
        _paintFern(canvas, cx, groundY, stage);
      case FlowerSpecies.lavender:
        _paintLavender(canvas, cx, groundY, stage);
    }
  }

  /// Returns the user's selected accent colour for [species] when an
  /// alternate skin is active, falling back to [fallback] otherwise.
  /// The fallback path preserves the painter's prior hardcoded look —
  /// default-skinned plants render byte-for-byte the same as before
  /// the skin system landed (TC-6 only changes the live render of
  /// alternate-skinned plants; default users see no change).
  ///
  /// Tier-aware: the returned colour is then run through
  /// [_tierSaturate] so Flourishing reads slightly more vivid and
  /// Storm Season slightly more muted while still rendering a fully
  /// alive, coloured plant (plants are never desaturated to grey —
  /// ADR-0010 §4). Resting and Thriving pass through unchanged.
  Color _accentFor(FlowerSpecies species, Color fallback) {
    final override = speciesAccent;
    final base = override == null ? fallback : (override[species] ?? fallback);
    return _tierSaturate(base);
  }

  /// Applies the per-tier saturation modulation. The factor is bounded
  /// at 0.78 (Storm Season) so petals never desaturate to grey — even
  /// the most heavily-weighted tier still renders unambiguously
  /// coloured flowers. Flourishing pushes saturation modestly above
  /// 1.0 by lerping the colour toward a brighter HSL-saturated cousin.
  Color _tierSaturate(Color base) {
    final factor = switch (tier) {
      PlantTier.flourishing => 1.08,
      PlantTier.thriving => 1.0,
      PlantTier.resting => 0.95,
      PlantTier.weathering => 0.86,
      PlantTier.stormSeason => 0.78,
    };
    if (factor == 1.0) return base;
    final hsl = HSLColor.fromColor(base);
    final newSat = (hsl.saturation * factor).clamp(0.0, 1.0);
    return hsl.withSaturation(newSat).toColor();
  }

  // ───── species 1: sunflower (Joy) ─────
  // Growth stages:
  //   0 stormSeason  — short stem (50dp), tightly closed green bud
  //   1 weathering   — stem 70dp, bud showing tip of yellow
  //   2 resting      — stem 85dp, half-open (8 petals)
  //   3 thriving     — stem 100dp, mostly open (14 petals)
  //   4 flourishing  — stem 100dp, full 18-petal bloom + bright disk

  void _paintSunflower(Canvas canvas, double cx, double groundY, int stage) {
    final stemH = switch (stage) {
      0 => 50.0,
      1 => 70.0,
      2 => 85.0,
      _ => 100.0,
    };
    final headCy = groundY - stemH - 8;

    // Stem.
    final stem = Paint()
      ..color = _stemGreen
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx, groundY), Offset(cx, groundY - stemH), stem);

    // Leaves — fewer on early stages so the bud reads as young.
    if (stage >= 1) {
      _drawBroadLeaf(
        canvas,
        attach: Offset(cx, groundY - (stemH * 0.4)),
        tip: Offset(cx - 22, groundY - (stemH * 0.45) - 10),
        color: _leafGreen,
      );
    }
    if (stage >= 2) {
      _drawBroadLeaf(
        canvas,
        attach: Offset(cx, groundY - (stemH * 0.7)),
        tip: Offset(cx + 24, groundY - (stemH * 0.75) - 10),
        color: _leafGreen,
      );
    }

    canvas.save();
    canvas.translate(cx, headCy);

    if (stage == 0) {
      // Tightly closed bud: small green sepal ovals around a centre.
      final sepal = Paint()..color = _stemDark;
      for (var i = 0; i < 5; i += 1) {
        canvas.save();
        canvas.rotate((i / 5) * 2 * math.pi);
        canvas.drawOval(const Rect.fromLTWH(0, -3, 9, 6), sepal);
        canvas.restore();
      }
      canvas.drawCircle(Offset.zero, 3, Paint()..color = _leafGreen);
      canvas.restore();
      return;
    }

    if (stage == 1) {
      // Bud opening — tip of yellow visible inside green sepals.
      final sepal = Paint()..color = _stemGreen;
      for (var i = 0; i < 6; i += 1) {
        canvas.save();
        canvas.rotate((i / 6) * 2 * math.pi);
        canvas.drawOval(const Rect.fromLTWH(0, -3.5, 11, 7), sepal);
        canvas.restore();
      }
      canvas.drawCircle(Offset.zero, 4.5, Paint()..color = _sunflowerYellow);
      canvas.restore();
      return;
    }

    // Stage 2+: ray petals appear. Petal count grows toward full bloom.
    final rayCount = switch (stage) {
      2 => 8,
      3 => 14,
      _ => 18,
    };

    // Back petal layer (deeper amber). Petals are CENTRED between front
    // petals on flourishing (stage 4) so the back layer doesn't peek
    // through as a 5°-misaligned ring.
    final backPetal = Paint()..color = _sunflowerYellowDeep;
    final backOffset = stage == 4 ? math.pi / rayCount : 0.0;
    for (var i = 0; i < rayCount; i += 1) {
      canvas.save();
      canvas.rotate((i / rayCount) * 2 * math.pi + backOffset);
      canvas.drawOval(const Rect.fromLTWH(7.5, -3.5, 16, 7), backPetal);
      canvas.restore();
    }
    // Front petal layer (bright yellow). Recolours to the user's
    // selected accent when an alternate sunflower skin is active.
    final frontPetal = Paint()
      ..color = _accentFor(FlowerSpecies.sunflower, _sunflowerYellow);
    for (var i = 0; i < rayCount; i += 1) {
      canvas.save();
      canvas.rotate((i / rayCount) * 2 * math.pi);
      canvas.drawOval(const Rect.fromLTWH(7, -3, 14, 6), frontPetal);
      canvas.restore();
    }
    // Disk.
    canvas.drawCircle(Offset.zero, 7.5, Paint()..color = _sunflowerDisk);
    canvas.drawCircle(
      Offset.zero,
      4.5,
      Paint()
        ..color = _sunflowerDiskRing
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.restore();
  }

  // ───── species 2: daisy (Okay) ─────
  // Stage 0 → tight white bud; 1 → 4 petals; 2 → 8; 3 → 12; 4 → 12 +
  // larger amber centre. Stem grows 35 → 65dp.

  void _paintDaisy(Canvas canvas, double cx, double groundY, int stage) {
    final stemH = switch (stage) {
      0 => 35.0,
      1 => 48.0,
      2 => 58.0,
      _ => 65.0,
    };
    final headCy = groundY - stemH - 5;

    final stem = Paint()
      ..color = _stemGreen
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx, groundY), Offset(cx, groundY - stemH), stem);

    if (stage >= 1) {
      _drawNarrowLeaf(
        canvas,
        attach: Offset(cx, groundY - (stemH * 0.45)),
        tip: Offset(cx - 15, groundY - (stemH * 0.5) - 3),
        color: _leafGreen,
      );
    }
    if (stage >= 2) {
      _drawNarrowLeaf(
        canvas,
        attach: Offset(cx, groundY - (stemH * 0.75)),
        tip: Offset(cx + 14, groundY - (stemH * 0.8) - 3),
        color: _leafGreen,
      );
    }

    canvas.save();
    canvas.translate(cx, headCy);

    if (stage == 0) {
      // Tight closed bud — small white oval inside green sepals.
      canvas.drawCircle(Offset.zero, 4, Paint()..color = _stemGreen);
      canvas.drawCircle(Offset.zero, 2.2, Paint()..color = _daisyWhite);
      canvas.restore();
      return;
    }

    final petalCount = switch (stage) {
      1 => 4,
      2 => 8,
      _ => 12,
    };
    final petal = Paint()..color = _daisyWhite;
    final petalShadow = Paint()
      ..color = const Color(0xFFB8AE94).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    for (var i = 0; i < petalCount; i += 1) {
      canvas.save();
      canvas.rotate((i / petalCount) * 2 * math.pi);
      const rect = Rect.fromLTWH(3.5, -2, 10, 4);
      canvas.drawOval(rect, petal);
      canvas.drawOval(rect, petalShadow);
      canvas.restore();
    }
    final diskRadius = stage == 4 ? 4.5 : 3.5;
    canvas.drawCircle(Offset.zero, diskRadius, Paint()..color = _daisyDisk);
    canvas.restore();
  }

  // ───── species 3: forget-me-not (Sad) ─────
  // Stage 0 → 1 closed bud at apex; 1 → 1 open flower; 2 → 2 flowers;
  // 3 → 3 flowers; 4 → 4 flowers (full cluster, current shape).

  void _paintForgetMeNot(Canvas canvas, double cx, double groundY, int stage) {
    final stemH = switch (stage) {
      0 => 35.0,
      1 => 45.0,
      _ => 56.0,
    };

    final stem = Paint()
      ..color = _stemGreen
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx, groundY), Offset(cx, groundY - stemH), stem);

    if (stage >= 2) {
      canvas.drawLine(
        Offset(cx, groundY - (stemH * 0.55)),
        Offset(cx + 14, groundY - (stemH * 0.55) - 10),
        stem,
      );
    }
    if (stage >= 3) {
      canvas.drawLine(
        Offset(cx, groundY - (stemH * 0.7)),
        Offset(cx - 12, groundY - (stemH * 0.7) - 10),
        stem,
      );
    }

    if (stage >= 1) {
      _drawNarrowLeaf(
        canvas,
        attach: Offset(cx, groundY - 20),
        tip: Offset(cx - 11, groundY - 22),
        color: _leafGreen,
      );
    }
    if (stage >= 2) {
      _drawNarrowLeaf(
        canvas,
        attach: Offset(cx, groundY - 12),
        tip: Offset(cx + 10, groundY - 14),
        color: _leafGreen,
      );
    }

    if (stage == 0) {
      // Closed bud at the stem tip.
      canvas.drawCircle(
        Offset(cx, groundY - stemH),
        3,
        Paint()..color = _stemGreen,
      );
      canvas.drawCircle(
        Offset(cx, groundY - stemH),
        1.6,
        Paint()..color = _forgetMeNotBlue,
      );
      return;
    }

    // Cluster of 1..4 5-petal flowers grown from apex outward.
    final all = [
      Offset(cx, groundY - stemH),
      Offset(cx + 14, groundY - 42),
      Offset(cx - 12, groundY - 48),
      Offset(cx + 4, groundY - 50),
    ];
    final shown = all.take(stage).toList(growable: false);
    for (final pos in shown) {
      _draw5PetalFlower(canvas, pos, radius: 4.0);
    }
  }

  void _draw5PetalFlower(
    Canvas canvas,
    Offset center, {
    required double radius,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    final petal = Paint()
      ..color = _accentFor(FlowerSpecies.forgetMeNot, _forgetMeNotBlue);
    for (var i = 0; i < 5; i += 1) {
      canvas.save();
      canvas.rotate((i / 5) * 2 * math.pi);
      canvas.drawCircle(Offset(radius * 0.85, 0), radius, petal);
      canvas.restore();
    }
    canvas.drawCircle(
      Offset.zero,
      radius * 0.45,
      Paint()..color = _forgetMeNotCenter,
    );
    canvas.restore();
  }

  // ───── species 4: poppy (Anger) ─────
  // Stage 0 → drooping closed bud at stem tip; 1 → small bud showing red;
  // 2 → 2 petals; 3 → 4 petals (no stamens); 4 → 4 petals + stamens.

  void _paintPoppy(Canvas canvas, double cx, double groundY, int stage) {
    final stemH = switch (stage) {
      0 => 40.0,
      1 => 55.0,
      _ => 68.0,
    };
    final headCy = groundY - stemH - 7;

    final stem = Paint()
      ..color = _stemGreen
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final stemPath = Path()
      ..moveTo(cx, groundY)
      ..quadraticBezierTo(cx + 3, groundY - (stemH * 0.5), cx, groundY - stemH);
    canvas.drawPath(stemPath, stem);

    if (stage >= 1) {
      _drawJaggedLeaf(
        canvas,
        attach: Offset(cx, groundY - 25),
        tip: Offset(cx - 18, groundY - 32),
        color: _leafDark,
      );
    }
    if (stage >= 2) {
      _drawJaggedLeaf(
        canvas,
        attach: Offset(cx, groundY - 50),
        tip: Offset(cx + 18, groundY - 56),
        color: _leafDark,
      );
    }

    canvas.save();
    canvas.translate(cx, headCy);

    if (stage == 0) {
      // Closed teardrop bud — sepal-green outer, hint of red inside.
      canvas.drawOval(
        const Rect.fromLTWH(-5, -10, 10, 14),
        Paint()..color = _stemGreen,
      );
      canvas.drawOval(
        const Rect.fromLTWH(-3, -7, 6, 9),
        Paint()..color = _poppyRedDeep,
      );
      canvas.restore();
      return;
    }

    if (stage == 1) {
      // First petal opening.
      canvas.drawOval(
        const Rect.fromLTWH(-7, -12, 14, 12),
        Paint()..color = _poppyRed,
      );
      canvas.drawCircle(Offset.zero, 3.0, Paint()..color = _poppyCenter);
      canvas.restore();
      return;
    }

    final petalCount = stage == 2 ? 2 : 4;
    final backPetal = Paint()..color = _poppyRedDeep;
    for (var i = 0; i < petalCount; i += 1) {
      canvas.save();
      canvas.rotate((i / petalCount) * 2 * math.pi);
      canvas.drawOval(const Rect.fromLTWH(-9, -14, 18, 14), backPetal);
      canvas.restore();
    }
    final frontPetal = Paint()
      ..color = _accentFor(FlowerSpecies.poppy, _poppyRed);
    for (var i = 0; i < petalCount; i += 1) {
      canvas.save();
      canvas.rotate((i / petalCount) * 2 * math.pi + (math.pi / 8));
      canvas.drawOval(const Rect.fromLTWH(-7, -12, 14, 12), frontPetal);
      canvas.restore();
    }
    canvas.drawCircle(Offset.zero, 4.5, Paint()..color = _poppyCenter);
    if (stage == 4) {
      // Stamen dots only on full bloom.
      final stamen = Paint()..color = _poppyCenter;
      for (var i = 0; i < 6; i += 1) {
        final a = (i / 6) * 2 * math.pi;
        final p = Offset(math.cos(a) * 7, math.sin(a) * 7);
        canvas.drawCircle(p, 0.9, stamen);
      }
    }
    canvas.restore();
  }

  // ───── species 5: fern (Anxiety) ─────
  // Stage 0 → coiled fiddlehead (no pinnae); 1 → 4 pinnae; 2 → 6 pinnae;
  // 3 → 8 pinnae; 4 → 10 pinnae (full frond).

  void _paintFern(Canvas canvas, double cx, double groundY, int stage) {
    final stemH = switch (stage) {
      0 => 30.0,
      1 => 50.0,
      2 => 65.0,
      3 => 76.0,
      _ => 85.0,
    };
    final tipY = groundY - stemH;

    final rachis = Paint()
      ..color = _ferGreen
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final rachisPath = Path()
      ..moveTo(cx, groundY)
      ..cubicTo(
        cx,
        groundY - (stemH * 0.35),
        cx + 5,
        groundY - (stemH * 0.7),
        cx + 8,
        tipY,
      );
    canvas.drawPath(rachisPath, rachis);

    if (stage == 0) {
      // Coiled fiddlehead — small spiral at the tip.
      final fiddlehead = Paint()
        ..color = _ferGreen
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      final spiral = Path()
        ..moveTo(cx + 8, tipY)
        ..arcToPoint(
          Offset(cx + 12, tipY - 4),
          radius: const Radius.circular(4),
        )
        ..arcToPoint(Offset(cx + 6, tipY - 6), radius: const Radius.circular(3))
        ..arcToPoint(
          Offset(cx + 9, tipY - 9),
          radius: const Radius.circular(2),
        );
      canvas.drawPath(spiral, fiddlehead);
      return;
    }

    final pinnaeCount = switch (stage) {
      1 => 4,
      2 => 6,
      3 => 8,
      _ => 10,
    };
    final pinnae = Paint()
      ..color = _ferGreen.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < pinnaeCount; i += 1) {
      final t = pinnaeCount == 1 ? 0.5 : i / (pinnaeCount - 1).toDouble();
      // Sample the spine path at parameter t for the attach point.
      final attachY = groundY - (stemH * t);
      final attachX = cx + (8 * t * t); // matches the cubic's slight bend
      final length = 24 - t * 14; // 24dp at base, 10dp at tip
      final side = i.isEven ? -1 : 1; // alternate left / right
      final tipOffset = Offset(
        attachX + length * side,
        attachY - 3, // each pinna angles slightly upward
      );
      // Draw the pinna as a teardrop / pointed oval.
      final p = Path()
        ..moveTo(attachX, attachY)
        ..quadraticBezierTo(
          attachX + length * 0.4 * side,
          attachY - 6,
          tipOffset.dx,
          tipOffset.dy,
        )
        ..quadraticBezierTo(
          attachX + length * 0.4 * side,
          attachY + 1.5,
          attachX,
          attachY,
        )
        ..close();
      canvas.drawPath(p, pinnae);
    }
    // Small terminal pinna at the very tip.
    canvas.drawCircle(Offset(cx + 8, tipY), 2.5, Paint()..color = _ferGreen);
  }

  // ───── species 6: lavender (Calm) ─────
  // Stage 0 → 2 closed buds; 1 → 4 buds; 2 → 5 buds; 3 → 6 buds;
  // 4 → 8 buds (full spike). Stem grows 50 → 95dp.

  void _paintLavender(Canvas canvas, double cx, double groundY, int stage) {
    final stemH = switch (stage) {
      0 => 50.0,
      1 => 65.0,
      2 => 78.0,
      3 => 88.0,
      _ => 95.0,
    };
    final tipY = groundY - stemH;

    final stalk = Paint()
      ..color = _lavenderStem
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx, groundY), Offset(cx, tipY), stalk);

    if (stage >= 1) {
      _drawNarrowLeaf(
        canvas,
        attach: Offset(cx, groundY - 20),
        tip: Offset(cx - 13, groundY - 25),
        color: _lavenderLeaf,
      );
      _drawNarrowLeaf(
        canvas,
        attach: Offset(cx, groundY - 20),
        tip: Offset(cx + 13, groundY - 25),
        color: _lavenderLeaf,
      );
    }
    if (stage >= 2) {
      _drawNarrowLeaf(
        canvas,
        attach: Offset(cx, groundY - 35),
        tip: Offset(cx - 11, groundY - 40),
        color: _lavenderLeaf,
      );
      _drawNarrowLeaf(
        canvas,
        attach: Offset(cx, groundY - 35),
        tip: Offset(cx + 11, groundY - 40),
        color: _lavenderLeaf,
      );
    }

    // Flowering spike — bud count scales with stage.
    final budCount = switch (stage) {
      0 => 2,
      1 => 4,
      2 => 5,
      3 => 6,
      _ => 8,
    };
    final budOuter = Paint()
      ..color = _accentFor(FlowerSpecies.lavender, _lavenderPurple);
    final budInner = Paint()..color = _lavenderPurpleDeep;
    for (var i = 0; i < budCount; i += 1) {
      final y = tipY + (i * 4.0);
      final dx = (i.isEven ? -1.0 : 1.0) * 1.5;
      final centre = Offset(cx + dx, y + 1.5);
      canvas.drawOval(
        Rect.fromCenter(center: centre, width: 7, height: 5),
        budOuter,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: centre.translate(0, 0.8),
          width: 4,
          height: 2.5,
        ),
        budInner,
      );
    }
  }

  // ───── leaf primitives ─────

  void _drawBroadLeaf(
    Canvas canvas, {
    required Offset attach,
    required Offset tip,
    required Color color,
  }) {
    final p = Path()
      ..moveTo(attach.dx, attach.dy)
      ..quadraticBezierTo((attach.dx + tip.dx) / 2, tip.dy - 8, tip.dx, tip.dy)
      ..quadraticBezierTo(
        (attach.dx + tip.dx) / 2,
        tip.dy + 6,
        attach.dx,
        attach.dy,
      )
      ..close();
    canvas.drawPath(p, Paint()..color = color);
    // Centre vein for visual depth.
    canvas.drawLine(
      attach,
      tip,
      Paint()
        ..color = _stemDark.withValues(alpha: 0.4)
        ..strokeWidth = 0.6,
    );
  }

  void _drawNarrowLeaf(
    Canvas canvas, {
    required Offset attach,
    required Offset tip,
    required Color color,
  }) {
    final p = Path()
      ..moveTo(attach.dx, attach.dy)
      ..quadraticBezierTo((attach.dx + tip.dx) / 2, tip.dy - 3, tip.dx, tip.dy)
      ..quadraticBezierTo(
        (attach.dx + tip.dx) / 2,
        tip.dy + 3,
        attach.dx,
        attach.dy,
      )
      ..close();
    canvas.drawPath(p, Paint()..color = color);
  }

  void _drawJaggedLeaf(
    Canvas canvas, {
    required Offset attach,
    required Offset tip,
    required Color color,
  }) {
    // Jagged outer edge — two notches along the long side give the
    // poppy leaf its characteristic deep-lobed look without going
    // full SVG-grade detail.
    final mid = Offset(
      (attach.dx + tip.dx) / 2,
      ((attach.dy + tip.dy) / 2) - 8,
    );
    final p = Path()
      ..moveTo(attach.dx, attach.dy)
      ..quadraticBezierTo(mid.dx - 4, mid.dy + 2, mid.dx - 2, mid.dy)
      ..lineTo(mid.dx, mid.dy - 3)
      ..lineTo(mid.dx + 2, mid.dy)
      ..quadraticBezierTo(mid.dx + 4, mid.dy + 2, tip.dx, tip.dy)
      ..quadraticBezierTo(
        (attach.dx + tip.dx) / 2,
        tip.dy + 5,
        attach.dx,
        attach.dy,
      )
      ..close();
    canvas.drawPath(p, Paint()..color = color);
  }

  // ───── tier ambient overlays ─────

  void _drawTierAmbient(Canvas canvas, Size size, double groundY) {
    switch (tier) {
      case PlantTier.flourishing:
        // Two butterflies drifting in opposite directions so the
        // motion reads as ambient life rather than synchronized
        // animation. Each carries its own phase offset and y bobbing.
        final dxA = math.sin(phase * 2 * math.pi) * 18;
        final dyA = math.cos(phase * 2 * math.pi) * 4;
        final dxB = math.sin(phase * 2 * math.pi + math.pi) * 18;
        final dyB = math.cos(phase * 2 * math.pi + math.pi) * 4;
        _drawButterfly(
          canvas,
          Offset(size.width * 0.20 + dxA, 18 + dyA),
          MoodBloomColors.moodCalm,
        );
        _drawButterfly(
          canvas,
          Offset(size.width * 0.78 + dxB, 28 + dyB),
          MoodBloomColors.moodAnxious,
        );
      case PlantTier.thriving:
      case PlantTier.resting:
        // Calm baseline — no ambient extras.
        break;
      case PlantTier.weathering:
        // Cloud shadow drifts slowly across the bed.
        final cloudDx = math.sin(phase * 2 * math.pi) * 24;
        _drawCloudShadow(canvas, size, cloudDx);
      case PlantTier.stormSeason:
        // Lanterns pulse opacity gently — ±0.15 around the base alpha.
        final pulseA = (math.sin(phase * 2 * math.pi) + 1) / 2;
        final pulseB = (math.sin(phase * 2 * math.pi + math.pi) + 1) / 2;
        _drawLantern(canvas, Offset(size.width * 0.12, groundY - 22), pulseA);
        _drawLantern(canvas, Offset(size.width * 0.88, groundY - 22), pulseB);
    }
  }

  void _drawCloudShadow(Canvas canvas, Size size, double dx) {
    final cloud = Paint()..color = palette.textDim.withValues(alpha: 0.20);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5 + dx, 22),
        width: 130,
        height: 24,
      ),
      cloud,
    );
  }

  void _drawButterfly(Canvas canvas, Offset center, Color color) {
    // Wing flutter — open / close oscillation at 4× the bed phase so
    // wings beat faster than the body drifts.
    final flutter = math.sin(phase * 8 * math.pi).abs();
    final wingW = 3.0 + flutter * 1.6; // 3..4.6 dp
    final wing = Paint()..color = color.withValues(alpha: 0.85);
    canvas.drawCircle(center.translate(-4, 0), wingW, wing);
    canvas.drawCircle(center.translate(4, 0), wingW, wing);
    canvas.drawCircle(center, 1.4, Paint()..color = palette.text);
  }

  void _drawLantern(Canvas canvas, Offset center, double pulse) {
    // Bright amber glow + warm core. Brighter than the mood swatches
    // so the storm tier still reads as hopeful per ADR-0010 §4.
    // `pulse` (0..1) modulates the glow alpha so lanterns flicker
    // gently — never going fully dark, never blowing out.
    final glowAlpha = 0.25 + pulse * 0.20; // 0.25..0.45
    final glowR = 13.0 + pulse * 3.0; // 13..16 dp
    final glow = Paint()
      ..color = MoodBloomColors.amber.withValues(alpha: glowAlpha);
    canvas.drawCircle(center, glowR, glow);
    final core = Paint()..color = const Color(0xFFFFE9B8);
    canvas.drawCircle(center, 7, core);
    final stroke = Paint()
      ..color = MoodBloomColors.amber
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 7, stroke);
  }

  @override
  bool shouldRepaint(covariant _GardenBedPainter old) =>
      old.tier != tier ||
      old.entries.length != entries.length ||
      !_sameEntryIds(old.entries, entries) ||
      old.palette != palette ||
      old.phase != phase ||
      !_sameAccentMap(old.speciesAccent, speciesAccent);

  static bool _sameAccentMap(
    Map<FlowerSpecies, Color>? a,
    Map<FlowerSpecies, Color>? b,
  ) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  static bool _sameEntryIds(List<MoodEntry> a, List<MoodEntry> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i += 1) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }
}

/// Resolved x-position + depth for a plant in the bed. `depth = 0`
/// means the front row (full size, sits at the bed's groundY); larger
/// values place the plant on a back row (smaller, sits higher up so
/// it reads as further from the camera).
class _PlantPlacement {
  const _PlantPlacement({
    required this.entry,
    required this.cx,
    required this.depth,
  });

  final MoodEntry entry;
  final double cx;
  final double depth;
}
