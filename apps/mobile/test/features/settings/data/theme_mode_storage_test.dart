import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/settings/data/theme_mode_storage.dart';
import 'package:moodbloom/features/settings/domain/entities/theme_mode_preference.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeModeStorage', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'read defaults to ThemeModePreference.system on first launch',
      () async {
        final prefs = await SharedPreferences.getInstance();
        expect(ThemeModeStorage(prefs).read(), ThemeModePreference.system);
      },
    );

    test('read returns the persisted value (round-trip)', () async {
      SharedPreferences.setMockInitialValues({'settings.theme_mode': 'dark'});
      final prefs = await SharedPreferences.getInstance();
      expect(ThemeModeStorage(prefs).read(), ThemeModePreference.dark);
    });

    test('round-trip for the new followDeviceTime value', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = ThemeModeStorage(prefs);

      await storage.write(ThemeModePreference.followDeviceTime);
      expect(storage.read(), ThemeModePreference.followDeviceTime);
      // The on-disk serialised form is snake_case so old apps don't
      // misread it as a literal enum name. Lock the wire format.
      expect(prefs.getString('settings.theme_mode'), 'follow_device_time');
    });

    test('read maps all four serialised forms correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = ThemeModeStorage(prefs);

      await storage.write(ThemeModePreference.system);
      expect(storage.read(), ThemeModePreference.system);

      await storage.write(ThemeModePreference.light);
      expect(storage.read(), ThemeModePreference.light);

      await storage.write(ThemeModePreference.dark);
      expect(storage.read(), ThemeModePreference.dark);

      await storage.write(ThemeModePreference.followDeviceTime);
      expect(storage.read(), ThemeModePreference.followDeviceTime);
    });

    test(
      'malformed stored value falls back to ThemeModePreference.system',
      () async {
        SharedPreferences.setMockInitialValues({
          'settings.theme_mode': 'highContrast',
        });
        final prefs = await SharedPreferences.getInstance();
        expect(ThemeModeStorage(prefs).read(), ThemeModePreference.system);
      },
    );

    group('backward-compat: legacy Sprint-3 strings on disk', () {
      // Sprint-3 storage wrote literal `'system' / 'light' / 'dark'`.
      // Existing users on those values must keep getting the matching
      // new enum value after the upgrade — no flash-of-system, no
      // forced re-pick.
      test("legacy 'system' decodes to ThemeModePreference.system", () async {
        SharedPreferences.setMockInitialValues({
          'settings.theme_mode': 'system',
        });
        final prefs = await SharedPreferences.getInstance();
        expect(ThemeModeStorage(prefs).read(), ThemeModePreference.system);
      });

      test("legacy 'light' decodes to ThemeModePreference.light", () async {
        SharedPreferences.setMockInitialValues({
          'settings.theme_mode': 'light',
        });
        final prefs = await SharedPreferences.getInstance();
        expect(ThemeModeStorage(prefs).read(), ThemeModePreference.light);
      });

      test("legacy 'dark' decodes to ThemeModePreference.dark", () async {
        SharedPreferences.setMockInitialValues({'settings.theme_mode': 'dark'});
        final prefs = await SharedPreferences.getInstance();
        expect(ThemeModeStorage(prefs).read(), ThemeModePreference.dark);
      });
    });
  });
}
