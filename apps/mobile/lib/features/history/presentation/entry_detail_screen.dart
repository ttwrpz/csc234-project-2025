import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../mood/data/providers.dart';
import '../../mood/domain/entities/mood_entry.dart';
import '../../mood/presentation/widgets/mood_kind_adapter.dart';
import 'widgets/entry_attachments.dart';

/// Entry detail screen with a back-icon header, optional soft-coral lock
/// banner, the entry body inside an [MbCard] with an emoji square +
/// intensity dots, and an Edit/Delete row (gated by the 24h immutability
/// rule).
class EntryDetailScreen extends ConsumerWidget {
  const EntryDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryAsync = ref.watch(moodEntryByIdProvider(id));
    final mb = Theme.of(context).extension<MbColors>()!;

    return Scaffold(
      backgroundColor: mb.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            MoodBloomSpacing.pagePadding,
            MoodBloomSpacing.pagePadding,
            MoodBloomSpacing.pagePadding,
            MoodBloomSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(onBack: () => _onBack(context)),
              const SizedBox(height: MoodBloomSpacing.md),
              Expanded(
                child: entryAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => const _NotFound(),
                  data: (entry) =>
                      entry == null ? const _NotFound() : _Detail(entry: entry),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/history');
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Row(
      children: [
        MbIconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
          semanticLabel: 'Back',
        ),
        const SizedBox(width: 10),
        Text(
          'Entry',
          style: MbFonts.fraunces(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: mb.text,
          ),
        ),
      ],
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.entry});
  final MoodEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mb = theme.extension<MbColors>()!;
    final palette = theme.extension<MbMoodPalette>()!;
    final mbKind = entry.mood.mbKind;
    final color = palette.colorOf(mbKind);
    final emoji = palette.emojiOf(mbKind);
    final locked = entry.isLocked();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (locked) ...[
          _LockBanner(),
          const SizedBox(height: MoodBloomSpacing.md),
        ],
        MbCard(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: mb.card,
            border: Border.all(color: mb.line),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: color.withAlpha(0x33),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 30)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.mood.name,
                          style: MbFonts.fraunces(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: mb.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        MbIntensityDots(
                          value: entry.intensity,
                          color: color,
                          dotSize: 7,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'intensity ${entry.intensity} / 5',
                          style: MbFonts.nunito(
                            fontSize: 11,
                            color: mb.textDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: mb.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: entry.text.isEmpty
                    ? Text(
                        'No note.',
                        style: MbFonts.nunito(
                          fontSize: 14,
                          color: mb.textDim,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : Text(
                        entry.text,
                        style: MbFonts.nunito(
                          fontSize: 14,
                          height: 1.6,
                          color: mb.text,
                        ),
                      ),
              ),
              // Attachments — resolved on demand from gs:// URIs to
              // download URLs and rendered as 96 dp thumbnails. Only the
              // mediaRefs list lives on the Firestore document; the
              // widget caches each download URL via a family-keyed
              // FutureProvider so cell rebuilds don't re-fetch.
              if (entry.mediaRefs.isNotEmpty) ...[
                const SizedBox(height: 12),
                EntryAttachments(refs: entry.mediaRefs),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: mb.line)),
                ),
                child: Text(
                  '${_fullDate(entry.createdAt)} · '
                  '${_formatTime(entry.createdAt)}',
                  style: MbFonts.nunito(fontSize: 11, color: mb.textDim),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: MoodBloomSpacing.md),
        _ActionsRow(
          // Lock predicate flips Edit + Delete off once the calendar
          // day rolls over. Same-day entries are mutable.
          locked: locked,
          onEdit: locked
              ? null
              : () => context.go('/log-mood?edit=${entry.id}'),
          onDelete: locked ? null : () => _confirmDelete(context, entry),
        ),
      ],
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
          actions: [
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
    // We use a one-shot ProviderContainer read via the navigator's
    // context — Riverpod's `ProviderScope.containerOf` would also
    // work but pulling the repository directly through the
    // providers is the same dependency edge.
    final scope = ProviderScope.containerOf(context);
    final repo = scope.read(moodRepositoryProvider);
    final result = await repo.delete(userId: entry.userId, id: entry.id);
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        context.go('/history');
      case Err(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }
}

class _LockBanner extends StatelessWidget {
  const _LockBanner();

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mb.softCoral,
        border: Border.all(color: MoodBloomColors.coral.withAlpha(0x55)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, size: 16, color: mb.text),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your history is a record, not a redo. '
              "Add a note to today's entry instead.",
              style: MbFonts.nunito(fontSize: 12, height: 1.5, color: mb.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  const _ActionsRow({required this.locked, this.onEdit, this.onDelete});

  /// True when the entry is past its same-day mutation window. Locked
  /// rows render Edit/Delete in a visually-disabled state regardless
  /// of whether the parent supplied callbacks.
  final bool locked;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mb = theme.extension<MbColors>()!;
    final errorColor = theme.colorScheme.error;
    final disabledEdit = locked || onEdit == null;
    final disabledDelete = locked || onDelete == null;
    return Row(
      children: [
        Expanded(
          child: MbPrimaryButton(
            label: 'Edit',
            onPressed: disabledEdit ? null : onEdit,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 44,
            child: OutlinedButton(
              onPressed: disabledDelete ? null : onDelete,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: disabledDelete ? mb.textDim : errorColor,
                disabledForegroundColor: mb.textDim,
                side: BorderSide(
                  color: disabledDelete ? mb.line : errorColor.withAlpha(0x88),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    MoodBloomSpacing.radiusButton,
                  ),
                ),
                textStyle: MbFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: const Text('Delete'),
            ),
          ),
        ),
      ],
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MoodBloomSpacing.xl),
        child: Text(
          "We couldn't find that entry.",
          style: MbFonts.nunito(fontSize: 14, color: mb.text),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

String _fullDate(DateTime t) {
  final local = t.toLocal();
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
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
