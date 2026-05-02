import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/settings/data/theme_mode_storage.dart';
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

    test('build() returns the persisted ThemeMode synchronously', () async {
      SharedPreferences.setMockInitialValues({'settings.theme_mode': 'dark'});
      final prefs = await SharedPreferences.getInstance();
      final container = makeContainer(ThemeModeStorage(prefs));
      addTearDown(container.dispose);

      expect(container.read(themeModeControllerProvider), ThemeMode.dark);
    });

    test('setMode updates state AND persists', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = ThemeModeStorage(prefs);
      final container = makeContainer(storage);
      addTearDown(container.dispose);

      // initial: no preference → system
      expect(container.read(themeModeControllerProvider), ThemeMode.system);

      await container
          .read(themeModeControllerProvider.notifier)
          .setMode(ThemeMode.light);

      expect(container.read(themeModeControllerProvider), ThemeMode.light);
      // re-read storage directly to confirm persistence
      expect(storage.read(), ThemeMode.light);
    });

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
  });
}
