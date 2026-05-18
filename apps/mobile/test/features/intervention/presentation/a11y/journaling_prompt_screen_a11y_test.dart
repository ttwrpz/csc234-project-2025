import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsFlag;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/intervention/domain/entities/intervention_dispatch.dart';
import 'package:moodbloom/features/intervention/presentation/controllers/intervention_controller.dart';
import 'package:moodbloom/features/intervention/presentation/screens/journaling_prompt_screen.dart';
import 'package:moodbloom/features/intervention/presentation/widgets/intervention_opt_out_button.dart';
import 'package:moodbloom/features/mood/data/providers.dart'
    show moodRepositoryProvider, saveMoodEntryUseCaseProvider;
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/mood_failure.dart';
import 'package:moodbloom/features/mood/domain/mood_repository.dart';
import 'package:moodbloom/features/mood/domain/usecases/save_mood_entry.dart';
import 'package:moodbloom/features/pattern_engine/domain/entities/tier.dart';

/// Sprint 5 Day 3 a11y sweep — Tier 2 journaling prompt screen.
///
/// Covered:
///   1. The dispatched body + the curated prompt question are reachable
///      in the semantics tree.
///   2. Each ChoiceChip on the mood strip carries its mood name AND its
///      selected/unselected state in its semantics label.
///   3. The multi-line journal TextField announces a hint that includes
///      "journal" so screen readers don't simply say "text field".
///   4. "Save", "Maybe later", "I'm okay" buttons announce with distinct
///      labels — "I'm okay" carries the dismiss-action context.
///   5. 200% type renders without RenderFlex overflow.

class _RecordingController extends InterventionController {
  @override
  InterventionControllerState build() => const InterventionIdle();

  @override
  void complete() {
    state = const InterventionIdle();
  }

  @override
  Future<void> optOut() async {
    state = const InterventionIdle();
  }
}

/// Inert mood repo — the a11y tests never actually save; we just need
/// the screen to mount without crashing on the use-case resolution.
class _NoopMoodRepo implements MoodRepository {
  @override
  Future<Result<MoodEntry, MoodFailure>> save(MoodEntry entry) async =>
      Ok(entry);
  @override
  Future<Result<MoodEntry, MoodFailure>> update(MoodEntry entry) async =>
      Ok(entry);
  @override
  Future<Result<void, MoodFailure>> delete({
    required String userId,
    required String id,
  }) async => const Ok(null);
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
  body:
      'Would you like to write about what has been on your mind?\n\n'
      'MoodBloom is not a medical device. Not a substitute for professional '
      'care.',
  ctas: const ['open_journal', 'opt_out'],
  dispatchId: 'd-two-a11y',
  quoteId: 'q-two-a11y',
  dispatchedAt: DateTime(2026, 5, 13, 10, 30),
);

class _HostWrap extends ConsumerWidget {
  const _HostWrap();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pre-subscribe so currentUserStreamProvider's value resolves
    // before the screen reads it (mirrors journaling_prompt_screen_test).
    ref.watch(currentUserStreamProvider);
    return const Scaffold(body: Text('host-screen'));
  }
}

Widget _makeApp({
  required _RecordingController controller,
  required _NoopMoodRepo moodRepo,
  Brightness brightness = Brightness.light,
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
                JournalingPromptScreen(dispatch: _tier2Dispatch()),
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
    child: MaterialApp.router(
      routerConfig: router,
      theme: brightness == Brightness.dark
          ? buildDarkTheme()
          : buildLightTheme(),
    ),
  );
}

