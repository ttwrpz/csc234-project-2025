import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/notification_failure.dart';
import '../controllers/notifications_controller.dart';

/// SwitchListTile for the cheer-up reminders preference. Lives inside
/// the settings screen's PREFERENCES zone (above SECURITY).
///
/// Behaviour:
/// - Reflects the controller's current state (defaults `true` per O13).
/// - On enable: defers to the controller, which requests OS permission
///   first. If denied, the toggle stays off and a compassionate
///   imperative SnackBar surfaces — never "You must…".
/// - The switch is briefly disabled while a write is in flight so the
///   user can't double-tap into a half-applied state.
class NotificationsToggleTile extends ConsumerWidget {
  const NotificationsToggleTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsControllerProvider);

    // Surface a one-shot SnackBar after a failure. We listen rather than
    // build-time read so re-renders triggered by other state shifts
    // don't re-fire the toast.
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

    return SwitchListTile(
      secondary: const Icon(Icons.notifications_active_outlined),
      title: const Text('Cheer-up reminders'),
      subtitle: const Text(
        'Gentle nudges if your week looks heavy. Off until you grant '
        'notification permission.',
      ),
      value: state.enabled,
      onChanged: state.isPersisting
          ? null
          : (v) => ref
                .read(notificationsControllerProvider.notifier)
                .setEnabled(v),
    );
  }

  void _showFailureSnack(BuildContext context, NotificationFailure failure) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(failure.message)));
  }
}
