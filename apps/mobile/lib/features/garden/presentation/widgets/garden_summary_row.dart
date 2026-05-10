import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/garden_state.dart';
import 'sky_header.dart' show SkyHeader;

/// Page-flow card holding the garden's meta info: the compassionate
/// tier tagline ("Resting — quiet days for the soil"), the optional
/// token-balance chip, and the "View patterns →" CTA.
///
/// v1.0 polish (2026-05-10): these elements used to overlay the
/// SkyHeader canvas. The user reported that the floating overlays
/// fought with the sky/plants and were hard to read against the
/// gradient. Pulling them into a normal MbCard below the canvas
/// keeps the SkyHeader visually clean and gives the meta info a
/// readable home.
class GardenSummaryRow extends StatelessWidget {
  const GardenSummaryRow({super.key, required this.state, this.tokenChip});

  final GardenState state;

  /// Optional token-balance widget rendered to the left of the
  /// "View patterns" CTA. The garden screen passes a `_GardenTokenChip`;
  /// other surfaces (tests, harvest history) can omit it.
  final Widget? tokenChip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mb = theme.extension<MbColors>()!;
    return MbCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Garden today',
                  style: MbFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: mb.textDim,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
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
            ),
          ),
          if (tokenChip != null) ...[const SizedBox(width: 12), tokenChip!],
          const SizedBox(width: 12),
          _ViewPatternsButton(onTap: () => context.go('/analytics')),
        ],
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
