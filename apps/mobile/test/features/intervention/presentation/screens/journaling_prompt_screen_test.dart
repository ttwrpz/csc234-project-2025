import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/intervention/domain/entities/intervention_dispatch.dart';
import 'package:moodbloom/features/intervention/presentation/controllers/intervention_controller.dart';
import 'package:moodbloom/features/intervention/presentation/screens/journaling_prompt_screen.dart';
import 'package:moodbloom/features/mood/data/providers.dart'
    show saveMoodEntryUseCaseProvider, moodRepositoryProvider;
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';
import 'package:moodbloom/features/mood/domain/mood_failure.dart';
import 'package:moodbloom/features/mood/domain/mood_repository.dart';
import 'package:moodbloom/features/mood/domain/usecases/save_mood_entry.dart';
import 'package:moodbloom/features/pattern_engine/domain/entities/tier.dart';

class _RecordingController extends InterventionController {
  int completeCalls = 0;
  int optOutCalls = 0;

  @override
  InterventionControllerState build() => const InterventionIdle();

  @override
  void complete() {
    completeCalls += 1;
    state = const InterventionIdle();
  }

  @override
  Future<void> optOut() async {
    optOutCalls += 1;
    state = const InterventionIdle();
  }
}

/// Recording mood repository — the journaling screen invokes
/// `SaveMoodEntryUseCase`, which in turn invokes
/// [MoodRepository.save]. Asserting on this layer keeps the test
/// orthogonal to the use case's internal validation.
class _RecordingMoodRepo implements MoodRepository {
  final List<MoodEntry> saved = [];
  bool failNext = false;

  @override
  Future<Result<MoodEntry, MoodFailure>> save(MoodEntry entry) async {
    if (failNext) {
      failNext = false;
      return const Err(MoodFailure.network());
    }
    saved.add(entry);
    return Ok(entry);
  }

  @override
  Future<Result<MoodEntry, MoodFailure>> update(MoodEntry entry) async =>
      throw UnimplementedError();

  @override
  Future<Result<void, MoodFailure>> delete({
    required String userId,
    required String id,
  }) async => throw UnimplementedError();

  @override
  Stream<List<MoodEntry>> watchAll({required String userId}) =>
      const Stream.empty();

  @override
  Future<Result<MoodEntry, MoodFailure>> findById({
    required String userId,
    required String id,
  }) async => Err(MoodFailure.notFound(id));
}

InterventionDispatch _tier2Dispatch() => InterventionDispatch(
  tier: Tier.two,
  body: 'Tier 2 quote.\n\nfooter.',
  ctas: const ['open_journal', 'opt_out'],
  dispatchId: 'd-two-fixed',
  quoteId: 'q-two-fixed',
  dispatchedAt: DateTime(2026, 5, 13, 10, 30),
);

/// Host wrapper that pre-subscribes to [currentUserStreamProvider] so
/// the StreamProvider's value resolves before the screen reads it.
/// Without this, `ref.read(currentUserStreamProvider).value?.uid`
/// returns `null` on the first tap.
class _HostWrap extends ConsumerWidget {
  const _HostWrap();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(currentUserStreamProvider);
    return const Scaffold(body: Text('host-screen'));
  }
}

