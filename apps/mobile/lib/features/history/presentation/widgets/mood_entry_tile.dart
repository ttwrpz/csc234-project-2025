import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../mood/domain/entities/mood_entry.dart';
import '../../../mood/presentation/widgets/mood_kind_adapter.dart';

/// Single row in the History list. Restyled to the Sprint 2 Prototype:
/// 40×40 mood-tinted square with the mood-emotion emoji, mood label +
/// intensity dots + optional lock badge, 2-line clamped note, and a
/// `relative · time` caption. Tap routes to `/history/<id>`.
class MoodEntryTile extends StatelessWidget {
  const MoodEntryTile({super.key, required this.entry, required this.onTap});

  final MoodEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final palette = Theme.of(context).extension<MbMoodPalette>()!;
    final mbKind = entry.mood.mbKind;
    final color = palette.colorOf(mbKind);
    final emoji = palette.emojiOf(mbKind);
    final locked = entry.isLocked();
    final note = entry.text.trim();
    final now = DateTime.now();

    return MbCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(0x33),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.mood.name,
                        style: MbFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: mb.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    MbIntensityDots(value: entry.intensity, color: color),
                    if (locked) ...[
                      const SizedBox(width: 8),
                      const MbLockBadge(small: true),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  note.isEmpty ? '—' : note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: MbFonts.nunito(
                    fontSize: 12,
                    height: 1.45,
                    color: mb.textDim,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_relative(entry.createdAt, now)} · '
                  '${_formatTime(entry.createdAt)}',
                  style: MbFonts.nunito(fontSize: 11, color: mb.textDim),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _relative(DateTime then, DateTime now) {
  final diff = now.difference(then);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${then.year}-${then.month.toString().padLeft(2, '0')}'
      '-${then.day.toString().padLeft(2, '0')}';
}

String _formatTime(DateTime t) {
  final local = t.toLocal();
  final hour = local.hour;
  final minute = local.minute.toString().padLeft(2, '0');
  final h12 = hour == 0
      ? 12
      : hour > 12
      ? hour - 12
      : hour;
  final ampm = hour < 12 ? 'AM' : 'PM';
  return '$h12:$minute $ampm';
}
