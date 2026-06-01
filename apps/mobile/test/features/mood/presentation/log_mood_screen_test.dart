import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/mood/data/providers.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';
import 'package:moodbloom/features/mood/presentation/log_mood_screen.dart';
import 'package:moodbloom/features/mood/presentation/widgets/mood_type_tile.dart';
// MbPrimaryButton wraps a FilledButton internally; finders below match the
// FilledButton + the prototype's "Save entry" / "Pick a feeling to continue"
// labels.

import '../domain/fakes/fake_mood_repository.dart';

/// A stream that synchronously emits [user] on listen and stays open. Using
/// `Stream.value` ends the stream and emits via a microtask, which means
/// `StreamProvider.value` may still be null at the moment a button tap
/// reads it. Backing the override with a long-lived controller fixes that.
Stream<AppUser?> _userStream(AppUser? user) {
  final controller = StreamController<AppUser?>();
  controller.add(user);
  return controller.stream;
}

Future<void> _pumpLogMood(
  WidgetTester tester, {
  required FakeMoodRepository repo,
  Size surfaceSize = const Size(700, 1600),
}) async {
  // Default surface mirrors a tall phone-landscape / small-tablet portrait:
  // width <720 forces the narrow single-column layout, height keeps the
  // Save button on screen so tests don't need to scroll to interact with
  // it. Wide-layout tests pass an explicit surfaceSize to flip into the
  // desktop two-column path. We deliberately stay >414dp because the
  // existing MbPrimaryButton Row needs more horizontal room than a
  // typical phone width to render its label + spinner without overflow
  // (see MbPrimaryButton).
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        moodRepositoryProvider.overrideWithValue(repo),
        currentUserStreamProvider.overrideWith(
          (_) => _userStream(const AppUser(uid: 'u-1', email: 'u@example.com')),
        ),
      ],
      // The controller does ref.read(currentUserStreamProvider) at save time;
      // we make sure the provider is subscribed *before* that read by
      // wrapping the screen in a Consumer that watches it during build.
      //
      // We also wire a tiny GoRouter so the screen's success-path
      // `context.go('/history')` finds a router and does not assert.
      child: MaterialApp.router(
        theme: buildLightTheme(),
        routerConfig: GoRouter(
          initialLocation: '/log',
          routes: [
            GoRoute(
              path: '/log',
              builder: (_, _) => Consumer(
                builder: (context, ref, _) {
                  ref.watch(currentUserStreamProvider);
                  return const LogMoodScreen();
                },
              ),
            ),
            GoRoute(
              path: '/history',
              builder: (_, _) =>
                  const Scaffold(body: Center(child: Text('history-stub'))),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Locates the Save FilledButton without depending on a Key in production.
/// The button's label is "Save entry" once a mood is picked, and
/// "Pick a feeling to continue" while the draft has no mood - the
/// underlying [FilledButton] (wrapped by `MbPrimaryButton`) is the same
/// instance either way, so we look up by widget type and pick the only
/// one in the tree.
Finder _saveButton() => find.byType(FilledButton);

void main() {
  group('LogMoodScreen', () {
    testWidgets('Save button is disabled until a mood is selected', (
      tester,
    ) async {
      final repo = FakeMoodRepository();
      await _pumpLogMood(tester, repo: repo);

      final initial = tester.widget<FilledButton>(_saveButton());
      expect(
        initial.onPressed,
        isNull,
        reason: 'Save must be disabled when MoodDraft.mood is null',
      );
    });

    testWidgets('selecting a mood enables Save', (tester) async {
      final repo = FakeMoodRepository();
      await _pumpLogMood(tester, repo: repo);

      // Tap the "happy" tile (label rendered by MoodTypeTile).
      await tester.tap(find.text('happy'));
      await tester.pumpAndSettle();

      final after = tester.widget<FilledButton>(_saveButton());
      expect(
        after.onPressed,
        isNotNull,
        reason: 'Save must enable once a MoodType is picked',
      );
      // The selected tile carries selected: true.
      expect(
        find.byWidgetPredicate(
          (w) => w is MoodTypeTile && w.selected && w.type == MoodType.happy,
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'wide surface (>=720dp) renders the two-column desktop layout',
      (tester) async {
        final repo = FakeMoodRepository();
        await _pumpLogMood(
          tester,
          repo: repo,
          surfaceSize: const Size(1280, 800),
        );

        // The wide layout is identified by the ValueKey on its outermost
        // Center; the narrow layout is keyed differently and must NOT be
        // present when the surface is wide.
        expect(
          find.byKey(const ValueKey('log-mood-wide')),
          findsOneWidget,
          reason: 'wide surface must select the two-column layout',
        );
        expect(
          find.byKey(const ValueKey('log-mood-narrow')),
          findsNothing,
          reason:
              'narrow ListView layout must NOT render alongside the wide '
              'layout - exactly one of the two paths is taken per build',
        );
        // v1.6 redesign: the wide layout is a single Row that contains
        // two Expanded Columns; the inner-column ValueKeys were dropped.
        // Verify the structural Row + both inner columns by checking
        // the section labels are present in the tree (each column owns
        // a distinct MbSectionLabel).
        expect(
          find.byWidgetPredicate(
            (w) => w is MbSectionLabel && w.text == 'HOW ARE YOU?',
          ),
          findsOneWidget,
        );

        // The save button is present and starts disabled (no mood picked).
        final initial = tester.widget<FilledButton>(_saveButton());
        expect(initial.onPressed, isNull);
      },
    );

    testWidgets(
      'narrow surface (<720dp) renders the single-column ListView layout',
      (tester) async {
        final repo = FakeMoodRepository();
        await _pumpLogMood(
          tester,
          repo: repo,
          surfaceSize: const Size(700, 1600),
        );

        expect(find.byKey(const ValueKey('log-mood-narrow')), findsOneWidget);
        expect(find.byKey(const ValueKey('log-mood-wide')), findsNothing);
      },
    );

    testWidgets('tapping Save invokes SaveMoodEntryUseCase via the repo', (
      tester,
    ) async {
      final repo = FakeMoodRepository(
        saveResult: Ok(
          MoodEntry(
            id: 'allocated-id',
            userId: 'u-1',
            mood: MoodType.happy,
            intensity: 3,
            text: '',
            createdAt: DateTime.utc(2026, 4, 28, 12),
          ),
        ),
      );
      await _pumpLogMood(tester, repo: repo);

      await tester.tap(find.text('happy'));
      await tester.pumpAndSettle();

      // Sanity check: there is exactly one Save button and it is enabled
      // before we tap.
      expect(_saveButton(), findsOneWidget);
      expect(tester.widget<FilledButton>(_saveButton()).onPressed, isNotNull);
      await tester.ensureVisible(_saveButton());
      await tester.pumpAndSettle();
      await tester.tap(_saveButton());
      await tester.pumpAndSettle();

      // Diagnostic: did we trip the "signed-in" guard?
      expect(
        find.text('You need to be signed in.'),
        findsNothing,
        reason: 'currentUserStreamProvider override should provide a user',
      );
      expect(
        repo.saveCalls,
        hasLength(1),
        reason: 'tapping Save with valid draft must hit the repository once',
      );
      expect(repo.saveCalls.single.userId, equals('u-1'));
      expect(repo.saveCalls.single.mood, equals(MoodType.happy));
      expect(repo.saveCalls.single.intensity, equals(3));
    });
  });
}
