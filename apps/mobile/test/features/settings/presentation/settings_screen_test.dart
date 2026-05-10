import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/auth/domain/entities/biometric_capability.dart';
import 'package:moodbloom/features/settings/data/theme_mode_storage.dart';
import 'package:moodbloom/features/settings/domain/entities/theme_mode_preference.dart';
import 'package:moodbloom/features/settings/presentation/controllers/theme_mode_controller.dart';
import 'package:moodbloom/features/settings/presentation/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/pump_app.dart';

/// Maps a [ThemeModePreference] to the legacy serialised string used by
/// pre-existing tests. The new value `followDeviceTime` serialises as
/// `'follow_device_time'`.
String _serialize(ThemeModePreference preference) => switch (preference) {
  ThemeModePreference.system => 'system',
  ThemeModePreference.light => 'light',
  ThemeModePreference.dark => 'dark',
  ThemeModePreference.followDeviceTime => 'follow_device_time',
};

Future<void> _pumpSettings(
  WidgetTester tester, {
  required ThemeModePreference initialPreference,
  ThemeMode appThemeMode = ThemeMode.light,
}) async {
  // Seed SharedPreferences with the requested initial preference so the
  // controller's synchronous build() reads it.
  SharedPreferences.setMockInitialValues({
    'settings.theme_mode': _serialize(initialPreference),
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
      await _pumpSettings(
        tester,
        initialPreference: ThemeModePreference.system,
      );

      // The section was renamed from "Appearance" to "PREFERENCES" when
      // the screen was re-grouped into zoned MbCard clusters.
      expect(find.text('PREFERENCES'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      // The summary line under "Theme" reflects the persisted preference.
      expect(find.text('Match the device theme'), findsOneWidget);
    });

    testWidgets('renders all four theme radio options', (tester) async {
      await _pumpSettings(
        tester,
        initialPreference: ThemeModePreference.system,
      );

      expect(find.text('Follow device theme'), findsOneWidget);
      expect(find.text('Follow device time'), findsOneWidget);
      expect(find.text('Always light'), findsOneWidget);
      expect(find.text('Always dark'), findsOneWidget);
    });

    testWidgets('summary line reflects the current preference', (tester) async {
      await _pumpSettings(tester, initialPreference: ThemeModePreference.dark);
      expect(find.text('Always dark'), findsWidgets);
    });

    testWidgets(
      'tapping followDeviceTime updates the controller AND persists',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'settings.theme_mode': 'system',
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

        expect(
          container.read(themeModeControllerProvider),
          ThemeModePreference.system,
        );

        // Tap the "Follow device time" radio tile by its label text.
        await tester.tap(find.text('Follow device time'));
        await tester.pumpAndSettle();

        expect(
          container.read(themeModeControllerProvider),
          ThemeModePreference.followDeviceTime,
        );
        expect(storage.read(), ThemeModePreference.followDeviceTime);
      },
    );

    testWidgets(
      'tapping each radio updates the controller (4-state coverage)',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
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

        const cases = <(String, ThemeModePreference)>[
          ('Always light', ThemeModePreference.light),
          ('Always dark', ThemeModePreference.dark),
          ('Follow device time', ThemeModePreference.followDeviceTime),
          ('Follow device theme', ThemeModePreference.system),
        ];

        for (final entry in cases) {
          await tester.tap(find.text(entry.$1));
          await tester.pumpAndSettle();
          expect(container.read(themeModeControllerProvider), entry.$2);
          expect(storage.read(), entry.$2);
        }
      },
    );

    testWidgets('preserves the existing tiles (account / sign-out)', (
      tester,
    ) async {
      await _pumpSettings(
        tester,
        initialPreference: ThemeModePreference.system,
      );
      // Let StreamProvider emit the seeded user + the biometric tile's
      // FutureProvider settle.
      await tester.pumpAndSettle();
      // Profile tile is at the top of the list so it renders without
      // scrolling.
      expect(find.text('tester@example.com'), findsOneWidget);
      // The 4-radio theme group made the screen tall enough that
      // Sign out lives below the default 600-pixel test viewport;
      // the widget framework skips off-screen ListView children, so
      // we have to scroll the tile into view before asserting.
      await tester.dragUntilVisible(
        find.text('Sign out'),
        find.byType(ListView),
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sign out'), findsOneWidget);
    });
  });
}
