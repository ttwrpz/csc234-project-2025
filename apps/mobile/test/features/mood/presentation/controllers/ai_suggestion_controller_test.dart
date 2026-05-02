import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/mood/data/providers.dart';
import 'package:moodbloom/features/mood/domain/ai_analysis_failure.dart';
import 'package:moodbloom/features/mood/domain/entities/ai_suggestion.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';
import 'package:moodbloom/features/mood/presentation/controllers/ai_suggestion_controller.dart';

import '../../domain/fakes/fake_ai_analysis_repository.dart';

const _shortDebounce = Duration(milliseconds: 30);

ProviderContainer _container({required FakeAiAnalysisRepository fake}) {
  final container = ProviderContainer(
    overrides: [
      aiAnalysisRepositoryProvider.overrideWithValue(fake),
      // Riverpod 3: `Notifier` constructors take no args. Dependency
      // injection of the debounce window now goes through a sibling
      // provider override.
      aiSuggestionDebounceWindowProvider.overrideWithValue(_shortDebounce),
    ],
  );
  // autoDispose providers are reaped once the last subscription drops; keep a
  // permanent listener throughout the test so the timer fires and the state
  // updates make it back into the container's snapshot.
  container.listen<AsyncValue<AiSuggestion?>>(
    aiSuggestionControllerProvider,
    (_, _) {},
  );
  return container;
}

void main() {
  late FakeAiAnalysisRepository fake;
  late ProviderContainer container;

  const sampleOk = AiSuggestion(
    mood: MoodType.sad,
    confidence: 0.7,
    rationale: '',
    latency: Duration(milliseconds: 100),
  );

  setUp(() {
    fake = FakeAiAnalysisRepository(nextResult: const Ok(sampleOk));
    container = _container(fake: fake);
  });

  tearDown(() => container.dispose());

  test(
    'rapid typing coalesces into ONE call after the debounce window',
    () async {
      final ctrl = container.read(aiSuggestionControllerProvider.notifier);
      ctrl.onTextChanged('h');
      ctrl.onTextChanged('he');
      ctrl.onTextChanged('hel');
      ctrl.onTextChanged('hell');
      ctrl.onTextChanged('hello');

      // Wait past the debounce window AND let async work settle.
      await Future<void>.delayed(
        _shortDebounce + const Duration(milliseconds: 50),
      );

      expect(fake.calls, hasLength(1));
      expect(fake.calls.first.text, 'hello');
    },
  );

  test('clear() cancels pending debounce — no use case call', () async {
    final ctrl = container.read(aiSuggestionControllerProvider.notifier);
    ctrl.onTextChanged('hello');
    ctrl.clear();
    await Future<void>.delayed(
      _shortDebounce + const Duration(milliseconds: 50),
    );
    expect(fake.calls, isEmpty);
    expect(
      container.read(aiSuggestionControllerProvider),
      const AsyncValue<AiSuggestion?>.data(null),
    );
  });

  test('whitespace-only input → AsyncData(null), no use case call', () async {
    final ctrl = container.read(aiSuggestionControllerProvider.notifier);
    ctrl.onTextChanged('   ');
    await Future<void>.delayed(
      _shortDebounce + const Duration(milliseconds: 50),
    );
    expect(fake.calls, isEmpty);
    expect(
      container.read(aiSuggestionControllerProvider),
      const AsyncValue<AiSuggestion?>.data(null),
    );
  });

  test('use case Ok → state is AsyncData(suggestion)', () async {
    final ctrl = container.read(aiSuggestionControllerProvider.notifier);
    ctrl.onTextChanged('feeling sad');
    await Future<void>.delayed(
      _shortDebounce + const Duration(milliseconds: 50),
    );
    final state = container.read(aiSuggestionControllerProvider);
    expect(state.value, sampleOk);
  });

  test('use case Err → state is AsyncError', () async {
    fake.nextResult = const Err(AiAnalysisFailure.geminiUnavailable());
    final ctrl = container.read(aiSuggestionControllerProvider.notifier);
    ctrl.onTextChanged('something');
    await Future<void>.delayed(
      _shortDebounce + const Duration(milliseconds: 50),
    );
    final state = container.read(aiSuggestionControllerProvider);
    expect(state.hasError, isTrue);
  });
}
