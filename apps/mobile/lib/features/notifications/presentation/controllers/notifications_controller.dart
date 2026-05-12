import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/providers.dart';
import '../../data/datasources/notifications_preference_datasource.dart';
import '../../data/providers.dart';
import '../../domain/fcm_token_repository.dart';
import '../../domain/notification_failure.dart';
import '../../domain/notifications_settings.dart';

/// View-state of the notification preference toggles. Carries the legacy
/// cheer-up boolean alongside the three new per-tier flags introduced in
/// S5 Day 2 (HB-007 follow-up).
///
/// The cold-start initial values come from two places:
/// - [enabled] (the cheer-up shim) is hydrated synchronously from
///   [NotificationsPreferenceDatasource] (SharedPreferences) so the UI
///   never flashes a stale value.
/// - [tier1Enabled] / [tier2Enabled] / [tier3Enabled] start `true` and
///   are reconciled against Firestore via [watchSettings] as soon as a
///   signed-in user is available.
class NotificationsToggleState {
  const NotificationsToggleState({
    required this.enabled,
    this.tier1Enabled = true,
    this.tier2Enabled = true,
    this.tier3Enabled = true,
    this.isPersisting = false,
    this.lastError,
  });

  /// Cheer-up reminders enabled? Reflects the most recent successful
  /// write (local mirror or remote echo, whichever is fresher).
  ///
  /// Re-derived from the three tier flags on every per-tier write —
  /// `enabled` flips false only when ALL three tier flags are off, so
  /// the legacy `sendCheerUpPush` Cloud Function stops firing only
  /// when the user has opted out of every channel.
  final bool enabled;

  /// Tier 1 (gentle nudge) channel enabled. Surfaces the dispatcher's
  /// "is this delivery channel open" flag to the UI.
  final bool tier1Enabled;

  /// Tier 2 (journaling check-in) channel enabled.
  final bool tier2Enabled;

  /// Tier 3 (Hotline 1323 reminder) channel enabled.
  final bool tier3Enabled;

  /// `true` while a write is in flight — used to disable switches and
  /// render a small spinner so the user doesn't double-tap.
  final bool isPersisting;

  /// Surfaced once after a failure so the UI can show a SnackBar.
  /// Cleared when the user successfully re-toggles or dismisses.
  final NotificationFailure? lastError;

  NotificationsToggleState copyWith({
    bool? enabled,
    bool? tier1Enabled,
    bool? tier2Enabled,
    bool? tier3Enabled,
    bool? isPersisting,
    NotificationFailure? lastError,
    bool clearError = false,
  }) => NotificationsToggleState(
    enabled: enabled ?? this.enabled,
    tier1Enabled: tier1Enabled ?? this.tier1Enabled,
    tier2Enabled: tier2Enabled ?? this.tier2Enabled,
    tier3Enabled: tier3Enabled ?? this.tier3Enabled,
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
    // Subscribe to the remote settings stream so the three tier flags
    // stay in sync with Firestore (and so a migration write that lands
    // on first read flows back through `_applyRemoteSettings`).
    //
    // Listen to auth state first (cheap — no Firestore yet). The
    // Firestore-backed repo is read lazily inside the auth listener so
    // unauthenticated test fixtures that override
    // `currentUserStreamProvider` to emit `null` never trigger the
    // Firestore provider's initialization path. This mirrors the
    // pre-S5 lazy-read shape of the controller.
    ref.listen(currentUserStreamProvider, (_, async) {
      final uid = async.value?.uid;
      if (uid == null || uid.isEmpty) return;
      _attachRemoteStream(uid);
    }, fireImmediately: true);
    return NotificationsToggleState(
      // Default flipped to `false` in v1.0 polish (2026-05-10): cheer-
      // up reminders must be off until the user explicitly grants
      // notification permission. See `NotificationsPreferenceDatasource`
      // docstring for the rationale.
      enabled: _preference?.isCheerUpEnabled() ?? false,
    );
  }

  /// Attaches a Firestore listener for the signed-in user. Idempotent:
  /// re-running cancels the prior subscription via [ref.onDispose].
  void _attachRemoteStream(String uid) {
    final repo = ref.read(fcmTokenRepositoryProvider);
    final stream = repo.watchSettings(uid: uid);
    if (stream == null) return;
    final sub = stream.listen(_applyRemoteSettings);
    ref.onDispose(sub.cancel);
  }

