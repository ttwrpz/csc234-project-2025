import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../intervention/presentation/screens/breathing_screen.dart';

/// Compassionate intervention card shown above the weekly bloom bar
/// when the pattern detector trips (`InterventionState.triggered`) and
/// the user has not dismissed it for the current session.
///
/// Copy is locked in CLAUDE.md and may not be paraphrased:
///  * Title: "It's been a heavy week."
///  * Body:  "Want to try a two-minute breathing exercise?"
///  * Reason caption echoes the human-readable form of `pattern.reason`.
///
/// "Try it" opens the breathing modal via [BreathingSheet]. "Not now"
/// calls [onDismiss],
/// which the parent uses to hide the banner for the rest of the session
/// (it does NOT write the cooldown to storage - that flow lives in the
/// pattern detector).
class CheerUpBanner extends StatelessWidget {
  const CheerUpBanner({
    super.key,
    required this.reason,
    required this.onDismiss,
  });

  /// Domain-level reason code from `InterventionState.reason`. We map it
  /// to a sentence below; unknown codes fall back to a generic line.
  final String reason;
  final VoidCallback onDismiss;

  /// Compassionate, present-tense rephrasing of the trigger reason. We
  /// must not surface the raw code (`5_of_7_negative`) to the user.
  static String reasonCaption(String reason) => switch (reason) {
    '5_of_7_negative' => '5 of the last 7 days have felt heavy.',
    '3_consecutive_high_intensity' => 'The last three days have felt heavy.',
    _ => 'A few heavier days in a row.',
  };

  // Foreground color used by the prototype on the coral→sunrise gradient.
  // Kept as a const because the banner is always rendered on the warm
  // gradient regardless of theme brightness (prototype behavior).
  static const _fg = Color(0xFF5A3A2E);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      // Full locked CLAUDE.md sentence + reason caption. Screen readers
      // hear the complete prompt; the parity test asserts the label
      // `startsWith` the locked sentence.
      label:
          "It's been a heavy week. Want to try a two-minute breathing exercise? "
          "${reasonCaption(reason)}",
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MoodBloomColors.coral.withValues(alpha: 0xDD / 255),
              // Sunrise-amber per the prototype's `PALETTE.sunrise`. We
              // don't have a separate sunrise token in design_system, so
              // we use the brand amber at high opacity.
              MoodBloomColors.amber.withValues(alpha: 0xEE / 255),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: MoodBloomColors.coral.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              // The cherry-blossom is purely ornamental - the
              // surrounding Semantics(label:) already covers the full
              // locked sentence. Excluding stops screen readers from
              // announcing "cherry blossom emoji" before the sentence.
              child: ExcludeSemantics(
                child: Text('🌸', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "It's been a heavy week.",
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: _fg,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Want to try a two-minute breathing exercise?',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _fg,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _PillButton(
                        label: 'Try it',
                        background: _fg,
                        foreground: Colors.white,
                        onTap: () => BreathingSheet.show(context),
                      ),
                      const SizedBox(width: 8),
                      _PillButton(
                        label: 'Not now',
                        background: Colors.white.withValues(alpha: 0.5),
                        foreground: _fg,
                        onTap: onDismiss,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reasonCaption(reason),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _fg.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusFull),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusFull),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
