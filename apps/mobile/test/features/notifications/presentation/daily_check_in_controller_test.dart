import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/notifications/data/datasources/daily_check_in_scheduler_impl.dart';
import 'package:moodbloom/features/notifications/data/datasources/notifications_preference_datasource.dart';
import 'package:moodbloom/features/notifications/data/providers.dart';
import 'package:moodbloom/features/notifications/domain/daily_check_in_scheduler.dart';
import 'package:moodbloom/features/notifications/presentation/controllers/daily_check_in_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records scheduler calls without touching a platform channel.
/// [scheduleResult] controls whether `schedule` reports the reminder as
/// armed (true) or permission-denied (false).
class _FakeScheduler implements DailyCheckInScheduler {
  bool scheduleResult = true;
  final List<({int hour, int minute})> scheduleCalls = [];
  int cancelCalls = 0;

  @override
  Future<bool> schedule({required int hour, required int minute}) async {
    scheduleCalls.add((hour: hour, minute: minute));
    return scheduleResult;
  }

  @override
  Future<void> cancel() async => cancelCalls++;
}

Future<ProviderContainer> _container(
  _FakeScheduler scheduler, {
  Map<String, Object>? prefs,
}) async {
  SharedPreferences.setMockInitialValues(prefs ?? {});
  final sp = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      notificationsPreferenceDatasourceProvider.overrideWithValue(
        NotificationsPreferenceDatasource(sp),
      ),
      dailyCheckInSchedulerProvider.overrideWithValue(scheduler),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('DailyCheckInController', () {
    test('initial state is off at the 21:30 default', () async {
      final container = await _container(_FakeScheduler());
      final state = container.read(dailyCheckInControllerProvider);
      expect(state.enabled, isFalse);
      expect(state.hour, defaultDailyCheckInHour);
      expect(state.minute, defaultDailyCheckInMinute);
    });

    test('hydrates from persisted prefs', () async {
      final container = await _container(
        _FakeScheduler(),
        prefs: const {
          'notifications.daily_check_in_enabled': true,
          'notifications.daily_check_in_hour': 7,
          'notifications.daily_check_in_minute': 15,
        },
      );
      final state = container.read(dailyCheckInControllerProvider);
      expect(state.enabled, isTrue);
      expect(state.hour, 7);
      expect(state.minute, 15);
    });

    test('enable arms the scheduler at the current time and persists', () async {
      final scheduler = _FakeScheduler();
      final container = await _container(scheduler);
      final notifier = container.read(dailyCheckInControllerProvider.notifier);

      await notifier.setEnabled(true);

      expect(scheduler.scheduleCalls, [(hour: 21, minute: 30)]);
      expect(container.read(dailyCheckInControllerProvider).enabled, isTrue);
      final sp = await SharedPreferences.getInstance();
      expect(sp.getBool('notifications.daily_check_in_enabled'), isTrue);
    });

    test('permission denied keeps the toggle off and unpersisted', () async {
      final scheduler = _FakeScheduler()..scheduleResult = false;
      final container = await _container(scheduler);
      final notifier = container.read(dailyCheckInControllerProvider.notifier);

      await notifier.setEnabled(true);

      expect(container.read(dailyCheckInControllerProvider).enabled, isFalse);
      final sp = await SharedPreferences.getInstance();
      expect(sp.getBool('notifications.daily_check_in_enabled'), isFalse);
    });

    test('disable cancels the scheduler and persists off', () async {
      final scheduler = _FakeScheduler();
      final container = await _container(
        scheduler,
        prefs: const {'notifications.daily_check_in_enabled': true},
      );
      final notifier = container.read(dailyCheckInControllerProvider.notifier);

      await notifier.setEnabled(false);

      expect(scheduler.cancelCalls, 1);
      expect(container.read(dailyCheckInControllerProvider).enabled, isFalse);
      final sp = await SharedPreferences.getInstance();
      expect(sp.getBool('notifications.daily_check_in_enabled'), isFalse);
    });

    test('changing time while on re-arms the scheduler', () async {
      final scheduler = _FakeScheduler();
      final container = await _container(
        scheduler,
        prefs: const {'notifications.daily_check_in_enabled': true},
      );
      final notifier = container.read(dailyCheckInControllerProvider.notifier);

      await notifier.setTime(hour: 8, minute: 0);

      expect(scheduler.scheduleCalls, [(hour: 8, minute: 0)]);
      final state = container.read(dailyCheckInControllerProvider);
      expect(state.hour, 8);
      expect(state.minute, 0);
    });

    test('changing time while off persists but does not schedule', () async {
      final scheduler = _FakeScheduler();
      final container = await _container(scheduler);
      final notifier = container.read(dailyCheckInControllerProvider.notifier);

      await notifier.setTime(hour: 6, minute: 45);

      expect(scheduler.scheduleCalls, isEmpty);
      final sp = await SharedPreferences.getInstance();
      expect(sp.getInt('notifications.daily_check_in_hour'), 6);
      expect(sp.getInt('notifications.daily_check_in_minute'), 45);
    });
  });
}
