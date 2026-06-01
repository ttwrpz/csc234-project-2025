import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../mood/domain/entities/mood_entry.dart';
import '../../../mood/presentation/widgets/mood_kind_adapter.dart';
import '../../domain/entities/flower_species.dart';
import 'flower_sprite.dart';

/// Bottom-sheet preview of a single mood entry - opens when the user
/// taps a flower in the garden canvas.
///
/// Shows:
///   * The species sprite at a generous size (60 dp).
///   * Mood label + intensity dots row.
///   * Date / time the entry was logged.
///   * A 3-line clamped excerpt of the entry text (or "-" when empty).
///   * "Open entry" CTA that routes to `/history/<id>` for the full
///     editable detail.
///
/// Deliberately lightweight - the full mood-entry detail experience
/// (edit, delete, media gallery) already lives on `EntryDetailScreen`
/// at `/history/<id>`. This modal is a tap-preview surface that lets
/// the user identify a flower without losing their place on the home
/// page.
class PerFlowerDetailModal extends StatelessWidget {
  const PerFlowerDetailModal({
    super.key,
    required this.entry,
    this.speciesAccent,
  });

  final MoodEntry entry;

  /// Optional per-species petal accent for the header sprite. When the
  /// user has equipped a per-species skin for this entry's species, the
  /// live opener passes the resolved colour so the preview matches the
  /// garden. `null` (the default, and the value all widget tests use)
  /// falls back to the species' mood colour - precedence rule 1 vs 3 in
  /// [FlowerSprite].
  final Color? speciesAccent;

  /// Stable key on the ConstrainedBox that caps the centered-dialog
  /// width. Exposed so widget tests can assert the chosen breakpoint
  /// without false-positives from Dialog's internal sizing layers.
  @visibleForTesting
  static const Key dialogConstraintsKey = ValueKey(
    'perFlowerDetailModal.dialogConstraints',
  );

  /// Breakpoints mirror `_AppShell._tabletMin` / `_desktopMin` in
  /// `apps/mobile/lib/app/router.dart`. Keep these aligned with the
  /// shell so the chrome we pick here matches the navigation layout at
  /// the same viewport width.
  static const double _tabletMin = 600;
  static const double _desktopMin = 900;

  /// Dialog max-width on desktop. 560 dp comfortably holds the
  /// sprite + title row at top and the 3-line note card below without
  /// padding the columns out - this modal carries less information than
  /// the skin grid, so it doesn't need the grid's wider 640 dp cap.
  static const double _desktopDialogMaxWidth = 560;

  /// Dialog max-width on tablet. 480 dp is the spot where the sprite +
  /// title row still reads as a single tight unit; wider feels lonely.
  static const double _tabletDialogMaxWidth = 480;

  /// Cap the dialog at 80% of the viewport so the home page underneath
  /// stays peeking through - same compositional cue the phone bottom
  /// sheet gives via its mainAxisSize.min Column.
  static const double _dialogMaxHeightFraction = 0.8;

  /// Responsive launcher - bottom sheet on phone, centered dialog on
  /// tablet + desktop. Picks presentation off `MediaQuery.sizeOf` at the
  /// call site so a window-resize before the tap closes is respected.
  static Future<void> show(
    BuildContext context,
    MoodEntry entry, {
    Color? speciesAccent,
  }) {
    final size = MediaQuery.sizeOf(context);
    if (size.width < _tabletMin) {
      return showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            PerFlowerDetailModal(entry: entry, speciesAccent: speciesAccent),
      );
    }
    final dialogMaxWidth = size.width >= _desktopMin
        ? _desktopDialogMaxWidth
        : _tabletDialogMaxWidth;
    final dialogMaxHeight = size.height * _dialogMaxHeightFraction;
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusSky),
        ),
        child: ConstrainedBox(
          key: dialogConstraintsKey,
          constraints: BoxConstraints(
            maxWidth: dialogMaxWidth,
            maxHeight: dialogMaxHeight,
          ),
          child: PerFlowerDetailModal(
            entry: entry,
            speciesAccent: speciesAccent,
          ),
        ),
      ),
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
    // Bottom-sheet vs centered-dialog mode. The drag-handle and the
    // safe-area inset only make sense in the sheet presentation; in a
    // dialog they read as misplaced furniture.
    final isPhoneWidth = MediaQuery.sizeOf(context).width < _tabletMin;
    final bottomPad = isPhoneWidth
        ? MediaQuery.viewPaddingOf(context).bottom + MoodBloomSpacing.lg
        : MoodBloomSpacing.lg;

    return Container(
      decoration: BoxDecoration(
        color: mb.bg,
        // Only round the top corners when we're in the bottom-sheet
        // presentation. In the dialog the parent `Dialog` already clips
        // with a uniform radius so any inner rounding would double up
        // visually.
        borderRadius: isPhoneWidth
            ? const BorderRadius.vertical(
                top: Radius.circular(MoodBloomSpacing.radiusSky),
              )
            : null,
      ),
      padding: EdgeInsets.fromLTRB(
        MoodBloomSpacing.pagePadding,
        12,
        MoodBloomSpacing.pagePadding,
        bottomPad,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPhoneWidth) ...[
            // Handle - only meaningful in the bottom-sheet idiom.
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
          ],
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
                child: FlowerSprite(
                  species: species,
                  size: 42,
                  tint: color,
                  speciesAccent: speciesAccent,
                ),
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
              note.isEmpty ? '-' : note,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: MbFonts.nunito(fontSize: 13, height: 1.5, color: mb.text),
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
