import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Compact pill that pairs a flower icon with the user's running token
/// balance. Used by the garden screen's top bar (anti-pattern guardrail:
/// visible by default, hideable via the "Show token balance" toggle in
/// Settings — never forced).
///
/// Icon choice: `Icons.local_florist` — the flower glyph echoes the
/// garden metaphor of the wider app and is intentionally NOT a
/// money/coin glyph (CLAUDE.md "no mood-contingent rewards"; tokens
/// unlock cosmetic flower skins, not therapeutic features).
///
/// Semantics: the entire chip is announced as
/// `'<balance> tokens'` — accessibility users get the same signal as
/// sighted users without needing to read the icon. WCAG 2.2 AA contrast
/// is inherited from the active `MbColors` theme; light + dark are both
/// covered without the chip itself picking literals.
class TokenBalanceChip extends StatelessWidget {
  const TokenBalanceChip({super.key, required this.balance});

  /// The user's current accumulated balance (`>= 0`). Bound by the
  /// caller to `tokenBalanceStreamProvider.value.balance`.
  final int balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mb = theme.extension<MbColors>()!;

    return Semantics(
      label: '$balance tokens',
      container: true,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: mb.card,
            borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusFull),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_florist,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                '$balance',
                style: MbFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: mb.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
