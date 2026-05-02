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

/// Debounce window for the AI suggestion call. Tests override this with a
/// short interval (e.g. 30ms) so the timer fires inside the test budget.
/// Riverpod 3: `Notifier` constructors take no args, so dependency
/// injection happens through provider overrides instead of `new
/// AiSuggestionController(ref, debounceWindow: …)`.
final aiSuggestionDebounceWindowProvider = Provider<Duration>(
  (ref) => _kDefaultDebounceWindow,
);

/// Auto-disposed notifier holding the latest AI mood suggestion for the
/// Log Mood screen. Pure-Riverpod (no codegen) so tests can override the
/// provider with a fresh instance and the debounce-window provider in
/// the same `ProviderContainer`.
class AiSuggestionController extends Notifier<AsyncValue<AiSuggestion?>> {
  AiSuggestionController();

  Timer? _debounce;
  late Duration _debounceWindow;

  @override
  AsyncValue<AiSuggestion?> build() {
    _debounceWindow = ref.watch(aiSuggestionDebounceWindowProvider);
    ref.onDispose(() => _debounce?.cancel());
    return const AsyncValue.data(null);
  }

  /// Pump text into the controller. Debounced — only the latest call within
  /// the configured window survives.
  void onTextChanged(String text) {
    _debounce?.cancel();
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
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
