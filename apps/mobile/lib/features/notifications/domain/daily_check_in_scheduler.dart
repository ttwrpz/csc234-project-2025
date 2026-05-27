/// Schedules (or cancels) the self-set daily check-in local notification.
///
/// Abstract so the presentation controller depends on the behaviour, not
/// the `flutter_local_notifications` plugin. The data layer provides the
/// real platform-bound implementation; widget/unit tests inject a fake
/// recorder so no platform channel is touched. Pure-Dart by design — no
/// Flutter or Firebase imports.
abstract class DailyCheckInScheduler {
  /// Requests OS notification permission (Android 13+ POST_NOTIFICATIONS),
  /// then cancels any prior daily check-in and arms a fresh repeating
  /// reminder at [hour]:[minute] local wall-clock time.
  ///
  /// Returns `true` when the reminder is armed, `false` when permission
  /// was denied or the platform has no local-notification support (e.g.
  /// Web). Never throws to the caller; failures resolve to `false`.
  Future<bool> schedule({required int hour, required int minute});

  /// Cancels the armed daily check-in, if any. Idempotent and safe to
  /// call when nothing is scheduled.
  Future<void> cancel();
}
