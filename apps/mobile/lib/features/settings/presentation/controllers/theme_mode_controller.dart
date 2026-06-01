import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/theme_mode_storage.dart';
import '../../domain/entities/theme_mode_preference.dart';
import '../../domain/services/day_night_strategy.dart';

/// Riverpod controller for the active [ThemeModePreference]. Initial
/// state is resolved synchronously from [ThemeModeStorage] (which wraps
/// an eager-resolved SharedPreferences), so `bootstrap.dart` reads a
/// hot value on the very first build. No flash-of-light, no
/// AsyncValue flicker.
///
/// The provider intentionally throws if not overridden - `main.dart`
/// must seed it via `overrideWith(() => ThemeModeController(...))`
/// after `SharedPreferences.getInstance()` resolves. Tests can
/// override the same way with a fake storage.
///
/// The 4-value preference enum (incl. `followDeviceTime`) is mapped to
/// a concrete [ThemeMode] by [currentThemeModeProvider], which is what
/// `MaterialApp.themeMode` consumes in `bootstrap.dart`. Keeping the
/// resolve step OUT of this notifier means the persisted preference
/// is the only stateful surface - the resolved theme is a pure
/// function of `(preference, now)`.
class ThemeModeController extends Notifier<ThemeModePreference> {
  ThemeModeController({required ThemeModeStorage storage}) : _storage = storage;

  final ThemeModeStorage _storage;

  @override
  ThemeModePreference build() => _storage.read();

  /// Persists [preference] and updates state. Awaited by callers (the
  /// settings radio group) so the surface change is observable in
  /// tests.
  Future<void> setPreference(ThemeModePreference preference) async {
    state = preference;
    await _storage.write(preference);
  }
}

/// Notifier provider for the persisted theme preference. MUST be
/// overridden in `main.dart` - see [ThemeModeController]'s class doc.
final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeModePreference>(() {
      throw UnimplementedError(
        'themeModeControllerProvider must be overridden in main.dart with '
        'an eager-resolved ThemeModeStorage. See main.dart bootstrap.',
      );
    });

/// Tick interval driving the `followDeviceTime` re-evaluation. Cheap
/// (no I/O); the 15-minute granularity is more than enough for
/// catching the 07:00 / 19:00 boundary while the app is in the
/// foreground.
const Duration _dayNightTickInterval = Duration(minutes: 15);

/// Resolved [ThemeMode] consumed by `MaterialApp.themeMode`. Reads the
/// preference notifier and the strategy, and (when the preference is
/// `followDeviceTime`) ticks every 15 minutes so the resolved mode
/// flips at the next 07:00 / 19:00 boundary the user is awake to
/// notice.
///
/// The 15-minute tick is acceptable; an `AppLifecycleState.resumed`
/// re-evaluation is a known follow-up. In practice the resolved mode
/// also recomputes on every rebuild triggered by
/// [themeModeControllerProvider], so a user toggling the preference
/// picks up the new theme immediately.
final currentThemeModeProvider = Provider<ThemeMode>((ref) {
  final preference = ref.watch(themeModeControllerProvider);
  const strategy = DayNightStrategy();

  if (preference == ThemeModePreference.followDeviceTime) {
    // Subscribe to a periodic ticker so the resolved mode
    // re-evaluates across the 07:00 / 19:00 boundary while the app is
    // open. `Stream.periodic` is cancelled by `ref.onDispose` when no
    // widget watches the provider any more, so there's no leak.
    final ticker = Stream<int>.periodic(_dayNightTickInterval, (i) => i);
    final sub = ticker.listen((_) => ref.invalidateSelf());
    ref.onDispose(sub.cancel);
  }

  return strategy.resolve(preference: preference, now: DateTime.now());
});
