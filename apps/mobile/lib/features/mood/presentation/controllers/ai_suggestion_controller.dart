import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/ai_analysis_failure.dart';
import '../../domain/entities/ai_suggestion.dart';

/// 600ms debounce on text changes — coalesces rapid typing into one Cloud
/// Function call. Tunable via [aiSuggestionDebounceWindowProvider]; longer
/// feels laggy, shorter wastes quota.
const Duration _kDefaultDebounceWindow = Duration(milliseconds: 600);

/// Minimum trimmed character count before the AI analyse fires. Below
/// this threshold the controller treats the text as empty (no
/// suggestion shown, no Cloud Function call). User feedback v1.0
/// polish (2026-05-10): the prior threshold was 1 char, which fired
/// Gemini on 2-3 char drafts ("ok", "sad") and felt over-eager. 12
/// chars is roughly "I feel sad" — long enough to imply intent.
const int _kDefaultMinChars = 12;

/// Debounce window for the AI suggestion call. Tests override this with a
/// short interval (e.g. 30ms) so the timer fires inside the test budget.
/// Riverpod 3: `Notifier` constructors take no args, so dependency
/// injection happens through provider overrides instead of `new
/// AiSuggestionController(ref, debounceWindow: …)`.
final aiSuggestionDebounceWindowProvider = Provider<Duration>(
  (ref) => _kDefaultDebounceWindow,
);

/// Minimum trimmed-text length before AI analyse fires. Tests can
/// override this provider to drop the threshold to 1 if they want to
/// exercise the fire path with short inputs.
final aiSuggestionMinCharsProvider = Provider<int>((ref) => _kDefaultMinChars);

/// Auto-disposed notifier holding the latest AI mood suggestion for the
/// Log Mood screen. Pure-Riverpod (no codegen) so tests can override the
/// provider with a fresh instance and the debounce-window provider in
/// the same `ProviderContainer`.
class AiSuggestionController extends Notifier<AsyncValue<AiSuggestion?>> {
  AiSuggestionController();

  Timer? _debounce;
  late Duration _debounceWindow;
  late int _minChars;

  @override
  AsyncValue<AiSuggestion?> build() {
    _debounceWindow = ref.watch(aiSuggestionDebounceWindowProvider);
    _minChars = ref.watch(aiSuggestionMinCharsProvider);
    ref.onDispose(() => _debounce?.cancel());
    return const AsyncValue.data(null);
  }

  /// Pump text into the controller. Debounced — only the latest call within
  /// the configured window survives. Texts shorter than [_minChars] are
  /// treated as empty and clear any prior suggestion (no Gemini call).
  void onTextChanged(String text) {
    _debounce?.cancel();
    final trimmed = text.trim();
    if (trimmed.length < _minChars) {
      state = const AsyncValue.data(null);
      return;
    }
    _debounce = Timer(_debounceWindow, () => _run(trimmed));
  }

  /// Cancel any pending debounce and reset to data(null). Called when the
  /// user manually picks a mood or taps "Choose another".
  void clear() {
    _debounce?.cancel();
    state = const AsyncValue.data(null);
  }

  /// Re-run the analysis immediately, bypassing the debounce. Wired to
  /// the "Retry" button in the AI suggestion card's error state.
  Future<void> retry(String text) async {
    _debounce?.cancel();
    final trimmed = text.trim();
    if (trimmed.length < _minChars) {
      state = const AsyncValue.data(null);
      return;
    }
    await _run(trimmed);
  }

  Future<void> _run(String text) async {
    state = const AsyncValue.loading();
    final usecase = ref.read(analyzeMoodTextUseCaseProvider);
    final result = await usecase(text: text);
    // Riverpod 3: `Notifier.state =` is a no-op once the provider is
    // disposed; no `mounted` guard needed.
    state = switch (result) {
      Ok(:final value) => AsyncValue.data(value),
      Err<AiSuggestion, AiAnalysisFailure>(:final failure) => AsyncValue.error(
        failure,
        StackTrace.current,
      ),
    };
  }
}

/// Auto-disposed provider so the controller (and its pending debounce)
/// is reaped when the Log Mood screen leaves the tree.
final aiSuggestionControllerProvider =
    NotifierProvider.autoDispose<
      AiSuggestionController,
      AsyncValue<AiSuggestion?>
    >(AiSuggestionController.new);
