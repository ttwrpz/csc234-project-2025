import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/app/feature_flags.dart';
import 'package:moodbloom/app/providers.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/garden/data/providers.dart';
import 'package:moodbloom/features/garden/domain/cheer_up_events_repository.dart';
import 'package:moodbloom/features/garden/domain/intervention_state_repository.dart';
import 'package:moodbloom/features/garden/presentation/garden_screen.dart';
import 'package:moodbloom/features/mood/data/providers.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

import '../../mood/domain/fakes/fake_mood_repository.dart';

/// Recording fake of [InterventionStateRepository] for the screen test.
/// Counts every write so we can assert that GardenScreen's
/// addPostFrameCallback dispatched onShown exactly once when the
/// detector flipped to triggered: true.
class _RecordingRepo implements InterventionStateRepository {
  int writeLastCalls = 0;
  int writeFirstIfNullCalls = 0;

  @override
  Future<Result<InterventionAnchors, InterventionStateFailure>> read() async {
    return const Ok(InterventionAnchors());
  }

  @override
  Future<Result<void, InterventionStateFailure>> writeLastTriggeredAt(
    DateTime now,
  ) async {
    writeLastCalls += 1;
    return const Ok(null);
  }

  @override
  Future<Result<void, InterventionStateFailure>> writeFirstTriggeredAtIfNull(
    DateTime now,
  ) async {
    writeFirstIfNullCalls += 1;
    return const Ok(null);
  }

  @override
  Future<Result<void, InterventionStateFailure>> clearFirstTriggeredAt() async {
    return const Ok(null);
  }
}

/// Recording fake of [CheerUpEventsRepository] for the screen test.
/// The 5.5b dispatch path requires this provider to be overridden too;
/// without it, the controller tries to read a real
/// `CheerUpEventsRepositoryImpl` that depends on FirebaseFirestore.
class _RecordingEventsRepo implements CheerUpEventsRepository {
  final List<({String reason, DateTime now})> calls =
      <({String reason, DateTime now})>[];

  @override
  Future<Result<void, CheerUpEventsFailure>> createEvent({
    required String reason,
    required DateTime now,
  }) async {
    calls.add((reason: reason, now: now));
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

/// Builds a 5-of-7 negative-day fixture ending today: five distinct days
/// each carrying ≥1 negative entry, within the last seven local-midnight
/// days. Sufficient to fire the detector's first rule.
List<MoodEntry> _fiveOfSevenNegative() {
  final today = DateTime.now();
  final days = [
    for (var i = 0; i < 5; i += 1) today.subtract(Duration(days: i)),
  ];
  return [
    for (var i = 0; i < days.length; i += 1)
      _entry(MoodType.sad, days[i], id: 'e$i'),
  ];
}

void main() {
  group('GardenScreen cheer-up dispatch', () {
    testWidgets(
      'detector triggered → CheerUpController.onShown writes both anchors AND the event doc',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1600));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final moodRepo = FakeMoodRepository()
          ..streamedEntries = [_fiveOfSevenNegative()];
        final stateRepo = _RecordingRepo();
        final eventsRepo = _RecordingEventsRepo();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              moodRepositoryProvider.overrideWithValue(moodRepo),
              currentUserStreamProvider.overrideWith(
                (_) => _userStream(
                  const AppUser(uid: 'u-1', email: 'u@example.com'),
                ),
              ),
              interventionStateRepositoryProvider.overrideWith(
                (_) async => stateRepo,
              ),
              cheerUpEventsRepositoryProvider.overrideWithValue(eventsRepo),
              // ADR-0011 §4: existing dispatch tests assert behaviour
              // BEFORE the v1.0 gate (default false). Flip ON for these.
              featureFlagsProvider.overrideWithValue(
                FeatureFlags.defaults().copyWith(
                  interventionDispatchEnabled: true,
                ),
              ),
            ],
            child: MaterialApp(
              theme: buildLightTheme(),
              home: const GardenScreen(),
            ),
          ),
        );

        // Pump enough frames to settle providers + run the
        // addPostFrameCallback that dispatches onShown.
        for (var i = 0; i < 8; i += 1) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        // Both anchors written exactly once. The controller's idempotency
        // guarantees no double-fire even if the listen rebuilds.
        expect(stateRepo.writeLastCalls, 1);
        expect(stateRepo.writeFirstIfNullCalls, 1);
        // 5.5b - event-doc create dispatched alongside the anchors.
        expect(eventsRepo.calls, hasLength(1));
        expect(eventsRepo.calls.single.reason, '5_of_7_negative');
      },
    );

    testWidgets(
      'detector NOT triggered → no anchor writes and no event-doc create',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1600));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        // A single positive entry today → detector reports triggered=false.
        final moodRepo = FakeMoodRepository()
          ..streamedEntries = [
            [_entry(MoodType.happy, DateTime.now(), id: 'p1')],
          ];
        final stateRepo = _RecordingRepo();
        final eventsRepo = _RecordingEventsRepo();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              moodRepositoryProvider.overrideWithValue(moodRepo),
              currentUserStreamProvider.overrideWith(
                (_) => _userStream(
                  const AppUser(uid: 'u-1', email: 'u@example.com'),
                ),
              ),
              interventionStateRepositoryProvider.overrideWith(
                (_) async => stateRepo,
              ),
              cheerUpEventsRepositoryProvider.overrideWithValue(eventsRepo),
              // ADR-0011 §4: existing dispatch tests assert behaviour
              // BEFORE the v1.0 gate (default false). Flip ON for these.
              featureFlagsProvider.overrideWithValue(
                FeatureFlags.defaults().copyWith(
                  interventionDispatchEnabled: true,
                ),
              ),
            ],
            child: MaterialApp(
              theme: buildLightTheme(),
              home: const GardenScreen(),
            ),
          ),
        );

        for (var i = 0; i < 8; i += 1) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        expect(stateRepo.writeLastCalls, 0);
        expect(stateRepo.writeFirstIfNullCalls, 0);
        expect(eventsRepo.calls, isEmpty);
      },
    );
  });
}
