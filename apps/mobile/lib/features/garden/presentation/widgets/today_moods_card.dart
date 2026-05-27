import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../history/presentation/entry_detail_screen.dart';
import '../../../mood/domain/entities/mood_entry.dart';
import '../../../mood/presentation/widgets/mood_kind_adapter.dart';

/// `TODAY · {date}` card on the Garden screen. Header carries the
/// section label + an outlined `+` icon button that routes to
/// `/log-mood`. Body either renders the prototype's empty-state caption
/// or a vertical list of today's mood chips, each paired with the
/// truncated note preview when present.
///
/// Pure presentation - the caller passes [todayEntries] already
/// filtered to today; the widget does no bucketing of its own.
class TodayMoodsCard extends StatelessWidget {
  const TodayMoodsCard({
    super.key,
    required this.todayEntries,
    required this.today,
  });

  /// Entries with `createdAt.toLocal()` falling on [today]. Need not
  /// be sorted; the card sorts newest-first internally.
  final List<MoodEntry> todayEntries;

  /// Local-midnight of the day represented by this card (used in the
  /// header `TODAY · Mon, May 26` label).
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final sorted = [...todayEntries]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return MbCard(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: MbSectionLabel('TODAY · ${_dateLabel(today)}'),
              ),
              MbIconButton(
                icon: const Icon(Icons.add),
                size: MbIconButtonSize.sm,
                semanticLabel: 'Log a new mood',
                onPressed: () => context.go('/log-mood'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (sorted.isEmpty)
            Text(
              "Empty days are fine. Tap + when you're ready.",
              style: MbFonts.nunito(fontSize: 13, color: mb.textDim),
            )
          else
            for (var i = 0; i < sorted.length; i += 1) ...<Widget>[
              if (i > 0) const SizedBox(height: 10),
              _EntryRow(entry: sorted[i], textDim: mb.textDim),
            ],
        ],
      ),
    );
  }

  static String _dateLabel(DateTime d) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final wd = weekdays[(d.weekday - 1).clamp(0, 6)];
    final m = months[(d.month - 1).clamp(0, 11)];
    return '$wd, $m ${d.day}';
  }
}

/// One row inside [TodayMoodsCard]'s entries list: a mood chip + an
/// optional truncated note preview. Tappable - routes to the entry's
/// detail screen.
class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, required this.textDim});

  final MoodEntry entry;
  final Color textDim;

  @override
  Widget build(BuildContext context) {
    final note = entry.text.trim();
    return InkWell(
      borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusSm),
      onTap: () => EntryDetailSheet.show(context, entry.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: <Widget>[
            MbMoodChip(mood: entry.mood.mbKind, size: MbChipSize.sm),
            if (note.isNotEmpty) ...<Widget>[
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MbFonts.nunito(fontSize: 12, color: textDim),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
