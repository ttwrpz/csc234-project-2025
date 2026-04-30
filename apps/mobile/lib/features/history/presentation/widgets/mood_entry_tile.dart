import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../mood/domain/entities/mood_entry.dart';
import '../../../mood/domain/entities/mood_type.dart';

/// Single row in the History list. Shows mood label, intensity dots, and a
/// short relative timestamp. Tap routes to `/history/<id>`.
class MoodEntryTile extends StatelessWidget {
  const MoodEntryTile({super.key, required this.entry, required this.onTap});

  final MoodEntry entry;
  final VoidCallback onTap;

  static const _moodColors = <MoodType, Color>{
    MoodType.happy: MoodBloomColors.moodHappy,
    MoodType.calm: MoodBloomColors.moodCalm,
    MoodType.okay: MoodBloomColors.moodOkay,
    MoodType.sad: MoodBloomColors.moodSad,
    MoodType.angry: MoodBloomColors.moodAngry,
    MoodType.anxious: MoodBloomColors.moodAnxious,
  };

  @override
  Widget build(BuildContext context) {
    final color = _moodColors[entry.mood] ?? MoodBloomColors.moodOkay;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.4),
        child: Text(
          entry.mood.name[0].toUpperCase(),
          style: TextStyle(color: MoodBloomColors.onSurface),
        ),
      ),
      title: Text(entry.mood.name),
      subtitle: _IntensityRow(intensity: entry.intensity),
      trailing: Text(
        _relativeTime(entry.createdAt, DateTime.now()),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _IntensityRow extends StatelessWidget {
  const _IntensityRow({required this.intensity});
  final int intensity;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final filled = i < intensity;
        return Padding(
          padding: const EdgeInsets.only(right: MoodBloomSpacing.xs),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? MoodBloomColors.seed : MoodBloomColors.outline,
            ),
          ),
        );
      }),
    );
  }
}

String _relativeTime(DateTime then, DateTime now) {
  final diff = now.difference(then);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${then.year}-${then.month.toString().padLeft(2, '0')}-${then.day.toString().padLeft(2, '0')}';
}
