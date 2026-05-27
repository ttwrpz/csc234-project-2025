import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/notification_failure.dart';
import '../controllers/notifications_controller.dart';

/// Identifies which per-tier intervention channel a [TierToggleTile]
/// renders. Each tier maps 1:1 to a controller setter, a Firestore
/// field, and the dispatcher's gate in `features/intervention/`.
enum InterventionTier { one, two, three }

/// SwitchListTile for a single intervention tier. Replaces the legacy
/// single-channel `NotificationsToggleTile` in the Settings preferences
/// zone.
///
/// Behaviour:
/// - Renders the controller's current per-tier flag.
/// - On tap, calls the controller's tier-specific setter, which writes
///   the four-flag schema to Firestore (re-deriving `cheerUpEnabled` so
///   the legacy CF stays in lock-step).
/// - The switch is briefly disabled while ANY notification preference
///   write is in flight so the user can't double-tap into a
///   half-applied state.
class TierToggleTile extends ConsumerWidget {
  const TierToggleTile({required this.tier, super.key});

  final InterventionTier tier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsControllerProvider);

    // Surface a one-shot SnackBar after a failure. We listen rather than
    // build-time read so re-renders triggered by other state shifts
    // don't re-fire the toast. The listener fires from EVERY tier tile,
    // so we use `previous.lastError == next.lastError` to dedupe — the
    // first tile that sees the new failure shows the SnackBar, the
    // others stay quiet.
    ref.listen<NotificationsToggleState>(notificationsControllerProvider, (
      previous,
      next,
    ) {
      final failure = next.lastError;
      if (failure == null) return;
      if (previous?.lastError == failure) return;
      _showFailureSnack(context, failure);
      // Schedule the acknowledgement after the frame so the listener
      // doesn't recurse on its own state mutation.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(notificationsControllerProvider.notifier).acknowledgeError();
      });
    });

    final spec = _specFor(tier);
    final value = switch (tier) {
      InterventionTier.one => state.tier1Enabled,
      InterventionTier.two => state.tier2Enabled,
      InterventionTier.three => state.tier3Enabled,
    };
    return SwitchListTile(
      secondary: Icon(spec.icon),
      title: Text(spec.title),
      subtitle: Text(spec.subtitle),
      value: value,
      onChanged: state.isPersisting ? null : (v) => _onChanged(ref, v),
    );
  }

  void _onChanged(WidgetRef ref, bool v) {
    final notifier = ref.read(notificationsControllerProvider.notifier);
    switch (tier) {
      case InterventionTier.one:
        unawaited(notifier.setTier1Enabled(v));
      case InterventionTier.two:
        unawaited(notifier.setTier2Enabled(v));
      case InterventionTier.three:
        unawaited(notifier.setTier3Enabled(v));
    }
  }

  void _showFailureSnack(BuildContext context, NotificationFailure failure) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(failure.message)));
  }

  /// Per-tier copy + icon. Kept inside the widget file so the three
  /// strings live next to the switch that renders them — easier for
  /// the qa-engineer + copy reviewer to audit than spreading them
  /// across a separate constants file.
  ///
  /// Copy follows CLAUDE.md compassionate rules:
  /// - No "Tier 1/2/3" labels (product-internal).
  /// - No clinical labels ("crisis", "depression", "anxiety").
  /// - Tier 3 subtitle names "Hotline 1323" explicitly so users know
  ///   what they're disabling, framed as a "kind voice" rather than a
  ///   medicalised crisis line.
  static _TileSpec _specFor(InterventionTier tier) => switch (tier) {
    InterventionTier.one => const _TileSpec(
      icon: Icons.spa_outlined,
      title: 'Gentle nudges',
      subtitle:
          'Quiet reminders when the garden has been weathering for a while.',
    ),
    InterventionTier.two => const _TileSpec(
      icon: Icons.edit_note_outlined,
      title: 'Journaling check-ins',
      subtitle:
          'A nudge to write things down when several rainy days stack up.',
    ),
    InterventionTier.three => const _TileSpec(
      icon: Icons.volunteer_activism_outlined,
      title: 'Support reminders',
      subtitle:
          'After heavy stretches, a kind voice and Hotline 1323. '
          'Off anytime.',
    ),
  };
}

class _TileSpec {
  const _TileSpec({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}
