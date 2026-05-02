import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/theme_mode_storage.dart';

/// Riverpod controller for the active [ThemeMode]. Initial state is
/// resolved synchronously from [ThemeModeStorage] (which wraps an
/// eager-resolved SharedPreferences), so `bootstrap.dart` reads a hot
/// value on the very first build. No flash-of-light, no AsyncValue
/// flicker.
///
/// The provider intentionally throws if not overridden — `main.dart`
/// must seed it via `overrideWith(() => ThemeModeController(...))` after
/// `SharedPreferences.getInstance()` resolves. Tests can override the
/// same way with a fake storage.
class ThemeModeController extends Notifier<ThemeMode> {
  ThemeModeController({required ThemeModeStorage storage}) : _storage = storage;

  final ThemeModeStorage _storage;

  @override
  ThemeMode build() => _storage.read();

  /// Persists [mode] and updates state. Awaited by callers (the toggle
  /// dropdown) so the surface change is observable in tests.
  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _storage.write(mode);
  }
}

/// Notifier provider for the active theme mode. MUST be overridden in
/// `main.dart` — see [ThemeModeController]'s class doc.
final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(() {
      throw UnimplementedError(
        'themeModeControllerProvider must be overridden in main.dart with '
        'an eager-resolved ThemeModeStorage. See main.dart bootstrap.',
      );
    });
