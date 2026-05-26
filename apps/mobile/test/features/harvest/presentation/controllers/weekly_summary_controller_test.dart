import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/domain/entities/plant_tier.dart';
import 'package:moodbloom/features/harvest/domain/entities/weekly_garden.dart';
import 'package:moodbloom/features/harvest/domain/harvest_failure.dart';
import 'package:moodbloom/features/harvest/presentation/controllers/weekly_summary_controller.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

/// Test seam: exposes the protected `state` setter so reset()'s
/// transitions can be exercised without driving a full acknowledge()
/// cycle (which would need user / entries / history / archive use-case
/// overrides just to land on Success).
class _StateSetter extends WeeklySummaryController {
  void forceState(HarvestArchiveStatus s) => state = s;
}

const _summary = WeeklySummary(
  averageMoodScore: 0.0,
  moodCounts: {MoodType.calm: 1},
  endingPlantTier: PlantTier.resting,
  totalEntryCount: 1,
  triggeredTierCount: 0,
);

final _garden = WeeklyGarden(
  weekId: '2026-W21',
  weekStart: DateTime.utc(2026, 5, 18),
  weekEnd: DateTime.utc(2026, 5, 25),
  entries: const [],
  healthHistory: const [],
  summary: _summary,
  archivedAt: DateTime.utc(2026, 5, 25, 0, 0, 1),
);

void main() {
  group('WeeklySummaryController.reset()', () {
    late ProviderContainer container;
    late _StateSetter controller;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          weeklySummaryControllerProvider.overrideWith(_StateSetter.new),
        ],
      );
      controller =
          container.read(weeklySummaryControllerProvider.notifier)
              as _StateSetter;
    });

    tearDown(() => container.dispose());

    test('clears HarvestArchiveSuccess back to idle', () {
      // The bug: a prior week's Success state was sticky across pushes,
      // making Continue a no-op on the next pending harvest because
      // acknowledge() short-circuits on terminal Success. reset() must
      // clear it.
      controller.forceState(HarvestArchiveSuccess(_garden));
      controller.reset();
      expect(
        container.read(weeklySummaryControllerProvider),
        isA<HarvestArchiveIdle>(),
      );
    });

    test('clears HarvestArchiveError back to idle', () {
      controller.forceState(
        const HarvestArchiveError(HarvestFailure.unknown('x')),
      );
      controller.reset();
      expect(
        container.read(weeklySummaryControllerProvider),
        isA<HarvestArchiveIdle>(),
      );
    });

    test('preserves HarvestArchiveRunning — must not drop in-flight write', () {
      controller.forceState(const HarvestArchiveRunning());
      controller.reset();
      expect(
        container.read(weeklySummaryControllerProvider),
        isA<HarvestArchiveRunning>(),
      );
    });

    test('is a no-op from HarvestArchiveIdle', () {
      controller.reset();
      expect(
        container.read(weeklySummaryControllerProvider),
        isA<HarvestArchiveIdle>(),
      );
    });
  });
}
