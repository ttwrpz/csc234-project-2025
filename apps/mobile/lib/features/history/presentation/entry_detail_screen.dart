import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../mood/data/providers.dart';
import '../../mood/domain/entities/mood_entry.dart';
import '../../mood/presentation/widgets/mood_kind_adapter.dart';
import 'widgets/entry_attachments.dart';

/// Entry detail, v1.6 prototype-aligned per
/// `screens-extra.jsx > EntryDetailScreen`, presented as a modal
/// (bottom sheet on phone, dialog on tablet+) via [EntryDetailSheet].
///
///   * Modal header: the entry's date in serif (e.g. "Fri, May 23") +
///     a close icon.
///   * Top row: full `MbMoodChip` (size lg) on the left, optional
///     `MbLockBadge` on the right when the 24h immutability window has
///     elapsed.
///   * "NOTE" section label + body text flush to the page.
///   * "ATTACHMENTS" section label + thumbnail strip (only when the
///     entry actually has media).
///   * AI-tinted footer card: lock icon + "Entries become read-only
///     24 hours after logging."
///   * Bottom action row: two ghost buttons - "Edit" (visually
///     disabled when locked) and "Delete" (danger).
class EntryDetailSheet {
  const EntryDetailSheet._();

  /// Opens the entry-detail modal for [id]. Returns when dismissed.
  static Future<void> show(BuildContext context, String id) {
    return MbModalSheet.show<void>(
      context,
      builder: (ctx) => EntryDetailView(id: id),
    );
  }
}

/// Modal body for a single mood entry. Watches `moodEntryByIdProvider`
/// and renders the detail inside an [MbModalScaffold] whose title is the
/// entry's date.
class EntryDetailView extends ConsumerWidget {
  const EntryDetailView({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryAsync = ref.watch(moodEntryByIdProvider(id));
    void close() => Navigator.of(context).pop();

    return entryAsync.when(
      loading: () => MbModalScaffold(
        title: 'Entry',
        onClose: close,
        scrollable: false,
        child: const SizedBox(
          height: 160,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => _NotFound(onClose: close),
      data: (entry) => entry == null
          ? _NotFound(onClose: close)
          : _Detail(entry: entry, onClose: close),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.entry, required this.onClose});

  final MoodEntry entry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final mbKind = entry.mood.mbKind;
    final locked = entry.isLocked();
    final note = entry.text.trim();

    return MbModalScaffold(
      title: _shortDate(entry.createdAt),
      onClose: onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(height: MoodBloomSpacing.sm),
          // Mood chip row - lg pill on the left, optional lock pill
          // on the right.
          Row(
            children: <Widget>[
              MbMoodChip(
                mood: mbKind,
                size: MbChipSize.lg,
                intensity: entry.intensity,
              ),
              const Spacer(),
              if (locked) const MbLockBadge(),
            ],
          ),
          const SizedBox(height: 4),
          // Time-of-day footer - the date is already in the header
          // so this just adds the precise time.
          Text(
            _formatTime(entry.createdAt),
            style: MbFonts.nunito(fontSize: 11, color: mb.textDim),
          ),
          const SizedBox(height: MoodBloomSpacing.lg),
          const MbSectionLabel('NOTE'),
          const SizedBox(height: 6),
          Text(
            note.isEmpty ? 'No note.' : note,
            style: note.isEmpty
                ? MbFonts.nunito(
                    fontSize: 14,
                    color: mb.textDim,
                    fontStyle: FontStyle.italic,
                  )
                : MbFonts.nunito(fontSize: 14, color: mb.text, height: 1.6),
          ),
          if (entry.mediaRefs.isNotEmpty) ...<Widget>[
            const SizedBox(height: MoodBloomSpacing.lg),
            const MbSectionLabel('ATTACHMENTS'),
            const SizedBox(height: 8),
            EntryAttachments(refs: entry.mediaRefs),
          ],
          const SizedBox(height: MoodBloomSpacing.lg),
          const _LockInfoFooter(),
          const SizedBox(height: MoodBloomSpacing.lg),
          _ActionsRow(
            locked: locked,
            onEdit: locked
                ? null
                : () {
                    onClose();
                    context.go('/log-mood?edit=${entry.id}');
                  },
            onDelete: locked ? null : () => _confirmDelete(context, entry),
          ),
        ],
      ),
    );
  }

  static Future<void> _confirmDelete(
    BuildContext context,
    MoodEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: const Text('Delete entry?'),
          content: const Text(
            'This entry will be removed from your history. '
            'You can always log a new mood today.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    final scope = ProviderScope.containerOf(context);
    final repo = scope.read(moodRepositoryProvider);
    final result = await repo.delete(userId: entry.userId, id: entry.id);
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        // Close the modal - the underlying history list / calendar
        // updates live via the mood stream.
        Navigator.of(context).pop();
      case Err(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }
}

/// Soft AI-tinted card explaining the 24-hour immutability rule.
/// Always rendered - the prototype shows this informational footer on
/// every entry so the user learns the rule even before any of their
/// entries lock.
class _LockInfoFooter extends StatelessWidget {
  const _LockInfoFooter();

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: mb.aiBg,
        border: Border.all(color: mb.aiBd),
        borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusCardLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.lock_outline, size: 16, color: mb.textDim),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Entries become read-only 24 hours after logging.',
              style: MbFonts.nunito(
                fontSize: 12,
                color: mb.textDim,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Edit / Delete pair at the bottom of the detail screen. Both are
/// ghost-style; the Edit button drops to ~60% opacity when the entry
/// is past the same-day mutation window so the affordance reads as
/// "visually present but inactive" (matches the prototype's
/// `<GhostBtn full style={{ opacity: 0.6 }}>Edit</GhostBtn>`).
class _ActionsRow extends StatelessWidget {
  const _ActionsRow({required this.locked, this.onEdit, this.onDelete});

  final bool locked;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Opacity(
            opacity: locked ? 0.6 : 1.0,
            child: MbGhostButton(
              label: 'Edit',
              onPressed: locked ? null : onEdit,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: MbGhostButton(
            label: 'Delete',
            danger: true,
            onPressed: locked ? null : onDelete,
          ),
        ),
      ],
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return MbModalScaffold(
      title: 'Entry',
      onClose: onClose,
      scrollable: false,
      child: SizedBox(
        height: 140,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(MoodBloomSpacing.xl),
            child: Text(
              "We couldn't find that entry.",
              style: MbFonts.nunito(fontSize: 14, color: mb.text),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

/// "Fri, May 23" - short weekday + month + day. Year is dropped to
/// match the prototype's `Fri, Apr 26` title.
String _shortDate(DateTime t) {
  final local = t.toLocal();
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
  return '${weekdays[local.weekday - 1]}, '
      '${months[local.month - 1]} ${local.day}';
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
