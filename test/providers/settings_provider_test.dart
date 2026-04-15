// Tests for: US-19 Animation Speed Setting, US-23 Dark Mode
// Features covered: settings persistence, theme switching,
//   animation speed changes, notification toggle
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_centric_mobile_app/providers/settings_provider.dart';
import 'package:user_centric_mobile_app/services/preferences_service.dart';

void main() {
  group('SettingsProvider', () {
    late SettingsProvider provider;
    late PreferencesService preferencesService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      preferencesService = PreferencesService();
      provider = SettingsProvider(preferencesService: preferencesService);
    });

    test('initial state has default values before loading', () {
      expect(provider.isLoaded, false);
      expect(provider.darkMode, false);
      expect(provider.animationSpeed, 2.0);
      expect(provider.notificationsEnabled, true);
      expect(provider.onboardingSeen, false);
    });

    test('loadSettings sets isLoaded to true', () async {
      await provider.loadSettings();
      expect(provider.isLoaded, true);
    });

    test('loadSettings loads default values from empty prefs', () async {
      await provider.loadSettings();
      expect(provider.darkMode, false);
      expect(provider.animationSpeed, 2.0);
      expect(provider.notificationsEnabled, true);
      expect(provider.onboardingSeen, false);
    });

    test('setDarkMode persists and updates state', () async {
      await provider.loadSettings();
      expect(provider.darkMode, false);

      await provider.setDarkMode(true);
      expect(provider.darkMode, true);

      // Reload to verify persistence
      final provider2 =
          SettingsProvider(preferencesService: preferencesService);
      await provider2.loadSettings();
      expect(provider2.darkMode, true);
    });

    test('setDarkMode toggle back to false', () async {
      await provider.loadSettings();
      await provider.setDarkMode(true);
      expect(provider.darkMode, true);

      await provider.setDarkMode(false);
      expect(provider.darkMode, false);
    });

    test('setAnimationSpeed persists and updates state', () async {
      await provider.loadSettings();
      expect(provider.animationSpeed, 2.0);

      await provider.setAnimationSpeed(4.0);
      expect(provider.animationSpeed, 4.0);

      // Reload to verify persistence
      final provider2 =
          SettingsProvider(preferencesService: preferencesService);
      await provider2.loadSettings();
      expect(provider2.animationSpeed, 4.0);
    });

    test('setAnimationSpeed accepts min value 1.0', () async {
      await provider.loadSettings();
      await provider.setAnimationSpeed(1.0);
      expect(provider.animationSpeed, 1.0);
    });

    test('setAnimationSpeed accepts max value 5.0', () async {
      await provider.loadSettings();
      await provider.setAnimationSpeed(5.0);
      expect(provider.animationSpeed, 5.0);
    });

    test('setNotificationsEnabled persists and updates state', () async {
      await provider.loadSettings();
      expect(provider.notificationsEnabled, true);

      await provider.setNotificationsEnabled(false);
      expect(provider.notificationsEnabled, false);

      final provider2 =
          SettingsProvider(preferencesService: preferencesService);
      await provider2.loadSettings();
      expect(provider2.notificationsEnabled, false);
    });

    test('setOnboardingSeen persists and updates state', () async {
      await provider.loadSettings();
      expect(provider.onboardingSeen, false);

      await provider.setOnboardingSeen(true);
      expect(provider.onboardingSeen, true);

      final provider2 =
          SettingsProvider(preferencesService: preferencesService);
      await provider2.loadSettings();
      expect(provider2.onboardingSeen, true);
    });

    test('multiple settings changes persist independently', () async {
      await provider.loadSettings();

      await provider.setDarkMode(true);
      await provider.setAnimationSpeed(3.5);
      await provider.setNotificationsEnabled(false);
      await provider.setOnboardingSeen(true);

      final provider2 =
          SettingsProvider(preferencesService: preferencesService);
      await provider2.loadSettings();

      expect(provider2.darkMode, true);
      expect(provider2.animationSpeed, 3.5);
      expect(provider2.notificationsEnabled, false);
      expect(provider2.onboardingSeen, true);
    });

    test('notifyListeners called on each setter', () async {
      await provider.loadSettings();

      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.setDarkMode(true);
      expect(notifyCount, 1);

      await provider.setAnimationSpeed(4.0);
      expect(notifyCount, 2);

      await provider.setNotificationsEnabled(false);
      expect(notifyCount, 3);
    });

    test('loadSettings with existing values', () async {
      SharedPreferences.setMockInitialValues({
        'dark_mode': true,
        'animation_speed': 3.0,
        'notifications_enabled': false,
        'onboarding_seen': true,
      });

      final ps = PreferencesService();
      final p = SettingsProvider(preferencesService: ps);
      await p.loadSettings();

      expect(p.darkMode, true);
      expect(p.animationSpeed, 3.0);
      expect(p.notificationsEnabled, false);
      expect(p.onboardingSeen, true);
    });
  });
}
