import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/providers.dart';
import '../../data/datasources/notifications_preference_datasource.dart';
import '../../data/providers.dart';
import '../../domain/fcm_token_repository.dart';
import '../../domain/notification_failure.dart';

/// View-state of the cheer-up reminders toggle.
///
/// Mirrors the [NotificationsPreferenceDatasource]'s local cache for
/// instant rendering on cold start (no Firestore round-trip), and
/// reconciles with the remote `users/{uid}/settings/notifications.tokens`
/// document over the [FcmTokenRepository.watchSettings] stream once a
/// signed-in user is available.
class NotificationsToggleState {
  const NotificationsToggleState({
    required this.enabled,
    this.isPersisting = false,
    this.lastError,
  });

  /// Cheer-up reminders enabled? Reflects the most recent successful
  /// write (local mirror or remote echo, whichever is fresher).
  final bool enabled;

  /// `true` while a write is in flight — used to disable the switch and
  /// render a small spinner so the user doesn't double-tap.
  final bool isPersisting;

  /// Surfaced once after a failure so the UI can show a SnackBar.
  /// Cleared when the user successfully re-toggles or dismisses.
  final NotificationFailure? lastError;

  NotificationsToggleState copyWith({
    bool? enabled,
    bool? isPersisting,
    NotificationFailure? lastError,
    bool clearError = false,
  }) => NotificationsToggleState(
    enabled: enabled ?? this.enabled,
    isPersisting: isPersisting ?? this.isPersisting,
    lastError: clearError ? null : (lastError ?? this.lastError),
  );
}

class NotificationsController extends Notifier<NotificationsToggleState> {
  /// Synchronous preference datasource if SharedPreferences has resolved,
  /// `null` during the brief window between provider-scope init and the
  /// FutureProvider's first emission. While null we treat the toggle as
  /// `true` per O13.
  NotificationsPreferenceDatasource? get _preference =>
      ref.read(notificationsPreferenceDatasourceProvider);

  @override
  NotificationsToggleState build() {
    return NotificationsToggleState(
      enabled: _preference?.isCheerUpEnabled() ?? true,
    );
  }

  /// Handles a user tap on the toggle.
  ///
  /// On enable: requests OS permission, registers an FCM token, and
  /// flips the Firestore flag. If permission is denied the toggle reverts
  /// and [state.lastError] is set so the UI can surface the SnackBar.
  ///
  /// On disable: flips the Firestore flag immediately. Token rows are
  /// kept around (cheap, multi-device) so re-enabling later does not
  /// re-prompt for permission on devices that already granted it.
  Future<void> setEnabled(bool enabled) async {
    final repo = ref.read(fcmTokenRepositoryProvider);
    final uid = ref.read(currentUserStreamProvider).value?.uid;
    final preference = _preference;
    if (uid == null || uid.isEmpty) {
      // Not signed in — fall back to the local mirror only. The next
      // post-sign-in bootstrap will reconcile with Firestore.
      await preference?.setCheerUpEnabled(enabled);
      state = state.copyWith(enabled: enabled, clearError: true);
      return;
    }

    state = state.copyWith(isPersisting: true, clearError: true);

    if (enabled) {
      final upsert = await repo.upsertToken(uid: uid);
      switch (upsert) {
        case Err(:final failure):
          state = state.copyWith(
            enabled: false,
            isPersisting: false,
            lastError: failure,
          );
          await preference?.setCheerUpEnabled(false);
          return;
        case Ok():
          break;
      }
    }

    final result = await repo.setEnabled(uid: uid, enabled: enabled);
    state = result.fold(
      ok: (_) => state.copyWith(
        enabled: enabled,
        isPersisting: false,
        clearError: true,
      ),
      err: (f) => state.copyWith(isPersisting: false, lastError: f),
    );
  }

  /// Clears [state.lastError] after the UI has surfaced it (e.g. once
  /// the SnackBar dismisses). Idempotent.
  void acknowledgeError() {
    if (state.lastError == null) return;
    state = state.copyWith(clearError: true);
  }
}

/// Notifier provider for the cheer-up reminders toggle. The underlying
/// [NotificationsPreferenceDatasource] is read from the synchronous
/// `notificationsPreferenceDatasourceProvider`, which `requireValue`s
/// the eager-resolved [SharedPreferences] singleton — so this provider
/// works on the first frame without a bootstrap-time override.
final notificationsControllerProvider =
    NotifierProvider<NotificationsController, NotificationsToggleState>(
      NotificationsController.new,
    );
