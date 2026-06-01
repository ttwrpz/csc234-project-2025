import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../garden/domain/entities/plant_tier.dart';
import '../../../garden/presentation/widgets/sky_plot_strip.dart';
import '../../../mood/domain/entities/mood_entry.dart';

/// Compact garden snapshot shared by every harvest surface (the history
/// cards, the archived-week detail hero, and the weekly-summary modal
/// hero) so they all render an identical garden.
///
/// Composition: a per-tier sky gradient + a two-tone ground band behind
/// the home garden's [SkyPlotStrip] (one mood-keyed plant cluster per
/// day, day labels hidden). This keeps the harvest flower model 1:1 with
/// the live home garden instead of the older detailed `GardenBed`.
class HarvestMiniGarden extends StatelessWidget {
  const HarvestMiniGarden({
    super.key,
    required this.entries,
    required this.tier,
    this.weekStart,
    this.height = 130,
  });

  /// The week's mood entries. Bucketed into 7 daily columns by the
  /// inner [SkyPlotStrip].
  final List<MoodEntry> entries;

  /// Ending plant tier for the week - drives the sky gradient + the
  /// plants' height boost.
  final PlantTier tier;

  /// Monday-aligned local-midnight of the week. When null it is derived
  /// from the entries (Monday of the most-recent entry) so callers that
  /// don't carry an explicit weekStart - e.g. the pre-archive summary
  /// modal - still bucket correctly.
  final DateTime? weekStart;

  /// Panel height. Cards + modal heroes use the 130 dp default; pass a
  /// larger value for a taller hero.
  final double height;

  /// Per-tier sky gradient stops. Light variants ported from the
  /// prototype's `MiniHarvestGarden > TIER_BG`; dark variants mirror the
  /// SkyHeader's per-tier night skies so the harvest snapshot respects
  /// the app theme instead of always rendering a bright daytime sky.
  /// Storm reads as a muted slate, never an alarming charcoal.
  static List<Color> _skyFor(PlantTier tier, bool isDark) {
    if (isDark) {
      return switch (tier) {
        PlantTier.flourishing => const [
          Color(0xFF2D2147),
          Color(0xFF3E2D5C),
          Color(0xFF1F2D3A),
        ],
        PlantTier.thriving => const [
          Color(0xFF1B2942),
          Color(0xFF1F2E3F),
          Color(0xFF1A2D2A),
        ],
        PlantTier.resting => const [
          Color(0xFF2A2638),
          Color(0xFF2D2A3B),
          Color(0xFF25292E),
        ],
        PlantTier.weathering => const [
          Color(0xFF232830),
          Color(0xFF252D30),
          Color(0xFF1F2A24),
        ],
        PlantTier.stormSeason => const [
          Color(0xFF0F1620),
          Color(0xFF1A2330),
          Color(0xFF14202A),
        ],
      };
    }
    return switch (tier) {
      PlantTier.flourishing => const [
        Color(0xFFFFE0BA),
        Color(0xFFFFEAD0),
        Color(0xFFDDEFD8),
      ],
      PlantTier.thriving => const [
        Color(0xFFFFE4D1),
        Color(0xFFF5E9DA),
        Color(0xFFE8F3ED),
      ],
      PlantTier.resting => const [
        Color(0xFFF4DCC4),
        Color(0xFFECDFD0),
        Color(0xFFDAE2CE),
      ],
      PlantTier.weathering => const [
        Color(0xFFC8C9BC),
        Color(0xFFC2C7BA),
        Color(0xFFB8C5B0),
      ],
      PlantTier.stormSeason => const [
        Color(0xFF6E7C8B),
        Color(0xFF61707F),
        Color(0xFF4C606A),
      ],
    };
  }

  static DateTime _mondayOf(DateTime now) {
    final local = now.toLocal();
    final midnight = DateTime(local.year, local.month, local.day);
    return midnight.subtract(
      Duration(days: midnight.weekday - DateTime.monday),
    );
  }

  DateTime _resolveWeekStart() {
    if (weekStart != null) return weekStart!;
    if (entries.isEmpty) return _mondayOf(DateTime.now());
    final latest = entries
        .map((e) => e.createdAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    return _mondayOf(latest);
  }

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isStorm = tier == PlantTier.stormSeason;
    // In dark mode the theme ground tones (already dark) read correctly
    // under the night sky; only the light-mode storm needs its custom
    // slate ground so it doesn't clash with the grey sky.
    final groundFront = (isStorm && !isDark)
        ? const Color(0xFF2E4538)
        : mb.ground2;
    final groundBack = (isStorm && !isDark)
        ? const Color(0xFF3D5040)
        : mb.ground;
    // White day labels read on both the light storm sky and any dark
    // sky; the dark non-storm tiers also want a light label.
    final labelTint = (isStorm || isDark) ? Colors.white : mb.text;

    return SizedBox(
      height: height,
      child: ClipRect(
        child: Stack(
          children: [
            // Sky.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0, 0.55, 1],
                    colors: _skyFor(tier, isDark),
                  ),
                ),
              ),
            ),
            // Two-tone ground band.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 30,
              child: DecoratedBox(decoration: BoxDecoration(color: groundBack)),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 18,
              child: DecoratedBox(
                decoration: BoxDecoration(color: groundFront),
              ),
            ),
            // Plants - same model + bucketing as the home strip.
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: SkyPlotStrip(
                weekEntries: entries,
                weekStart: _resolveWeekStart(),
                tier: tier,
                compact: true,
                showDayLabels: false,
                labelColor: labelTint,
                darkOverlay: isStorm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
