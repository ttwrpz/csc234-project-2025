import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Small token-cost chip rendered on the locked-skin card in the
/// [SkinModalSheet]. Pairs a flower-token icon with the integer cost,
/// dimmed when the user cannot afford it.
///
/// Icon choice: `Icons.local_florist` — matches the [TokenBalanceChip]
/// so the visual vocabulary is consistent across the modal (the chip in
/// the header reads "you have N tokens"; the chips on each locked skin
/// read "this costs M tokens"). CLAUDE.md "no mood-contingent rewards"
/// rule and ADR-0010 §7 — never a coin/money glyph.
///
/// Visual states (TC-8):
///   * affordable → primary border + filled icon at full opacity.
///   * unaffordable → muted border + low-opacity icon + low-opacity
///     text. Still legible (WCAG AA contrast is preserved by leaning
///     on `mb.textDim`), just visually distinct from the affordable
///     row.
///
/// Semantics: announced as `'<cost> tokens to unlock'` or, when
/// unaffordable, `'<cost> tokens to unlock, you have <balance>'`.
class LockedSkinChip extends StatelessWidget {
  const LockedSkinChip({
    super.key,
    required this.cost,
    required this.affordable,
    this.userBalance,
  });

  /// Token cost of the skin (≥ 0).
  final int cost;

  /// `true` when the user's current balance is ≥ [cost]. Controls the
  /// chip's visual treatment.
  final bool affordable;

  /// User's current balance — only included in the Semantics label when
  /// the chip is rendered as unaffordable, so screen reader users hear
  /// both the price AND why the button is dimmed.
  final int? userBalance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mb = theme.extension<MbColors>()!;
    final primary = theme.colorScheme.primary;
    final iconColor = affordable
        ? primary
        : primary.withValues(alpha: 0.45);
    // v1.5 final polish — keep the price text at full strength even when
    // unaffordable so the cost is always legible (was mb.textDim, which
    // stacked with the alpha-dimmed background and dropped contrast
    // below the WCAG 4.5:1 floor in both light and dark themes). The
    // unaffordable state is now communicated via the icon + border
    // opacity instead, leaving the number itself readable.
    final textColor = mb.text;
    final borderColor = affordable
        ? primary.withValues(alpha: 0.30)
        : mb.textDim.withValues(alpha: 0.30);

    final semanticsLabel = affordable || userBalance == null
        ? '$cost tokens to unlock'
        : '$cost tokens to unlock, you have $userBalance';

    return Semantics(
      label: semanticsLabel,
      container: true,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            // v1.5 final polish — drop the alpha on unaffordable so the
            // background stays opaque. The dimming cue lives in the
            // border + icon alpha only; the chip's text contrast is now
            // ≥ 4.5:1 in both themes regardless of affordable state.
            color: mb.card,
            borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusFull),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_florist, size: 13, color: iconColor),
              const SizedBox(width: 5),
              Text(
                '$cost',
                style: MbFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
