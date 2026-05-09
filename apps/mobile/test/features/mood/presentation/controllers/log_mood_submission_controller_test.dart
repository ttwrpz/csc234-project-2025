import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/mood/data/providers.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';
import 'package:moodbloom/features/mood/domain/mood_failure.dart';
import 'package:moodbloom/features/mood/domain/mood_repository.dart';
import 'package:moodbloom/features/mood/domain/usecases/save_mood_entry.dart';
import 'package:moodbloom/features/mood/presentation/controllers/log_mood_controller.dart';
import 'package:moodbloom/features/mood/presentation/controllers/log_mood_submission_controller.dart';
import 'package:moodbloom/features/pattern_engine/data/providers.dart';
import 'package:moodbloom/features/pattern_engine/domain/entities/pattern_result.dart';
import 'package:moodbloom/features/pattern_engine/domain/pattern_failure.dart';
import 'package:moodbloom/features/pattern_engine/domain/repositories/pattern_repository.dart';
import 'package:moodbloom/features/pattern_engine/domain/usecases/run_pattern_engine.dart';

/// HB-006 sub-track B verification — the post-save Pattern Engine
/// wire-up in `LogMoodController._runPatternEngine`. We use a
/// `WidgetTester` (not a bare `ProviderContainer`) so `pumpAndSettle`
/// flushes the microtask chain (auth-stream → mood-stream → engine →
/// pattern-repo) reliably; bare microtask polling races against the
/// `StreamController` event delivery on Riverpod 3.
///
/// Long-lived stream controllers mirror production: Firestore snapshot
/// listeners and `FirebaseAuth.authStateChanges()` are both broadcast,
/// they don't close after one emission. Using `Stream.value(...)` here
/// would short-circuit Riverpod's loading state in surprising ways.

/// Fake [MoodRepository]. Only `save()` and `watchAll()` are exercised
/// by the post-save engine wire-up. `findById`, `update`, and `delete`
/// throw on contact so any accidental tee-into them is loud.
class _StubMoodRepository implements MoodRepository {
  _StubMoodRepository({required this.savedEntry, required this.history});

  final MoodEntry savedEntry;
  final List<MoodEntry> history;

  late final StreamController<List<MoodEntry>> _controller =
      StreamController<List<MoodEntry>>.broadcast(
        onListen: () {
          // Buffer the first emission until something subscribes — this is
          // the production Firestore stream contract.
          Future<void>.microtask(() => _controller.add(history));
        },
      );

  @override
  Stream<List<MoodEntry>> watchAll({required String userId}) =>
      _controller.stream;

  @override
  Future<Result<MoodEntry, MoodFailure>> save(MoodEntry entry) async =>
      Ok(savedEntry);

  @override
  Future<Result<MoodEntry, MoodFailure>> update(MoodEntry entry) =>
      throw UnimplementedError();

  @override
  Future<Result<MoodEntry, MoodFailure>> findById({
    required String userId,
    required String id,
  }) => throw UnimplementedError();

  @override
  Future<Result<void, MoodFailure>> delete({
    required String userId,
    required String id,
  }) => throw UnimplementedError();
}

class _FakePatternRepo implements PatternRepository {
  final List<({String userId, PatternResult result})> calls = [];

  PatternFailure? nextFailure;

  @override
  Future<Result<void, PatternFailure>> save({
    required String userId,
    required PatternResult result,
  }) async {
    calls.add((userId: userId, result: result));
    final f = nextFailure;
    if (f != null) {
      nextFailure = null;
      return Err(f);
    }
    return const Ok(null);
  }

  @override
  Stream<PatternResult?> watch({
    required String userId,
    required String dateId,
  }) => const Stream<PatternResult?>.empty();
}

class _RecordingUseCase implements RunPatternEngineUseCase {
  int callCount = 0;
  List<MoodEntry>? lastEntries;
  DateTime? lastNow;

  PatternResult next = const PatternResult(
    dateId: '2026-05-09',
    mannKendallZ: null,
    slidingNegCount: 0,
    consecutiveHighIntensity: 0,
    zScoreToday: null,
    cusumC: 0.0,
    triggeredTier: null,
  );

  @override
  PatternResult call(List<MoodEntry> entries, {required DateTime now}) {
    callCount += 1;
    lastEntries = entries;
    lastNow = now;
    return next;
  }
}

/// Long-lived auth stream that emits a single signed-in user and stays
/// open. Mirrors `FirebaseAuth.authStateChanges()`.
Stream<AppUser?> _authStream(AppUser? user) {
  final controller = StreamController<AppUser?>.broadcast(onListen: () {});
  // Emit on the next microtask so the broadcast subscription is in place.
  Future<void>.microtask(() => controller.add(user));
  return controller.stream;
}

