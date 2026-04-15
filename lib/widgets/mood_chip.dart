import 'package:flutter/material.dart';
import '../models/mood_type.dart';

class MoodChip extends StatelessWidget {
  final MoodType moodType;
  final bool isSelected;
  final VoidCallback onTap;

  const MoodChip({
    super.key,
    required this.moodType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? moodType.color.withValues(alpha: 0.2)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? moodType.color : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              moodType.emoji,
              style: TextStyle(fontSize: isSelected ? 32 : 24),
            ),
            const SizedBox(height: 4),
            Text(
              moodType.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? moodType.color
                        : Theme.of(context).textTheme.bodySmall?.color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
