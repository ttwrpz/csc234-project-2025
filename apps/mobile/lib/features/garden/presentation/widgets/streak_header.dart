import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Streak header for the garden screen.
///
/// When [streakDays] > 0 we celebrate gently: "N day streak". When it is 0
/// we use compassionate empty-state copy — never streak-shaming. CLAUDE.md
/// "Copy rules" forbid "you broke your streak" / "don't lose your streak"
/// language; the absence of a streak is framed as an invitation, not a loss.
class StreakHeader extends StatelessWidget {
  const StreakHeader({super.key, required this.streakDays});

  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasStreak = streakDays > 0;
    final headline = hasStreak
        ? '$streakDays day streak'
        : 'Plant your first bloom';
    final subtitle = hasStreak
        ? 'Days in a row with a positive mood logged.'
        : 'Log a happy or calm mood to start your garden.';

    return Semantics(
      header: true,
      label: hasStreak
          ? '$streakDays day positive mood streak'
          : 'Empty garden, plant your first bloom',
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MoodBloomSpacing.xl,
          vertical: MoodBloomSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              headline,
              style: theme.textTheme.titleLarge?.copyWith(
                color: MoodBloomColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textScaler: MediaQuery.textScalerOf(context),
            ),
            const SizedBox(height: MoodBloomSpacing.xs),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: MoodBloomColors.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
