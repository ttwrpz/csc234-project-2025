import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/garden_state.dart';
import '../../domain/entities/plant_tier.dart';
import 'sky_header.dart' show SkyHeader;

/// Page-flow card holding the garden's meta info: the compassionate
/// tier tagline ("Resting — quiet days for the soil"), the optional
/// token-balance chip, and the "View patterns →" CTA.
///
/// Rendered as a normal MbCard below the canvas (not as a floating
/// overlay) so the SkyHeader stays visually clean and the meta info
/// has a readable home against the cream surface rather than fighting
/// the sky/plants gradient.
class GardenSummaryRow extends StatelessWidget {
  const GardenSummaryRow({super.key, required this.state, this.tokenChip});

  final GardenState state;

  /// Optional token-balance widget rendered to the left of the
  /// "View patterns" CTA. The garden screen passes a `_GardenTokenChip`;
  /// other surfaces (tests, harvest history) can omit it.
  final Widget? tokenChip;

  /// Below this card width the row's four children (tier pill +
  /// tagline, token chip, customize pill, Patterns button) crowd each
  /// other and the tagline gets crushed to two-or-three words per line.
  /// At narrow widths we stack them in two rows so each element has
  /// room to breathe.
  static const double _narrow = 400;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mb = theme.extension<MbColors>()!;
    return MbCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < _narrow;
          final tierColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tier pill — colored at-a-glance badge identifying the
              // ecosystem state. Surfaces the name + a colored dot up
              // front so the five states read distinctly across the
              // row, instead of being buried inside the longer tagline.
              _TierPill(tier: state.plantTier, isEmpty: state.isEmpty),
              const SizedBox(height: 6),
              Text(
                SkyHeader.tierTagline(state),
                style: MbFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: mb.text,
                  height: 1.3,
                ),
              ),
            ],
          );
          final patternsButton = _ViewPatternsButton(
            onTap: () => context.go('/analytics'),
          );

          if (isNarrow) {
            // Phone: stack vertically. Top row = tier + tagline full
            // width. Bottom row = token chip on the left, Patterns CTA
            // on the right. The customize affordance lives inside the
            // token chip composite, so this layout keeps all four
            // elements visible without squashing the tagline.
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                tierColumn,
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (tokenChip != null)
                      Flexible(child: tokenChip!)
                    else
                      const SizedBox.shrink(),
                    const SizedBox(width: 8),
                    patternsButton,
                  ],
                ),
              ],
            );
          }

          // Wider widths keep the prior horizontal layout.
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: tierColumn),
              if (tokenChip != null) ...[const SizedBox(width: 12), tokenChip!],
              const SizedBox(width: 12),
              // The "Take a breath" pill is rendered by the home page
              // itself, so this row only carries the tier badge,
              // tagline, token chip, and Patterns CTA.
              patternsButton,
            ],
          );
        },
      ),
    );
  }
}

class _ViewPatternsButton extends StatelessWidget {
  const _ViewPatternsButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Light mode: deep green primary on cream surface gives good
    // contrast directly. Dark mode: the same green darkens against
    // navy and reads as low-contrast — the user reported the button
    // was hard to see in dark theme. Switch to a filled tonal style
    // (light-mint container + primary text) which keeps the brand
    // hue but lifts contrast above WCAG AA on both themes.
    final fg = isDark ? const Color(0xFFCDE8DA) : theme.colorScheme.primary;
    final bg = isDark
        ? theme.colorScheme.primary.withValues(alpha: 0.32)
        : theme.colorScheme.primary.withValues(alpha: 0.08);
    final border = isDark
        ? const Color(0xFFCDE8DA).withValues(alpha: 0.45)
        : theme.colorScheme.primary.withValues(alpha: 0.25);

    return Semantics(
      button: true,
      label: 'View patterns',
      child: TextButton.icon(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: fg,
          backgroundColor: bg,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusFull),
            side: BorderSide(color: border),
          ),
        ),
        icon: Icon(Icons.insights_outlined, size: 16, color: fg),
        label: Text(
          'Patterns',
          style: MbFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}