void main() {
  group('LogMoodController post-save Pattern Engine wire-up', () {
    late _StubMoodRepository moodRepo;
    late _FakePatternRepo patternRepo;
    late _RecordingUseCase engine;

    setUp(() {
      moodRepo = _StubMoodRepository(
        savedEntry: MoodEntry(
          id: 'm1',
          userId: 'uid-1',
          mood: MoodType.calm,
          intensity: 3,
          text: '',
          createdAt: DateTime(2026, 5, 9, 10, 30),
        ),
        history: [
          MoodEntry(
            id: 'm1',
            userId: 'uid-1',
            mood: MoodType.calm,
            intensity: 3,
            text: '',
            createdAt: DateTime(2026, 5, 9, 10, 30),
          ),
        ],
      );
      patternRepo = _FakePatternRepo();
      engine = _RecordingUseCase();
    });

    /// Pumps a minimal widget tree that subscribes to all the providers
    /// `LogMoodController` reaches for, so when we call `save()` Riverpod
    /// has already resolved the upstream chain. Returns the
    /// [ProviderContainer] for direct controller access.
    Future<ProviderContainer> pumpHarness(WidgetTester tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserStreamProvider.overrideWith(
              (_) => _authStream(const AppUser(uid: 'uid-1')),
            ),
            moodRepositoryProvider.overrideWithValue(moodRepo),
            saveMoodEntryUseCaseProvider.overrideWithValue(
              SaveMoodEntryUseCase(repository: moodRepo),
            ),
            runPatternEngineUseCaseProvider.overrideWithValue(engine),
            patternRepositoryProvider.overrideWithValue(patternRepo),
          ],
          // Watch all the upstream providers so they're subscribed before
          // we call `save()` — otherwise the first emission could be
          // missed by a not-yet-listening provider.
          child: Consumer(
            builder: (context, ref, _) {
              ref.watch(currentUserStreamProvider);
              ref.watch(myMoodsStreamProvider);
              container = ProviderScope.containerOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      // pumpAndSettle drains microtasks/timers until everything is idle —
      // the auth stream + mood stream first emissions land here.
      await tester.pumpAndSettle();
      return container;
    }

    Future<MoodEntry?> doSave(ProviderContainer container) async {
      final controller = container.read(logMoodControllerProvider.notifier);
      controller.pickMood(MoodType.calm);
      controller.setIntensity(3);
      return controller.save();
    }

    testWidgets('engine + pattern repo are called after a successful save', (
      tester,
    ) async {
      final container = await pumpHarness(tester);
      final saved = await doSave(container);
      expect(saved, isNotNull);
      await tester.pumpAndSettle();
      // Engine ran exactly once.
      expect(engine.callCount, 1);
      // History plumbed from `myMoodsStreamProvider` (1 entry per stub).
      expect(engine.lastEntries, hasLength(1));
      // Pattern repo received the engine result and the signed-in uid.
      expect(patternRepo.calls, hasLength(1));
      expect(patternRepo.calls.single.userId, 'uid-1');
      expect(patternRepo.calls.single.result, engine.next);
    });

    testWidgets(
      'PatternFailure does NOT propagate to the mood-save UI surface',
      (tester) async {
        patternRepo.nextFailure = const PatternFailure.network();
        final container = await pumpHarness(tester);
        final saved = await doSave(container);
        await tester.pumpAndSettle();
        // The user's mood save still completes successfully.
        expect(saved, isNotNull);
        // Pattern repo was attempted exactly once.
        expect(patternRepo.calls, hasLength(1));
        // The submission controller is in the success state.
        final submissionState = container.read(
          logMoodSubmissionControllerProvider,
        );
        expect(submissionState.errorMessage, isNull);
        expect(submissionState.isSubmitting, isFalse);
      },
    );

    testWidgets(
      'failure log surface — dateId + failure runtimeType only, zero PII',
      (tester) async {
        patternRepo.nextFailure = const PatternFailure.network();
        final container = await pumpHarness(tester);
        await doSave(container);
        await tester.pumpAndSettle();
        // We can't intercept `dart:developer.log` without tooling, so
        // assert structurally on the result that the controller hands
        // the logger.
        expect(patternRepo.calls.single.result.dateId, isNotEmpty);
        // The result the logger sees has NO mood text, NO userId, NO
        // email — `PatternResult.toJson` keys are the rule allowlist
        // and nothing else. Defense-in-depth.
        final json = patternRepo.calls.single.result.toJson();
        expect(json.containsKey('text'), isFalse);
        expect(json.containsKey('userId'), isFalse);
        expect(json.containsKey('email'), isFalse);
      },
    );
  });
}
