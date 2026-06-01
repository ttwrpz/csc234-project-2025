import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/settings/domain/entities/theme_mode_preference.dart';
import 'package:moodbloom/features/settings/domain/services/day_night_strategy.dart';

void main() {
  group('DayNightStrategy', () {
    const strategy = DayNightStrategy();
    // Anchor `now` on a fixed local DateTime so the test is reproducible
    // regardless of the host machine's time zone - `toLocal()` is a
    // no-op on a `DateTime` already constructed in local time.
    DateTime localAt(int hour) => DateTime(2026, 5, 12, hour);

    group('TC-19 system pass-through', () {
      test('system preference returns ThemeMode.system regardless of hour', () {
        for (final hour in const [0, 6, 12, 18, 23]) {
          expect(
            strategy.resolve(
              preference: ThemeModePreference.system,
              now: localAt(hour),
            ),
            ThemeMode.system,
            reason: 'system must always pass through (hour=$hour)',
          );
        }
      });
    });

    group('explicit-mode pass-through', () {
      test('light preference returns ThemeMode.light regardless of hour', () {
        for (final hour in const [0, 7, 19, 23]) {
          expect(
            strategy.resolve(
              preference: ThemeModePreference.light,
              now: localAt(hour),
            ),
            ThemeMode.light,
          );
        }
      });

      test('dark preference returns ThemeMode.dark regardless of hour', () {
        for (final hour in const [0, 7, 19, 23]) {
          expect(
            strategy.resolve(
              preference: ThemeModePreference.dark,
              now: localAt(hour),
            ),
            ThemeMode.dark,
          );
        }
      });
    });

    group('TC-20 followDeviceTime cutoff at 07:00 / 19:00 local', () {
      test('14:00 local → ThemeMode.light', () {
        expect(
          strategy.resolve(
            preference: ThemeModePreference.followDeviceTime,
            now: localAt(14),
          ),
          ThemeMode.light,
        );
      });

      test('20:00 local → ThemeMode.dark', () {
        expect(
          strategy.resolve(
            preference: ThemeModePreference.followDeviceTime,
            now: localAt(20),
          ),
          ThemeMode.dark,
        );
      });

      // Boundary cases - the cutoff is inclusive at 07:00 (light) and
      // exclusive at 19:00 (dark from 19:00 onwards). 06:59 is dark,
      // 18:59 is light.
      test('06:59 local → ThemeMode.dark (just before sunrise cutoff)', () {
        expect(
          strategy.resolve(
            preference: ThemeModePreference.followDeviceTime,
            now: DateTime(2026, 5, 12, 6, 59),
          ),
          ThemeMode.dark,
        );
      });

      test('07:00 local → ThemeMode.light (sunrise cutoff inclusive)', () {
        expect(
          strategy.resolve(
            preference: ThemeModePreference.followDeviceTime,
            now: localAt(7),
          ),
          ThemeMode.light,
        );
      });

      test('18:59 local → ThemeMode.light (just before sunset cutoff)', () {
        expect(
          strategy.resolve(
            preference: ThemeModePreference.followDeviceTime,
            now: DateTime(2026, 5, 12, 18, 59),
          ),
          ThemeMode.light,
        );
      });

      test('19:00 local → ThemeMode.dark (sunset cutoff exclusive)', () {
        expect(
          strategy.resolve(
            preference: ThemeModePreference.followDeviceTime,
            now: localAt(19),
          ),
          ThemeMode.dark,
        );
      });

      test('00:00 local → ThemeMode.dark (deep night)', () {
        expect(
          strategy.resolve(
            preference: ThemeModePreference.followDeviceTime,
            now: localAt(0),
          ),
          ThemeMode.dark,
        );
      });
    });

    group('custom dayStartHour / dayEndHour', () {
      // Sanity check that the cutoffs are configurable - useful for a
      // v1.x sunrise/sunset table replacement and for tests in other
      // time zones.
      const earlyDay = DayNightStrategy(dayStartHour: 5, dayEndHour: 21);

      test('5am with custom 05:00 cutoff → light', () {
        expect(
          earlyDay.resolve(
            preference: ThemeModePreference.followDeviceTime,
            now: DateTime(2026, 5, 12, 5),
          ),
          ThemeMode.light,
        );
      });

      test('20:00 with custom 21:00 cutoff → light', () {
        expect(
          earlyDay.resolve(
            preference: ThemeModePreference.followDeviceTime,
            now: DateTime(2026, 5, 12, 20),
          ),
          ThemeMode.light,
        );
      });

      test('21:00 with custom 21:00 cutoff → dark (exclusive)', () {
        expect(
          earlyDay.resolve(
            preference: ThemeModePreference.followDeviceTime,
            now: DateTime(2026, 5, 12, 21),
          ),
          ThemeMode.dark,
        );
      });
    });
  });
}
