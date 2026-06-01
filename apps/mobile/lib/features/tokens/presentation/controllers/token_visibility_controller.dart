import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'token_visibility_controller.g.dart';

/// SharedPreferences-backed controller for the "Show token balance"
/// Settings toggle. Default `true`.
///
/// Anti-pattern guardrail: visibility is OPTIONAL - the user can hide
/// the chip without forfeiting tokens. Tokens still accumulate in the
/// background; only the chip render is suppressed.
///
/// `build()` returns the synchronous default `true` so the first frame
/// renders without a flicker. The async hydration from prefs runs in
/// the background; if the user previously chose to hide the chip, the
/// state flips to `false` once prefs resolve. Tests can override the
/// `sharedPreferencesProvider` to pre-seed a value.
///
/// Mirrors `theme_mode_storage.dart`'s storage shape (single string-
/// keyed bool) but the controller itself is `@riverpod` for the
/// codegen-friendly notifier surface.
@Riverpod(keepAlive: true)
class TokenVisibility extends _$TokenVisibility {
  static const String _prefsKey = 'settings.show_token_balance';

  @override
  bool build() {
    // Kick off the async hydration from SharedPreferences. We don't
    // await here because `build()` is synchronous - the first frame
    // renders the default `true`, and once prefs resolve we flip the
    // state to whatever was persisted (no-op if it was true).
    _hydrate();
    return true;
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_prefsKey);
    if (stored == null) return; // never written → keep the default
    if (stored == state) return; // no change → no rebuild
    state = stored;
  }

  /// Persists [visible] and updates state. Awaited by callers (the
  /// Settings toggle) so the surface change is observable in tests.
  Future<void> setVisible({required bool visible}) async {
    state = visible;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, visible);
  }
}
