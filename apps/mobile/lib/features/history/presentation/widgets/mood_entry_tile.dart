import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../mood/domain/entities/mood_entry.dart';
import '../../../mood/presentation/widgets/mood_kind_adapter.dart';

/// Single row in the History list, v1.6 prototype-aligned.
///
/// Each entry renders as its own MbCard with a single horizontal row:
/// the pill-shaped MbMoodChip (mood icon + intensity dots inline), the
/// note excerpt (flex, ellipsis), an optional MbLockBadge when the
/// 24h immutability window has passed, and a chevron_right glyph that
/// signals the row is tappable.
///
/// Layout per `screens-extra.jsx > HistoryListScreen`. The whole row
/// is tappable; the parent supplies the navigation callback so the
/// tile stays presentation-only.
class MoodEntryTile extends StatelessWidget {
  const MoodEntryTile({super.key, required this.entry, required this.onTap});

  final MoodEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final mbKind = entry.mood.mbKind;
    final locked = entry.isLocked();
    final note = entry.text.trim();

    return Semantics(
      button: true,
      label: '${entry.mood.name} entry. ${note.isEmpty ? "No note." : note}',
      child: ExcludeSemantics(
        child: MbCard(
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusCardLg),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  MbMoodChip(
                    mood: mbKind,
                    size: MbChipSize.md,
                    intensity: entry.intensity,
                  ),
                  // Note in the middle when present; otherwise an empty
                  // expander (no "(no note)" placeholder - consistent
                  // with the Today card and the calendar panel).
                  if (note.isNotEmpty)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: MbFonts.nunito(fontSize: 13, color: mb.text),
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  if (locked) ...<Widget>[
                    const SizedBox(width: 8),
                    const MbLockBadge(small: true),
                  ],
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right, size: 18, color: mb.textDim),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