  void _applyRemoteSettings(NotificationsSettings remote) {
    state = state.copyWith(
      enabled: remote.cheerUpEnabled,
      tier1Enabled: remote.tier1Enabled,
      tier2Enabled: remote.tier2Enabled,
      tier3Enabled: remote.tier3Enabled,
    );
  }

  /// Handles a user tap on the legacy cheer-up toggle (kept for
  /// onboarding compatibility — the Settings screen surfaces the three
  /// per-tier toggles instead).
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

  /// Toggles the Tier 1 (gentle nudge) intervention channel. See
  /// [setTier1Enabled] in [FcmTokenRepository] for the cheer-up shim
  /// semantics — turning the last enabled tier off also flips the
  /// legacy `cheerUpEnabled` flag.
  Future<void> setTier1Enabled(bool enabled) async {
    await _setTier(
      tier: _ControllerTier.one,
      enabled: enabled,
      write: (repo, uid) => repo.setTier1Enabled(uid: uid, enabled: enabled),
    );
  }

  /// Toggles the Tier 2 (journaling check-in) intervention channel.
  Future<void> setTier2Enabled(bool enabled) async {
    await _setTier(
      tier: _ControllerTier.two,
      enabled: enabled,
      write: (repo, uid) => repo.setTier2Enabled(uid: uid, enabled: enabled),
    );
  }

  /// Toggles the Tier 3 (Hotline 1323 reminder) intervention channel.
  Future<void> setTier3Enabled(bool enabled) async {
    await _setTier(
      tier: _ControllerTier.three,
      enabled: enabled,
      write: (repo, uid) => repo.setTier3Enabled(uid: uid, enabled: enabled),
    );
  }

  Future<void> _setTier({
    required _ControllerTier tier,
    required bool enabled,
    required Future<Result<void, NotificationFailure>> Function(
      FcmTokenRepository repo,
      String uid,
    )
    write,
  }) async {
    final repo = ref.read(fcmTokenRepositoryProvider);
    final uid = ref.read(currentUserStreamProvider).value?.uid;
    if (uid == null || uid.isEmpty) {
      // Optimistic local update; the next post-sign-in bootstrap will
      // reconcile with Firestore (the watchSettings stream replays the
      // canonical state).
      state = _withTierLocally(tier, enabled, clearError: true);
      return;
    }

    state = state.copyWith(isPersisting: true, clearError: true);
    final result = await write(repo, uid);
    state = result.fold(
      ok: (_) {
        // The remote stream will deliver the authoritative state
        // shortly. Mirror locally so the switch animates immediately
        // rather than waiting for the snapshot round-trip.
        final next = _withTierLocally(
          tier,
          enabled,
          isPersisting: false,
          clearError: true,
        );
        return next.copyWith(
          enabled: next.tier1Enabled || next.tier2Enabled || next.tier3Enabled,
        );
      },
      err: (f) => state.copyWith(isPersisting: false, lastError: f),
    );
  }

  NotificationsToggleState _withTierLocally(
    _ControllerTier tier,
    bool enabled, {
    bool? isPersisting,
    bool clearError = false,
  }) {
    switch (tier) {
      case _ControllerTier.one:
        return state.copyWith(
          tier1Enabled: enabled,
          isPersisting: isPersisting,
          clearError: clearError,
        );
      case _ControllerTier.two:
        return state.copyWith(
          tier2Enabled: enabled,
          isPersisting: isPersisting,
          clearError: clearError,
        );
      case _ControllerTier.three:
        return state.copyWith(
          tier3Enabled: enabled,
          isPersisting: isPersisting,
          clearError: clearError,
        );
    }
  }

  /// Clears [state.lastError] after the UI has surfaced it (e.g. once
  /// the SnackBar dismisses). Idempotent.
  void acknowledgeError() {
    if (state.lastError == null) return;
    state = state.copyWith(clearError: true);
  }
}

/// Private discriminator for the shared `_setTier` helper. Mirrors the
/// data-layer enum but stays local to this file to avoid leaking a
/// presentation-only token across the controller boundary.
enum _ControllerTier { one, two, three }

/// Notifier provider for the cheer-up reminders toggle. The underlying
/// [NotificationsPreferenceDatasource] is read from the synchronous
/// `notificationsPreferenceDatasourceProvider`, which `requireValue`s
/// the eager-resolved [SharedPreferences] singleton — so this provider
/// works on the first frame without a bootstrap-time override.
final notificationsControllerProvider =
    NotifierProvider<NotificationsController, NotificationsToggleState>(
      NotificationsController.new,
    );
