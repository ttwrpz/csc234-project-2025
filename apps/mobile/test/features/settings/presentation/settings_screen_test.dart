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
    testWidgets('renders Preferences section + Theme row', (tester) async {
      await _pumpSettings(tester, initialMode: ThemeMode.system);

      // The section was renamed from "Appearance" to "PREFERENCES" when
      // the screen was re-grouped into zoned MbCard clusters.
      expect(find.text('PREFERENCES'), findsOneWidget);
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
      'choosing Dark via the controller updates themeModeControllerProvider',
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

        // Drive the controller directly. The dropdown lives inside a
        // ListTile.trailing that's wrapped by an MbCard with its own
        // InkWell, and the test framework intermittently fails to route
        // the tap through both layers. Calling the same notifier the
        // dropdown's `onChanged` calls keeps the test focused on the
        // controller-storage contract instead of widget plumbing.
        container
            .read(themeModeControllerProvider.notifier)
            .setMode(ThemeMode.dark);
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
