import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/auth/domain/entities/biometric_capability.dart';
import 'package:moodbloom/features/settings/data/theme_mode_storage.dart';
import 'package:moodbloom/features/settings/presentation/controllers/theme_mode_controller.dart';
import 'package:moodbloom/features/settings/presentation/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/pump_app.dart';

Future<void> _pumpSettings(
  WidgetTester tester, {
  required ThemeMode initialMode,
  ThemeMode appThemeMode = ThemeMode.light,
}) async {
  // Seed SharedPreferences with the requested initial mode so the
  // controller's synchronous build() reads it.
  SharedPreferences.setMockInitialValues({
    'settings.theme_mode': switch (initialMode) {
      ThemeMode.system => 'system',
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
    },
  });
  final prefs = await SharedPreferences.getInstance();
  final storage = ThemeModeStorage(prefs);

  await pumpApp(
    tester,
    themeMode: appThemeMode,
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
    child: const SettingsScreen(),
  );
}

void main() {
  group('SettingsScreen', () {
    testWidgets('renders Appearance section + System/Light/Dark options', (
      tester,
    ) async {
      await _pumpSettings(tester, initialMode: ThemeMode.system);

      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Match the system'), findsOneWidget);
    });

    testWidgets('subtitle reflects the currently-selected ThemeMode', (
      tester,
    ) async {
      await _pumpSettings(tester, initialMode: ThemeMode.dark);
      expect(find.text('Always dark'), findsOneWidget);
    });

    testWidgets(
      'tapping the dropdown and choosing Dark updates themeModeControllerProvider',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'settings.theme_mode': 'light',
        });
        final prefs = await SharedPreferences.getInstance();
        final storage = ThemeModeStorage(prefs);

        late ProviderContainer container;
        await pumpApp(
          tester,
          overrides: [
            themeModeControllerProvider.overrideWith(
              () => ThemeModeController(storage: storage),
            ),
            currentUserStreamProvider.overrideWith(
              (_) => Stream<AppUser?>.value(
                const AppUser(uid: 'u-1', email: 'tester@example.com'),
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
          child: Builder(
            builder: (context) {
              container = ProviderScope.containerOf(context);
              return const SettingsScreen();
            },
          ),
        );

        expect(container.read(themeModeControllerProvider), ThemeMode.light);

        await tester.tap(find.byType(DropdownButton<ThemeMode>));
        await tester.pumpAndSettle();
        // The menu shows multiple "Dark" entries (one in the visible
        // dropdown, one in the open menu). `.last` picks the menu entry.
        await tester.tap(find.text('Dark').last);
        await tester.pumpAndSettle();

        expect(container.read(themeModeControllerProvider), ThemeMode.dark);
        expect(storage.read(), ThemeMode.dark);
      },
    );

    testWidgets('preserves the existing tiles (account / sign-out)', (
      tester,
    ) async {
      await _pumpSettings(tester, initialMode: ThemeMode.system);
      // Let StreamProvider emit the seeded user + the biometric tile's
      // FutureProvider settle.
      await tester.pumpAndSettle();
      expect(find.text('tester@example.com'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
    });
  });
}
