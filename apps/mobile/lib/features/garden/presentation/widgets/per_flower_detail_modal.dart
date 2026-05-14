import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../mood/domain/entities/mood_entry.dart';
import '../../../mood/presentation/widgets/mood_kind_adapter.dart';
import '../../domain/entities/flower_species.dart';
import 'flower_sprite.dart';

/// Bottom-sheet preview of a single mood entry — opens when the user
/// taps a flower in the garden canvas (TC-7).
///
/// Shows:
///   * The species sprite at a generous size (60 dp).
///   * Mood label + intensity dots row.
///   * Date / time the entry was logged.
///   * A 3-line clamped excerpt of the entry text (or "—" when empty).
///   * "Open entry" CTA that routes to `/history/<id>` for the full
///     editable detail.
///
/// Deliberately lightweight — the full mood-entry detail experience
/// (edit, delete, media gallery) already lives on `EntryDetailScreen`
/// at `/history/<id>`. This modal is a tap-preview surface that lets
/// the user identify a flower without losing their place on the home
/// page.
class PerFlowerDetailModal extends StatelessWidget {
  const PerFlowerDetailModal({super.key, required this.entry});

  final MoodEntry entry;

  /// Convenience launcher.
  static Future<void> show(BuildContext context, MoodEntry entry) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => PerFlowerDetailModal(entry: entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mb = theme.extension<MbColors>()!;
    final palette = theme.extension<MbMoodPalette>()!;
    final color = palette.colorOf(entry.mood.mbKind);
    final species = FlowerSpecies.forMood(entry.mood);
    final note = entry.text.trim();

    return Container(
      decoration: BoxDecoration(
        color: mb.bg,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(MoodBloomSpacing.radiusSky),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        MoodBloomSpacing.pagePadding,
        12,
        MoodBloomSpacing.pagePadding,
        MediaQuery.viewPaddingOf(context).bottom + MoodBloomSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: mb.textDim.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: FlowerSprite(species: species, size: 42, tint: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _moodTitle(entry),
                      style: MbFonts.fraunces(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: mb.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        MbIntensityDots(value: entry.intensity, color: color),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(entry.createdAt),
                          style: MbFonts.nunito(
                            fontSize: 12,
                            color: mb.textDim,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: mb.card,
              borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusMd),
            ),
            child: Text(
              note.isEmpty ? '—' : note,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: MbFonts.nunito(
                fontSize: 13,
                height: 1.5,
                color: mb.text,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go('/history/${entry.id}');
                  },
                  child: const Text('Open entry'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _moodTitle(MoodEntry e) {
    final name = e.mood.name;
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }

  static String _formatDate(DateTime dt) {
    final local = dt.toLocal();
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
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${months[local.month - 1]} ${local.day}, $hour:$minute';
  }
}
