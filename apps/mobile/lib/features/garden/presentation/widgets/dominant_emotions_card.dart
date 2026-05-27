import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../mood/domain/entities/mood_entry.dart';
import '../../../mood/domain/entities/mood_type.dart';
import '../../../mood/presentation/widgets/mood_kind_adapter.dart';

/// `DOMINANT EMOTIONS` card: section label + up to three wrap-laid
/// mood chips computed from the week's entries (most frequent first;
/// ties broken by recency).
///
/// On weeks with no entries the card renders an empty-state caption so
/// the right column stays balanced visually instead of collapsing.
class DominantEmotionsCard extends StatelessWidget {
  const DominantEmotionsCard({
    super.key,
    required this.weekEntries,
    this.maxChips = 3,
  });

  /// All entries falling within the active week. The card counts each
  /// mood, sorts by frequency desc, and renders the top [maxChips]
  /// distinct moods.
  final List<MoodEntry> weekEntries;

  /// Cap on the number of chips. Defaults to 3 per the prototype.
  final int maxChips;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final top = _topMoods(weekEntries, maxChips);

    return MbCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const MbSectionLabel('DOMINANT EMOTIONS'),
          const SizedBox(height: 10),
          if (top.isEmpty)
            Text(
              "Your week's emotions will appear here once you start logging.",
              style: MbFonts.nunito(fontSize: 13, color: mb.textDim),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final mood in top)
                  MbMoodChip(mood: mood.mbKind, size: MbChipSize.md),
              ],
            ),
        ],
      ),
    );
  }

  /// Counts entries per mood, returns the top [n] moods by frequency.
  /// Ties broken by which mood had the most-recent entry.
  static List<MoodType> _topMoods(List<MoodEntry> entries, int n) {
    if (entries.isEmpty) return const <MoodType>[];
    final counts = <MoodType, int>{};
    final newestByMood = <MoodType, DateTime>{};
    for (final e in entries) {
      counts[e.mood] = (counts[e.mood] ?? 0) + 1;
      final cur = newestByMood[e.mood];
      if (cur == null || e.createdAt.isAfter(cur)) {
        newestByMood[e.mood] = e.createdAt;
      }
    }
    final ranked = counts.keys.toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        if (byCount != 0) return byCount;
        return newestByMood[b]!.compareTo(newestByMood[a]!);
      });
    return ranked.take(n).toList(growable: false);
  }
}
