import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/settings/data/theme_mode_storage.dart';
import 'package:moodbloom/features/settings/domain/entities/theme_mode_preference.dart';
import 'package:moodbloom/features/settings/presentation/controllers/theme_mode_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeModeController', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    ProviderContainer makeContainer(ThemeModeStorage storage) {
      return ProviderContainer(
        overrides: [
          themeModeControllerProvider.overrideWith(
            () => ThemeModeController(storage: storage),
          ),
        ],
      );
    }

    test(
      'build() returns the persisted ThemeModePreference synchronously',
      () async {
        SharedPreferences.setMockInitialValues({'settings.theme_mode': 'dark'});
        final prefs = await SharedPreferences.getInstance();
        final container = makeContainer(ThemeModeStorage(prefs));
        addTearDown(container.dispose);

        expect(
          container.read(themeModeControllerProvider),
          ThemeModePreference.dark,
        );
      },
    );

    test('setPreference updates state AND persists', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = ThemeModeStorage(prefs);
      final container = makeContainer(storage);
      addTearDown(container.dispose);

      // initial: no preference → system
      expect(
        container.read(themeModeControllerProvider),
        ThemeModePreference.system,
      );

      await container
          .read(themeModeControllerProvider.notifier)
          .setPreference(ThemeModePreference.light);

      expect(
        container.read(themeModeControllerProvider),
        ThemeModePreference.light,
      );
      // re-read storage directly to confirm persistence
      expect(storage.read(), ThemeModePreference.light);
    });

    test(
      'setPreference accepts followDeviceTime — the new fourth value',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final storage = ThemeModeStorage(prefs);
        final container = makeContainer(storage);
        addTearDown(container.dispose);

        await container
            .read(themeModeControllerProvider.notifier)
            .setPreference(ThemeModePreference.followDeviceTime);

        expect(
          container.read(themeModeControllerProvider),
          ThemeModePreference.followDeviceTime,
        );
        expect(storage.read(), ThemeModePreference.followDeviceTime);
      },
    );

    test(
      'controller exposes all four preference states via setPreference',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final storage = ThemeModeStorage(prefs);
        final container = makeContainer(storage);
        addTearDown(container.dispose);

        for (final pref in ThemeModePreference.values) {
          await container
              .read(themeModeControllerProvider.notifier)
              .setPreference(pref);
          expect(container.read(themeModeControllerProvider), pref);
          expect(storage.read(), pref);
        }
      },
    );

    test('throws clear error if provider not overridden', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Riverpod 3 wraps the provider's factory exception in a
      // `ProviderException`; the original `UnimplementedError` is the
      // `.cause` of that wrapper, but `toString()` carries the message
      // verbatim for both layers. Match on the message rather than the
      // wrapper class so future internal changes don't break the test.
      expect(
        () => container.read(themeModeControllerProvider),
        throwsA(
          predicate<Object>(
            (e) => e.toString().contains(
              'themeModeControllerProvider must be overridden',
            ),
          ),
        ),
      );
    });

    group('currentThemeModeProvider', () {
      // Pass-through wiring: the resolved ThemeMode tracks the
      // preference notifier through the strategy. We don't time-travel
      // here (the strategy gets its own dedicated test); we just check
      // the four non-time-dependent preferences resolve to the
      // expected ThemeMode and that toggling preference updates the
      // resolved value.
      test('system preference resolves to ThemeMode.system', () async {
        final prefs = await SharedPreferences.getInstance();
        final container = makeContainer(ThemeModeStorage(prefs));
        addTearDown(container.dispose);

        expect(container.read(currentThemeModeProvider), ThemeMode.system);
      });

      test('light preference resolves to ThemeMode.light', () async {
        final prefs = await SharedPreferences.getInstance();
        final storage = ThemeModeStorage(prefs);
        final container = makeContainer(storage);
        addTearDown(container.dispose);

        await container
            .read(themeModeControllerProvider.notifier)
            .setPreference(ThemeModePreference.light);

        expect(container.read(currentThemeModeProvider), ThemeMode.light);
      });

      test('dark preference resolves to ThemeMode.dark', () async {
        final prefs = await SharedPreferences.getInstance();
        final storage = ThemeModeStorage(prefs);
        final container = makeContainer(storage);
        addTearDown(container.dispose);

        await container
            .read(themeModeControllerProvider.notifier)
            .setPreference(ThemeModePreference.dark);

        expect(container.read(currentThemeModeProvider), ThemeMode.dark);
      });

      test('toggling preference rebuilds currentThemeModeProvider', () async {
        final prefs = await SharedPreferences.getInstance();
        final storage = ThemeModeStorage(prefs);
        final container = makeContainer(storage);
        addTearDown(container.dispose);

        // Start: system → ThemeMode.system.
        expect(container.read(currentThemeModeProvider), ThemeMode.system);

        await container
            .read(themeModeControllerProvider.notifier)
            .setPreference(ThemeModePreference.dark);

        expect(container.read(currentThemeModeProvider), ThemeMode.dark);
      });
    });
  });
}