Widget _makeApp({
  required InterventionDispatch? dispatch,
  required _RecordingController controller,
  required _RecordingMoodRepo moodRepo,
}) {
  final router = GoRouter(
    initialLocation: '/host',
    routes: [
      GoRoute(
        path: '/host',
        builder: (_, _) => const _HostWrap(),
        routes: [
          GoRoute(
            path: 'journal',
            builder: (context, state) =>
                JournalingPromptScreen(dispatch: dispatch),
          ),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      interventionControllerProvider.overrideWith(() => controller),
      currentUserStreamProvider.overrideWith(
        (_) => Stream.value(const AppUser(uid: 'u-1', email: 'u@example.com')),
      ),
      moodRepositoryProvider.overrideWithValue(moodRepo),
      saveMoodEntryUseCaseProvider.overrideWithValue(
        SaveMoodEntryUseCase(repository: moodRepo),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

/// Push the journal screen on top of '/host' so `context.pop()` works.
/// Sets a 1200×900 surface so the bottom button row stays in-frame.
/// Pumps until the auth stream delivers its first event (otherwise
/// `_onSave`'s `value?.uid` is still null on the first frame).
Future<void> _pushScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pump();
  final ctx = tester.element(find.text('host-screen'));
  GoRouter.of(ctx).push('/host/journal');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  // Drain the auth stream so the screen's `_onSave` finds a uid.
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  group('JournalingPromptScreen', () {
    testWidgets('renders body verbatim from seeded dispatch', (tester) async {
      final controller = _RecordingController();
      final repo = _RecordingMoodRepo();
      await tester.pumpWidget(
        _makeApp(
          dispatch: _tier2Dispatch(),
          controller: controller,
          moodRepo: repo,
        ),
      );
      await _pushScreen(tester);
      expect(find.textContaining('Tier 2 quote.'), findsOneWidget);
    });

    testWidgets('renders one of the curated prompts', (tester) async {
      final controller = _RecordingController();
      final repo = _RecordingMoodRepo();
      await tester.pumpWidget(
        _makeApp(
          dispatch: _tier2Dispatch(),
          controller: controller,
          moodRepo: repo,
        ),
      );
      await _pushScreen(tester);
      // Any of the curated prompts should be on screen.
      const prompts = [
        "What's been weighing on you?",
        "Is there anything you've been holding back?",
        'What would you want a kind friend to know about today?',
        'Notice one feeling. Where in your body does it sit?',
        'If today had a color, what would it be? Why?',
        'What small thing helped today, even a little?',
      ];
      final found = prompts
          .where((p) => find.text(p).evaluate().isNotEmpty)
          .length;
      expect(found, 1, reason: 'Exactly one curated prompt must render.');
    });

    testWidgets(
      'typed text + Save → repo.save called with mood + intensity 3',
      (tester) async {
        final controller = _RecordingController();
        final repo = _RecordingMoodRepo();
        await tester.pumpWidget(
          _makeApp(
            dispatch: _tier2Dispatch(),
            controller: controller,
            moodRepo: repo,
          ),
        );
        await _pushScreen(tester);
        await tester.enterText(find.byType(TextField), 'I felt heavy today.');
        await tester.tap(find.widgetWithText(FilledButton, 'Save'));
        // pump() is sufficient — the screen pops back to /host, then the
        // snackbar lingers but doesn't block subsequent assertions.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(repo.saved, hasLength(1));
        expect(repo.saved.first.text, 'I felt heavy today.');
        expect(
          repo.saved.first.intensity,
          3,
          reason:
              'The journaling flow skips the slider step on purpose — '
              'intensity defaults to 3 (neutral).',
        );
        expect(repo.saved.first.mood, MoodType.sad);
        expect(controller.completeCalls, 1);
      },
    );

    testWidgets('Save Ok → snackbar then screen pops', (tester) async {
      final controller = _RecordingController();
      final repo = _RecordingMoodRepo();
      await tester.pumpWidget(
        _makeApp(
          dispatch: _tier2Dispatch(),
          controller: controller,
          moodRepo: repo,
        ),
      );
      await _pushScreen(tester);
      await tester.enterText(find.byType(TextField), 'hi');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();
      // SnackBar surfaces on the same frame as the controller.complete().
      expect(
        find.textContaining('Saved to your journal'),
        findsAtLeastNWidgets(1),
      );
      // Drain the snackbar timer + the post-pop animations without using
      // pumpAndSettle (which can hang on lingering dismissible timers).
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('Save Err → snackbar, screen stays', (tester) async {
      final controller = _RecordingController();
      final repo = _RecordingMoodRepo()..failNext = true;
      await tester.pumpWidget(
        _makeApp(
          dispatch: _tier2Dispatch(),
          controller: controller,
          moodRepo: repo,
        ),
      );
      await _pushScreen(tester);
      await tester.enterText(find.byType(TextField), 'hi');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();
      expect(find.textContaining("Couldn't save"), findsAtLeastNWidgets(1));
      // Screen still mounted — body text still visible.
      expect(find.textContaining('Tier 2 quote.'), findsOneWidget);
    });

    testWidgets('Maybe later → complete() + pop, no save', (tester) async {
      final controller = _RecordingController();
      final repo = _RecordingMoodRepo();
      await tester.pumpWidget(
        _makeApp(
          dispatch: _tier2Dispatch(),
          controller: controller,
          moodRepo: repo,
        ),
      );
      await _pushScreen(tester);
      await tester.tap(find.text('Maybe later'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(controller.completeCalls, 1);
      expect(repo.saved, isEmpty);
    });

    testWidgets("I'm okay → optOut() + pop", (tester) async {
      final controller = _RecordingController();
      final repo = _RecordingMoodRepo();
      await tester.pumpWidget(
        _makeApp(
          dispatch: _tier2Dispatch(),
          controller: controller,
          moodRepo: repo,
        ),
      );
      await _pushScreen(tester);
      await tester.tap(find.text("I'm okay"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(controller.optOutCalls, 1);
      expect(repo.saved, isEmpty);
    });
  });
}
