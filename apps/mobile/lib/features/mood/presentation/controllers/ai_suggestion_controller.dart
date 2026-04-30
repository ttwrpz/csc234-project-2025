import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/ai_analysis_failure.dart';
import '../../domain/entities/ai_suggestion.dart';

/// 600ms debounce on text changes — coalesces rapid typing into one Cloud
/// Function call. Tunable via the constant; longer feels laggy, shorter wastes
/// quota.
const Duration _kDefaultDebounceWindow = Duration(milliseconds: 600);

/// Pure-Riverpod (no codegen) so tests can override it cleanly with a fake
/// notifier subclass.
class AiSuggestionController extends StateNotifier<AsyncValue<AiSuggestion?>> {
  AiSuggestionController(this._ref, {Duration? debounceWindow})
    : _debounceWindow = debounceWindow ?? _kDefaultDebounceWindow,
      super(const AsyncValue.data(null));

  final Ref _ref;
  final Duration _debounceWindow;
  Timer? _debounce;

  /// Pump text into the controller. Debounced — only the latest call within
  /// [_debounceWindow] survives.
  void onTextChanged(String text) {
    _debounce?.cancel();
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      state = const AsyncValue.data(null);
      return;
    }
    _debounce = Timer(_debounceWindow, () => _run(trimmed));
  }

  /// Cancel any pending debounce and reset to data(null). Called when the user
  /// manually picks a mood or taps "Choose another".
  void clear() {
    _debounce?.cancel();
    state = const AsyncValue.data(null);
  }

  Future<void> _run(String text) async {
    state = const AsyncValue.loading();
    final usecase = _ref.read(analyzeMoodTextUseCaseProvider);
    final result = await usecase(text: text);
    if (!mounted) return;
    state = switch (result) {
      Ok(:final value) => AsyncValue.data(value),
      Err<AiSuggestion, AiAnalysisFailure>(:final failure) => AsyncValue.error(
        failure,
        StackTrace.current,
      ),
    };
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final aiSuggestionControllerProvider =
    StateNotifierProvider.autoDispose<
      AiSuggestionController,
      AsyncValue<AiSuggestion?>
    >((ref) {
      return AiSuggestionController(ref);
    });
