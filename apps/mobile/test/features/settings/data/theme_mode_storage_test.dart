import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/settings/data/theme_mode_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeModeStorage', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('read defaults to ThemeMode.system on first launch', () async {
      final prefs = await SharedPreferences.getInstance();
      expect(ThemeModeStorage(prefs).read(), ThemeMode.system);
    });

    test('read returns the persisted value (round-trip)', () async {
      SharedPreferences.setMockInitialValues({'settings.theme_mode': 'dark'});
      final prefs = await SharedPreferences.getInstance();
      expect(ThemeModeStorage(prefs).read(), ThemeMode.dark);
    });

    test('read maps the three serialised forms correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = ThemeModeStorage(prefs);

      await storage.write(ThemeMode.system);
      expect(storage.read(), ThemeMode.system);

      await storage.write(ThemeMode.light);
      expect(storage.read(), ThemeMode.light);

      await storage.write(ThemeMode.dark);
      expect(storage.read(), ThemeMode.dark);
    });

    test('malformed stored value falls back to ThemeMode.system', () async {
      SharedPreferences.setMockInitialValues({
        'settings.theme_mode': 'highContrast',
      });
      final prefs = await SharedPreferences.getInstance();
      expect(ThemeModeStorage(prefs).read(), ThemeMode.system);
    });
  });
}
