import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Quiet footer that surfaces only after the 10-day escalation
/// threshold is reached (`InterventionState.escalated == true`). Per
/// CLAUDE.md "Copy rules", **the hotline is footer-only** and must
/// never be a primary CTA — this widget is a soft note, not an action.
///
/// The exact wording is locked in CLAUDE.md and may not be paraphrased.
class HotlineFooter extends StatelessWidget {
  const HotlineFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final theme = Theme.of(context);

    return Semantics(
      label:
          'A gentle note. If it helps to talk, the Thai Mental Health '
          'Hotline is free at 1323, 24 hours.',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: mb.softCoral,
          borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusLg),
          border: Border.all(
            color: MoodBloomColors.coral.withValues(alpha: 0x55 / 255),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A gentle note',
              style: theme.textTheme.titleSmall?.copyWith(
                color: mb.text,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                style: theme.textTheme.bodySmall?.copyWith(
                  color: mb.text,
                  height: 1.55,
                ),
                children: const [
                  TextSpan(
                    text:
                        'If it helps to talk, the Thai Mental Health Hotline '
                        'is free at ',
                  ),
                  TextSpan(
                    text: '1323',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: ', 24 hours.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
