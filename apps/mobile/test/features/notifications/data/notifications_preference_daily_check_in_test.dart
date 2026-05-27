import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/notifications/data/datasources/notifications_preference_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('NotificationsPreferenceDatasource — daily check-in', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<NotificationsPreferenceDatasource> build() async {
      final prefs = await SharedPreferences.getInstance();
      return NotificationsPreferenceDatasource(prefs);
    }

    test('enabled defaults to false on a fresh install', () async {
      final ds = await build();
      expect(ds.isDailyCheckInEnabled(), isFalse);
    });

    test('time defaults to the 21:30 onboarding default', () async {
      final ds = await build();
      expect(ds.dailyCheckInHour(), defaultDailyCheckInHour);
      expect(ds.dailyCheckInMinute(), defaultDailyCheckInMinute);
      expect(ds.dailyCheckInHour(), 21);
      expect(ds.dailyCheckInMinute(), 30);
    });

    test('enabled round-trips', () async {
      final ds = await build();
      await ds.setDailyCheckInEnabled(true);
      expect(ds.isDailyCheckInEnabled(), isTrue);
      await ds.setDailyCheckInEnabled(false);
      expect(ds.isDailyCheckInEnabled(), isFalse);
    });

    test('time round-trips', () async {
      final ds = await build();
      await ds.setDailyCheckInTime(hour: 8, minute: 5);
      expect(ds.dailyCheckInHour(), 8);
      expect(ds.dailyCheckInMinute(), 5);
    });

    test('time persists independently of the enabled flag', () async {
      final ds = await build();
      await ds.setDailyCheckInTime(hour: 7, minute: 45);
      // Toggling enabled off must not clobber the chosen time.
      await ds.setDailyCheckInEnabled(false);
      expect(ds.dailyCheckInHour(), 7);
      expect(ds.dailyCheckInMinute(), 45);
    });

    test('seeded values are read back verbatim', () async {
      SharedPreferences.setMockInitialValues({
        'notifications.daily_check_in_enabled': true,
        'notifications.daily_check_in_hour': 6,
        'notifications.daily_check_in_minute': 0,
      });
      final ds = await build();
      expect(ds.isDailyCheckInEnabled(), isTrue);
      expect(ds.dailyCheckInHour(), 6);
      expect(ds.dailyCheckInMinute(), 0);
    });

    test('daily check-in keys are independent of the cheer-up flag', () async {
      final ds = await build();
      await ds.setCheerUpEnabled(true);
      await ds.setDailyCheckInEnabled(false);
      expect(ds.isCheerUpEnabled(), isTrue);
      expect(ds.isDailyCheckInEnabled(), isFalse);
    });
  });
}
