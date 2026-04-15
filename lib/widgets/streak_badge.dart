import 'package:flutter/material.dart';
import '../config/theme.dart';

class StreakBadge extends StatelessWidget {
  final int streak;

  const StreakBadge({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: streak > 0
            ? AppColors.accent.withValues(alpha: 0.15)
            : AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: streak > 0 ? AppColors.accent : AppColors.divider,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '\u{1F525}',
            style: TextStyle(fontSize: streak > 0 ? 20 : 16),
          ),
          const SizedBox(width: 6),
          Text(
            '$streak day${streak == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: streak > 0
                      ? AppColors.accent
                      : AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