/// Colored at-a-glance badge identifying which of the five ecosystem
/// tiers the garden is currently in. Sits above the tagline so the
/// user reads "Thriving" or "Storm Season" as a named state before
/// the longer compassionate sentence.
///
/// Colors are deliberately compassionate, not alarming — Storm Season
/// uses a soft coral (warm pink-amber) rather than a red, in keeping
/// with the no-fix-your-mood / "weather passes, roots hold" tone.
class _TierPill extends StatelessWidget {
  const _TierPill({required this.tier, required this.isEmpty});

  final PlantTier tier;

  /// When true, the user has logged no entries yet. In that case the
  /// pill collapses entirely so the empty-state tagline ("Plant your
  /// first mood — a fresh canvas awaits.") doesn't get prefixed with
  /// a tier badge that wouldn't reflect anything the user did.
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    if (isEmpty) return const SizedBox.shrink();
    final palette = _paletteFor(tier);
    return Semantics(
      label: 'Garden state: ${_labelFor(tier)}',
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: palette.bg,
          borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusFull),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Colored dot reinforces the pill background colour and
            // gives a one-glance hue cue for users with mild color
            // vision differences — the dot is denser saturation than
            // the soft pill bg, so the contrast reads even on a
            // monochrome scan.
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: palette.dot,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _labelFor(tier),
              style: MbFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: palette.fg,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _labelFor(PlantTier tier) => switch (tier) {
    PlantTier.flourishing => 'Flourishing',
    PlantTier.thriving => 'Thriving',
    PlantTier.resting => 'Resting',
    PlantTier.weathering => 'Weathering',
    PlantTier.stormSeason => 'Storm Season',
  };

  /// Per-tier palette (background, border, foreground, dot). All four
  /// colors are picked to clear WCAG AA against the cream MbCard
  /// surface in light theme and against the dark navy surface in dark
  /// theme — the foreground text is the same hue family as the dot but
  /// substantially darker so the label stays readable on the pill bg.
  static _TierPillPalette _paletteFor(PlantTier tier) => switch (tier) {
    // Bright meadow green — full life.
    PlantTier.flourishing => const _TierPillPalette(
      bg: Color(0xFFD9F0DD),
      border: Color(0xFF6DBE7A),
      fg: Color(0xFF1F5A2E),
      dot: Color(0xFF2E9B49),
    ),
    // Soft mint — growth in progress.
    PlantTier.thriving => const _TierPillPalette(
      bg: Color(0xFFE3F1E5),
      border: Color(0xFF8FBFA3),
      fg: Color(0xFF285C44),
      dot: Color(0xFF4FA37F),
    ),
    // Neutral warm grey — quiet, dormant.
    PlantTier.resting => const _TierPillPalette(
      bg: Color(0xFFEEEAE0),
      border: Color(0xFFC9C0AE),
      fg: Color(0xFF5A5448),
      dot: Color(0xFF8B8473),
    ),
    // Soft amber — light overcast, gentle weather.
    PlantTier.weathering => const _TierPillPalette(
      bg: Color(0xFFF4E7CD),
      border: Color(0xFFD9B96A),
      fg: Color(0xFF6E4F1B),
      dot: Color(0xFFC68A1E),
    ),
    // Soft coral — compassionate, never red-alarm.
    PlantTier.stormSeason => const _TierPillPalette(
      bg: Color(0xFFFDE3DA),
      border: Color(0xFFE9A892),
      fg: Color(0xFF7A3925),
      dot: Color(0xFFCC6347),
    ),
  };
}

/// Internal record-shaped struct for the four colors a tier pill needs.
/// Not exported — the pill is the only consumer.
@immutable
class _TierPillPalette {
  const _TierPillPalette({
    required this.bg,
    required this.border,
    required this.fg,
    required this.dot,
  });

  final Color bg;
  final Color border;
  final Color fg;
  final Color dot;
}
