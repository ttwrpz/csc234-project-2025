import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/garden/data/providers.dart';
import 'package:moodbloom/features/garden/domain/intervention_state_repository.dart';
import 'package:moodbloom/features/garden/presentation/garden_screen.dart';
import 'package:moodbloom/features/garden/presentation/widgets/hotline_footer.dart';
import 'package:moodbloom/features/mood/data/providers.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

import '../../mood/domain/fakes/fake_mood_repository.dart';

/// Verification of HB-003 §5.5c — the 10-day Hotline 1323 footer surfaces
/// when `firstTriggeredAt + 10d <= now` AND the detector is currently
/// triggering, and stays absent otherwise.
///
/// Exists per the brief's "verification track, not a build track":
/// - `pattern_detector.dart::_withEscalation` already sets
///   `escalated: true` when the 10-day threshold is crossed.
/// - `garden_screen.dart` already conditionally renders [HotlineFooter]
///   on `intervention.escalated`.
/// - 5.5a populates `firstTriggeredAt` via `CheerUpController.onShown`.
///
/// What this test guarantees: the three pieces above stay wired together
/// end-to-end. A future regression that decouples any of them — e.g. a
/// refactor that drops the `escalated` flag from the wiring, or pushes
/// the footer behind a feature flag — fails this test.

class _StaticAnchorsRepo implements InterventionStateRepository {
  _StaticAnchorsRepo({this.firstTriggeredAt});

  // `lastTriggeredAt` is intentionally null on every test in this file —
  // the 48h cooldown gate would otherwise mask the trigger that drives
  // escalation. Each test pumps qualifying entries fresh so no cooldown
  // is in effect.
  final DateTime? firstTriggeredAt;

  @override
  Future<Result<InterventionAnchors, InterventionStateFailure>> read() async {
    return Ok(InterventionAnchors(firstTriggeredAt: firstTriggeredAt));
  }

  @override
  Future<Result<void, InterventionStateFailure>> writeLastTriggeredAt(
    DateTime now,
  ) async => const Ok(null);

  @override
  Future<Result<void, InterventionStateFailure>> writeFirstTriggeredAtIfNull(
    DateTime now,
  ) async => const Ok(null);

  @override
  Future<Result<void, InterventionStateFailure>> clearFirstTriggeredAt() async {
    return const Ok(null);
  }
}

Stream<AppUser?> _userStream(AppUser? user) {
  final controller = StreamController<AppUser?>();
  controller.add(user);
  return controller.stream;
}

MoodEntry _entry(MoodType mood, DateTime createdAt, {required String id}) {
  return MoodEntry(
    id: id,
    userId: 'u-1',
    mood: mood,
    intensity: 3,
    text: '',
    createdAt: createdAt,
  );
}

/// 5-of-7 negative-day fixture — sufficient to fire the detector's
/// first rule at "now". `lastTriggeredAt` is left null in the repo so
/// the cooldown gate doesn't suppress the trigger; the detector then
/// consults `firstTriggeredAt` for the escalation decision.
List<MoodEntry> _qualifyingEntries() {
  final today = DateTime.now();
  return [
    for (var i = 0; i < 5; i += 1)
      _entry(MoodType.sad, today.subtract(Duration(days: i)), id: 'e$i'),
  ];
}

Future<void> _pumpGarden(
  WidgetTester tester, {
  required InterventionStateRepository repo,
  required FakeMoodRepository moodRepo,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        moodRepositoryProvider.overrideWithValue(moodRepo),
        currentUserStreamProvider.overrideWith(
          (_) => _userStream(const AppUser(uid: 'u-1', email: 'u@example.com')),
        ),
        interventionStateRepositoryProvider.overrideWith((_) async => repo),
      ],
      child: MaterialApp(theme: buildLightTheme(), home: const GardenScreen()),
    ),
  );

  // Pump enough frames to settle providers + run the post-frame callback
  // that dispatches the controller's onShown.
  for (var i = 0; i < 8; i += 1) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('HotlineFooter visibility (HB-003 §5.5c)', () {
    testWidgets(
      'firstTriggeredAt = now - 11 days + currently triggering → footer renders',
      (tester) async {
        final moodRepo = FakeMoodRepository()
          ..streamedEntries = [_qualifyingEntries()];
        final repo = _StaticAnchorsRepo(
          firstTriggeredAt: DateTime.now().subtract(const Duration(days: 11)),
        );

        await _pumpGarden(tester, repo: repo, moodRepo: moodRepo);

        expect(find.byType(HotlineFooter), findsOneWidget);
        // The locked CLAUDE.md substring must be visible verbatim. Using
        // textContaining absorbs the soft-wrap break in the rendered
        // Text.rich without depending on exact line breaks.
        expect(find.textContaining('1323'), findsWidgets);
      },
    );

    testWidgets(
      'firstTriggeredAt = now - 9 days + currently triggering → footer ABSENT',
      (tester) async {
        final moodRepo = FakeMoodRepository()
          ..streamedEntries = [_qualifyingEntries()];
        final repo = _StaticAnchorsRepo(
          firstTriggeredAt: DateTime.now().subtract(const Duration(days: 9)),
        );

        await _pumpGarden(tester, repo: repo, moodRepo: moodRepo);

        expect(find.byType(HotlineFooter), findsNothing);
      },
    );

    testWidgets(
      'firstTriggeredAt = null + currently triggering → footer ABSENT '
      '(escalation requires the anchor)',
      (tester) async {
        final moodRepo = FakeMoodRepository()
          ..streamedEntries = [_qualifyingEntries()];
        final repo = _StaticAnchorsRepo();

        await _pumpGarden(tester, repo: repo, moodRepo: moodRepo);

        expect(find.byType(HotlineFooter), findsNothing);
      },
    );

    testWidgets('firstTriggeredAt = now - 11 days + NOT currently triggering → '
        'footer ABSENT (escalation gated on triggered)', (tester) async {
      // A single positive entry today → detector reports triggered=false,
      // so escalated is also false even though the 10-day threshold has
      // been crossed.
      final moodRepo = FakeMoodRepository()
        ..streamedEntries = [
          [_entry(MoodType.happy, DateTime.now(), id: 'p1')],
        ];
      final repo = _StaticAnchorsRepo(
        firstTriggeredAt: DateTime.now().subtract(const Duration(days: 11)),
      );

      await _pumpGarden(tester, repo: repo, moodRepo: moodRepo);

      expect(find.byType(HotlineFooter), findsNothing);
    });

    testWidgets(
      'firstTriggeredAt = exactly 10 days ago (boundary) + triggering → '
      'footer renders (>= 10 days, not strictly >)',
      (tester) async {
        // Detector predicate is `now.difference(firstTriggeredAt) >= 10d`,
        // so the boundary is inclusive.
        final moodRepo = FakeMoodRepository()
          ..streamedEntries = [_qualifyingEntries()];
        final repo = _StaticAnchorsRepo(
          firstTriggeredAt: DateTime.now().subtract(const Duration(days: 10)),
        );

        await _pumpGarden(tester, repo: repo, moodRepo: moodRepo);

        expect(find.byType(HotlineFooter), findsOneWidget);
      },
    );
  });
}
