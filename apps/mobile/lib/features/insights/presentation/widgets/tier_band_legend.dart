import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Persistent tier-band legend card.
///
/// Five swatch-plus-text rows naming the five plant-tier bands the chart
/// paints behind the score line. Colour tokens are taken from the same
/// alpha/colour map [MoodScoreChart] feeds into `mood_score_chart.dart`
/// so the swatch reads as a literal mini-legend of what the user sees on
/// the chart.
///
/// Copy obeys CLAUDE.md "plants are NEVER destroyed" rule — Storm Season
/// is "sheltered, never withered", never "wilted", never "dying".
class TierBandLegend extends StatelessWidget {
  const TierBandLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    // Mirror the alpha + colour map in
    // `mood_score_chart.dart:43..49` so the legend swatches are
    // byte-for-byte the same hue the chart paints.
    final rows = <_LegendEntry>[
      _LegendEntry(
        color: MoodBloomColors.softGreen.withValues(alpha: 0.55),
        title: 'Flourishing',
        subtitle: 'full bloom',
      ),
      _LegendEntry(
        color: MoodBloomColors.softGreen.withValues(alpha: 0.28),
        title: 'Thriving',
        subtitle: 'open canopy',
      ),
      _LegendEntry(
        color: mb.line.withValues(alpha: 0.18),
        title: 'Resting',
        subtitle: 'a gentle pace',
      ),
      _LegendEntry(
        color: mb.softCoral.withValues(alpha: 0.45),
        title: 'Weathering',
        subtitle: 'rain-fed, growing',
      ),
      _LegendEntry(
        color: MoodBloomColors.coral.withValues(alpha: 0.30),
        title: 'Storm Season',
        subtitle: 'sheltered, never withered',
      ),
    ];

    return Semantics(
      container: true,
      label: 'Tier band legend',
      child: MbCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tier band legend',
              style: MbFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: mb.text,
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < rows.length; i++) ...[
              _LegendRow(entry: rows[i]),
              if (i != rows.length - 1) const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegendEntry {
  const _LegendEntry({
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final Color color;
  final String title;
  final String subtitle;
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.entry});

  final _LegendEntry entry;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: entry.color,
            // Faint outline so the swatch is visible even at the low
            // alpha values used for Resting / Thriving.
            border: Border.all(color: mb.line, width: 0.5),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                entry.title,
                style: MbFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: mb.text,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  entry.subtitle,
                  style: MbFonts.nunito(fontSize: 12, color: mb.textDim),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
