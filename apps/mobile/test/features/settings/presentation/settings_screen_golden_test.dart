@Tags(['golden'])
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/auth/domain/entities/biometric_capability.dart';
import 'package:moodbloom/features/settings/data/theme_mode_storage.dart';
import 'package:moodbloom/features/settings/domain/entities/theme_mode_preference.dart';
import 'package:moodbloom/features/settings/presentation/controllers/theme_mode_controller.dart';
import 'package:moodbloom/features/settings/presentation/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _serialize(ThemeModePreference preference) => switch (preference) {
  ThemeModePreference.system => 'system',
  ThemeModePreference.light => 'light',
  ThemeModePreference.dark => 'dark',
  ThemeModePreference.followDeviceTime => 'follow_device_time',
};

Future<void> _pumpSettingsAt(
  WidgetTester tester, {
  required ThemeMode mode,
  ThemeModePreference preference = ThemeModePreference.system,
}) async {
  SharedPreferences.setMockInitialValues({
    'settings.theme_mode': _serialize(preference),
  });
  final prefs = await SharedPreferences.getInstance();
  final storage = ThemeModeStorage(prefs);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        themeModeControllerProvider.overrideWith(
          () => ThemeModeController(storage: storage),
        ),
        currentUserStreamProvider.overrideWith(
          (_) => Stream<AppUser?>.value(
            const AppUser(
              uid: 'u-1',
              email: 'tester@example.com',
              displayName: 'Tester',
            ),
          ),
        ),
        biometricCapabilityProvider.overrideWith(
          (_) async => const BiometricCapability(
            isAvailable: false,
            hasEnrolledBiometrics: false,
            userOptedIn: false,
          ),
        ),
      ],
      child: MaterialApp(
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: mode,
        home: const SettingsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // The screen grew a 4-radio theme group on Day 4 (HB-005 Track
  // 4.4/7.2), so the goldens were regenerated alongside the radio
  // group merge. The dark / light goldens both now carry the four
  // theme options: Follow device theme / Follow device time / Always
  // light / Always dark.
  testGoldens('SettingsScreen — light theme', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpSettingsAt(tester, mode: ThemeMode.light);
    await screenMatchesGolden(tester, 'settings_screen_light');
  });

  testGoldens('SettingsScreen — dark theme', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpSettingsAt(tester, mode: ThemeMode.dark);
    await screenMatchesGolden(tester, 'settings_screen_dark');
  });
}
