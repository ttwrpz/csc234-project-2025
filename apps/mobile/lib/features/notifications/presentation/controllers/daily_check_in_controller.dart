import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/daily_check_in_scheduler_impl.dart';
import '../../data/providers.dart';
import '../../domain/daily_check_in_schedule.dart';

/// Drives the self-set daily check-in reminder: an on/off flag plus the
/// reminder time, persisted to SharedPreferences and mirrored to a real
/// local notification via [DailyCheckInScheduler].
///
/// Cold-start state is hydrated synchronously from the preference
/// datasource so the Settings tile never flashes a stale value. All side
/// effects (permission prompt, schedule, cancel) go through the injected
/// scheduler, which tests override with a fake.
class DailyCheckInController extends Notifier<DailyCheckInSchedule> {
  @override
  DailyCheckInSchedule build() {
    final pref = ref.read(notificationsPreferenceDatasourceProvider);
    return DailyCheckInSchedule(
      enabled: pref?.isDailyCheckInEnabled() ?? false,
      hour: pref?.dailyCheckInHour() ?? defaultDailyCheckInHour,
      minute: pref?.dailyCheckInMinute() ?? defaultDailyCheckInMinute,
    );
  }

  /// Handles the user toggling the reminder on or off.
  ///
  /// On enable: requests OS permission and arms the daily notification. If
  /// permission is denied the toggle reverts to off (and stays
  /// unpersisted-on) so the UI can surface a compassionate hint.
  ///
  /// On disable: cancels the notification and persists the off flag.
  Future<void> setEnabled(bool enabled) async {
    final pref = ref.read(notificationsPreferenceDatasourceProvider);
    final scheduler = ref.read(dailyCheckInSchedulerProvider);

    if (!enabled) {
      await scheduler.cancel();
      await pref?.setDailyCheckInEnabled(false);
      state = state.copyWith(enabled: false);
      return;
    }

    // Web has no local-notification plugin, so the scheduler can never
    // "arm" there. Persist the intent and flip the switch anyway: the
    // preference syncs to the user's Android device, where the scheduler
    // actually fires the reminder. Gating the toggle on a platform that
    // can never arm is the bug that made the switch snap back to off.
    if (kIsWeb) {
      await pref?.setDailyCheckInEnabled(true);
      state = state.copyWith(enabled: true);
      return;
    }

    final armed = await scheduler.schedule(
      hour: state.hour,
      minute: state.minute,
    );
    await pref?.setDailyCheckInEnabled(armed);
    state = state.copyWith(enabled: armed);
  }

  /// Handles the user picking a new reminder time. Persists the time
  /// unconditionally; re-arms the notification only when the reminder is
  /// currently on.
  Future<void> setTime({required int hour, required int minute}) async {
    final pref = ref.read(notificationsPreferenceDatasourceProvider);
    await pref?.setDailyCheckInTime(hour: hour, minute: minute);
    state = state.copyWith(hour: hour, minute: minute);

    // Nothing to re-arm when off, or on web (no local-notification
    // plugin - the persisted time still syncs to the mobile device).
    if (!state.enabled || kIsWeb) return;

    final scheduler = ref.read(dailyCheckInSchedulerProvider);
    final armed = await scheduler.schedule(hour: hour, minute: minute);
    if (armed) return;
    // Re-arm failed (permission revoked between sessions): reflect the
    // off state so the toggle and the OS stay in agreement.
    await pref?.setDailyCheckInEnabled(false);
    state = state.copyWith(enabled: false);
  }
}

/// Notifier provider for the daily check-in reminder. Reads the
/// synchronous preference datasource the same way
/// `notificationsControllerProvider` does, so it works on the first frame
/// without a bootstrap-time override.
final dailyCheckInControllerProvider =
    NotifierProvider<DailyCheckInController, DailyCheckInSchedule>(
      DailyCheckInController.new,
    );