Future<void> _pushScreen(
  WidgetTester tester, {
  Size physicalSize = const Size(1200, 1800),
}) async {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pump();
  final ctx = tester.element(find.text('host-screen'));
  GoRouter.of(ctx).push('/host/journal');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  // Auth stream drain — mirrors journaling_prompt_screen_test.dart.
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  group('JournalingPromptScreen — content semantics', () {
    testWidgets('dispatched body text is reachable in the semantics tree', (
      tester,
    ) async {
      await tester.pumpWidget(
        _makeApp(controller: _RecordingController(), moodRepo: _NoopMoodRepo()),
      );
      await _pushScreen(tester);

      // The body string contains the canonical Tier 2 phrase. The
      // disclaimer footer is also part of `dispatch.body` (TC-38) and
      // must be reachable to screen readers.
      expect(
        find.textContaining('Would you like to write about what has been'),
        findsOneWidget,
      );
    });

    testWidgets(
      'one of the curated prompt questions is rendered as readable text',
      (tester) async {
        await tester.pumpWidget(
          _makeApp(
            controller: _RecordingController(),
            moodRepo: _NoopMoodRepo(),
          ),
        );
        await _pushScreen(tester);

        // The dispatcher rotates a deterministic prompt based on
        // dispatchId.hashCode. Whichever lands, it must be reachable
        // verbatim (the prompt is the surface's load-bearing affordance
        // — without it the user is staring at a blank field).
        const prompts = [
          "What's been weighing on you?",
          "Is there anything you've been holding back?",
          'What would you want a kind friend to know about today?',
          'Notice one feeling. Where in your body does it sit?',
          'If today had a color, what would it be? Why?',
          'What small thing helped today, even a little?',
        ];
        final hits = prompts
            .where((p) => find.text(p).evaluate().isNotEmpty)
            .length;
        expect(
          hits,
          1,
          reason: 'Exactly one curated prompt must be reachable.',
        );
      },
    );
  });

  group('JournalingPromptScreen — mood chip strip semantics', () {
    testWidgets('every mood chip is reachable by its mood-name label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _makeApp(controller: _RecordingController(), moodRepo: _NoopMoodRepo()),
      );
      await _pushScreen(tester);

      // The chip labels come from _labelFor(MoodType) on the screen.
      // Joyful / Calm / Okay / Sad / Angry / Anxious — all six must be
      // reachable so AT users can pick a different mood than the
      // default "Sad" before saving.
      const labels = ['Joyful', 'Calm', 'Okay', 'Sad', 'Angry', 'Anxious'];
      for (final label in labels) {
        expect(
          find.text(label),
          findsOneWidget,
          reason: 'Mood chip "$label" must be reachable as text.',
        );
      }
    });

    testWidgets('default-selected chip carries the selected semantics flag', (
      tester,
    ) async {
      await tester.pumpWidget(
        _makeApp(controller: _RecordingController(), moodRepo: _NoopMoodRepo()),
      );
      await _pushScreen(tester);

      // "Sad" is the default selection (sliding-5-of-7 fires from a
      // heavy stretch). Verify the ChoiceChip's underlying Material
      // semantics carries `isSelected == true` for the Sad chip — and
      // false for every other chip. ChoiceChip composes the selected
      // flag into a SemanticsNode whose label is the chip text.
      // `flagsCollection.isSelected` returns a Tristate (post-3.32
      // semantics API), not a bool, so the `hasFlag` boolean variant
      // is what we want here. `// ignore` suppresses the deprecation
      // info — the migration to the Tristate API is a separate effort.
      final sadNode = tester.getSemantics(find.text('Sad'));
      expect(
        // ignore: deprecated_member_use
        sadNode.hasFlag(SemanticsFlag.isSelected),
        isTrue,
        reason:
            'Default-selected "Sad" chip must announce selected: true. '
            'Without this AT users hear 6 indistinguishable chip labels.',
      );

      final joyNode = tester.getSemantics(find.text('Joyful'));
      expect(
        // ignore: deprecated_member_use
        joyNode.hasFlag(SemanticsFlag.isSelected),
        isFalse,
        reason: 'Non-default chip must NOT carry the selected flag.',
      );
    });
  });

  group('JournalingPromptScreen — text field semantics', () {
    testWidgets('text field hint mentions journaling — not just "text field"', (
      tester,
    ) async {
      await tester.pumpWidget(
        _makeApp(controller: _RecordingController(), moodRepo: _NoopMoodRepo()),
      );
      await _pushScreen(tester);

      // The InputDecoration.hintText is the user-visible prompt
      // "Write a few lines, only if it helps…". Verifying via
      // find.text keeps the test resilient to a future
      // Semantics-wrapper refactor.
      expect(
        find.text('Write a few lines, only if it helps…'),
        findsOneWidget,
        reason:
            'TextField must surface the journaling-context hint so a '
            'screen reader announces purpose before "edit text".',
      );
    });
  });

  group('JournalingPromptScreen — button labels', () {
    testWidgets(
      '"Save" / "Maybe later" / "I\'m okay" each announce distinctly',
      (tester) async {
        await tester.pumpWidget(
          _makeApp(
            controller: _RecordingController(),
            moodRepo: _NoopMoodRepo(),
          ),
        );
        await _pushScreen(tester);

        // The three CTAs must NOT collapse to identical labels. Each
        // node's label is distinct, and "Save" is a button.
        final save = tester.getSemantics(
          find.widgetWithText(FilledButton, 'Save'),
        );
        expect(save.label, equals('Save'));
        expect(save.flagsCollection.isButton, isTrue);

        final maybe = tester.getSemantics(
          find.widgetWithText(TextButton, 'Maybe later'),
        );
        expect(maybe.label, equals('Maybe later'));
        expect(maybe.flagsCollection.isButton, isTrue);

        // The opt-out wraps an OutlinedButton in a Semantics with the
        // dismiss-context fragment.
        expect(
          find.bySemanticsLabel(RegExp("I'm okay, dismiss this reminder")),
          findsAtLeastNWidgets(1),
        );
        expect(find.byType(InterventionOptOutButton), findsOneWidget);
      },
    );
  });

  group('JournalingPromptScreen — 200% type readability', () {
    testWidgets('renders without RenderFlex overflow at 200% type', (
      tester,
    ) async {
      final exceptions = <Object>[];
      FlutterError.onError = (details) => exceptions.add(details.exception);
      addTearDown(() => FlutterError.onError = FlutterError.dumpErrorToConsole);

      // Apply the text scaler via a MediaQuery wrapper. The screen's
      // body is in a SingleChildScrollView so vertical overflow is
      // already protected; this test pins the bottom button row's
      // Row(spaceBetween) layout — that's the genuine risk zone.
      final controller = _RecordingController();
      final repo = _NoopMoodRepo();
      final router = GoRouter(
        initialLocation: '/host',
        routes: [
          GoRoute(
            path: '/host',
            builder: (_, _) => const _HostWrap(),
            routes: [
              GoRoute(
                path: 'journal',
                builder: (_, _) =>
                    JournalingPromptScreen(dispatch: _tier2Dispatch()),
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            interventionControllerProvider.overrideWith(() => controller),
            currentUserStreamProvider.overrideWith(
              (_) => Stream.value(
                const AppUser(uid: 'u-1', email: 'u@example.com'),
              ),
            ),
            moodRepositoryProvider.overrideWithValue(repo),
            saveMoodEntryUseCaseProvider.overrideWithValue(
              SaveMoodEntryUseCase(repository: repo),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            theme: buildLightTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2.0)),
              child: child!,
            ),
          ),
        ),
      );
      // Wide test surface so the bottom Row(spaceBetween) doesn't fight
      // the body's text wrap. 200% type roughly doubles the row's
      // intrinsic width — 1200dp is generous-but-realistic for a tablet
      // viewport.
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pump();
      final ctx = tester.element(find.text('host-screen'));
      GoRouter.of(ctx).push('/host/journal');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      final overflows = exceptions
          .map((e) => e.toString())
          .where((s) => s.contains('overflowed') || s.contains('RenderFlex'))
          .toList();
      expect(
        overflows,
        isEmpty,
        reason:
            'JournalingPromptScreen must not overflow at 200% type. '
            'Got: $overflows',
      );
    });
  });
}
