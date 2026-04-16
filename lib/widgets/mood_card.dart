import 'package:flutter/material.dart';
import '../models/mood_entry.dart';
import '../models/mood_type.dart';
import '../utils/date_helpers.dart';
import 'sync_indicator.dart';

/// Displays a mood entry as a compact card with emoji, label, text preview,
/// attachment icon, and sync indicator. Supports Hero animation for the emoji.
class MoodCard extends StatelessWidget {
  final MoodEntry entry;
  final VoidCallback onTap;

  const MoodCard({
    super.key,
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final mood = MoodType.fromString(entry.mood);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Mood emoji with Hero
              Hero(
                tag: 'mood_emoji_${entry.id}',
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (mood?.color ?? Colors.grey).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      mood?.emoji ?? '\u{2753}',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          mood?.label ?? entry.mood,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontSize: 15),
                        ),
                        const Spacer(),
                        Text(
                          DateHelpers.formatRelative(entry.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    if (entry.text.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        entry.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (entry.attachmentUrl != null) ...[
                const SizedBox(width: 8),
                Icon(
                  entry.attachmentType == 'video'
                      ? Icons.videocam_rounded
                      : Icons.photo_rounded,
                  size: 20,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ],
              const SizedBox(width: 6),
              SyncIndicator(isSynced: entry.isSynced),
            ],
          ),
        ),
      ),
    );
  }
}
