import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/harvest/domain/entities/weekly_garden.dart';
import 'package:moodbloom/features/harvest/domain/harvest_failure.dart';
import 'package:moodbloom/features/harvest/domain/repositories/harvest_repository.dart';
import 'package:moodbloom/features/harvest/domain/usecases/archive_weekly_garden.dart';
import 'package:moodbloom/features/harvest/domain/usecases/compute_weekly_summary.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

/// Recording fake of [HarvestRepository]. Captures every archive call
/// so the use case's userId + garden semantics can be asserted in
/// isolation from Firestore. `getByWeekId` returns whatever was last
/// archived under that weekId (TC-13: "entries preserved post-archive").
class _FakeHarvestRepository implements HarvestRepository {
  final List<({String userId, WeeklyGarden garden})> archives = [];

  /// When non-null, the next call to [archive] returns this Err
  /// instead of taking the happy path. Cleared after consumption.
  HarvestFailure? failNext;

  @override
  Future<Result<WeeklyGarden, HarvestFailure>> archive({
    required String userId,
    required WeeklyGarden garden,
  }) async {
    final f = failNext;
    if (f != null) {
      failNext = null;
      return Err(f);
    }
    archives.add((userId: userId, garden: garden));
    return Ok(garden);
  }

  @override
  Stream<List<WeeklyGarden>> watchHistory({required String userId}) {
    return Stream.value(
      archives.where((c) => c.userId == userId).map((c) => c.garden).toList(),
    );
  }

  @override
  Future<Result<WeeklyGarden, HarvestFailure>> getByWeekId({
    required String userId,
    required String weekId,
  }) async {
    for (final c in archives) {
      if (c.userId == userId && c.garden.weekId == weekId) return Ok(c.garden);
    }
    return Err(HarvestFailure.unknown('not-found:$weekId'));
  }
}

MoodEntry _entry({
  required DateTime createdAt,
  required MoodType mood,
  int intensity = 5,
  String id = 'e1',
}) => MoodEntry(
  id: id,
  userId: 'uid-1',
  mood: mood,
  intensity: intensity,
  text: '',
  createdAt: createdAt,
);

void main() {
  group('ArchiveWeeklyGardenUseCase — happy path', () {
    test('TC-11: archive returns the persisted WeeklyGarden + repository was '
        'called once with the same userId', () async {
      final repo = _FakeHarvestRepository();
      final useCase = ArchiveWeeklyGardenUseCase(
        repository: repo,
        computeSummary: const ComputeWeeklySummaryUseCase(),
      );

      // Mon 2026-05-04 → Sun 2026-05-10 (ISO 2026-W19).
      final weekStart = DateTime(2026, 5, 4);
      final now = DateTime(2026, 5, 11, 0, 0, 1);
      final weekEntries = [
        _entry(
          createdAt: DateTime(2026, 5, 6, 9),
          mood: MoodType.happy,
          id: 'a',
        ),
        _entry(
          createdAt: DateTime(2026, 5, 8, 9),
          mood: MoodType.calm,
          id: 'b',
        ),
      ];

      final outcome = await useCase(
        userId: 'uid-1',
        weekStart: weekStart,
        now: now,
        weekEntries: weekEntries,
        dailyHealthHistory: const [0.0, 0.12, 0.20, 0.18, 0.25, 0.30, 0.35],
      );

      expect(outcome, isA<Ok<WeeklyGarden, HarvestFailure>>());
      expect(repo.archives, hasLength(1));
      expect(repo.archives.single.userId, 'uid-1');
      expect(repo.archives.single.garden.weekId, '2026-W19');
      expect(repo.archives.single.garden.weekStart, weekStart);
      expect(
        repo.archives.single.garden.weekEnd,
        weekStart.add(const Duration(days: 7)),
      );
      expect(repo.archives.single.garden.archivedAt, now);
      expect(repo.archives.single.garden.entries, weekEntries);
    });

    test(
      'TC-14: summary stats are computed and written into the persisted doc',
      () async {
        final repo = _FakeHarvestRepository();
        final useCase = ArchiveWeeklyGardenUseCase(
          repository: repo,
          computeSummary: const ComputeWeeklySummaryUseCase(),
        );

        final weekStart = DateTime(2026, 5, 4);
        final entries = [
          _entry(
            createdAt: DateTime(2026, 5, 5, 9),
            mood: MoodType.happy,
            id: 'a',
          ),
          _entry(
            createdAt: DateTime(2026, 5, 6, 9),
            mood: MoodType.happy,
            id: 'b',
          ),
          _entry(
            createdAt: DateTime(2026, 5, 7, 9),
            mood: MoodType.sad,
            id: 'c',
          ),
        ];
        await useCase(
          userId: 'uid-1',
          weekStart: weekStart,
          now: DateTime(2026, 5, 11),
          weekEntries: entries,
          dailyHealthHistory: const [0.1, 0.2, 0.3, 0.25, 0.22, 0.20, 0.18],
          triggeredTierCount: 2,
        );

        final summary = repo.archives.single.garden.summary;
        expect(summary.totalEntryCount, 3);
        expect(summary.moodCounts[MoodType.happy], 2);
        expect(summary.moodCounts[MoodType.sad], 1);
        // 1.0 + 1.0 + (-1.0) all at intensity 5 → average 0.333…
        expect(summary.averageMoodScore, closeTo(0.333, 0.01));
        expect(summary.triggeredTierCount, 2);
      },
    );

    test('TC-13: entries preserved post-archive — getByWeekId returns the same '
        'list the use case wrote', () async {
      final repo = _FakeHarvestRepository();
      final useCase = ArchiveWeeklyGardenUseCase(
        repository: repo,
        computeSummary: const ComputeWeeklySummaryUseCase(),
      );
      final weekStart = DateTime(2026, 5, 4);
      final entries = [
        _entry(
          createdAt: DateTime(2026, 5, 6, 9),
          mood: MoodType.happy,
          id: 'a',
        ),
        _entry(
          createdAt: DateTime(2026, 5, 8, 9),
          mood: MoodType.calm,
          id: 'b',
        ),
      ];
      await useCase(
        userId: 'uid-1',
        weekStart: weekStart,
        now: DateTime(2026, 5, 11),
        weekEntries: entries,
        dailyHealthHistory: const [0.1, 0.2],
      );

      final read = await repo.getByWeekId(userId: 'uid-1', weekId: '2026-W19');
      expect(read, isA<Ok<WeeklyGarden, HarvestFailure>>());
      read.fold(
        ok: (g) => expect(g.entries, entries),
        err: (_) => fail('expected Ok'),
      );
    });
  });

  group('ArchiveWeeklyGardenUseCase — error paths', () {
    test(
      'empty week returns Err(noEntries) and never calls the repo',
      () async {
        final repo = _FakeHarvestRepository();
        final useCase = ArchiveWeeklyGardenUseCase(
          repository: repo,
          computeSummary: const ComputeWeeklySummaryUseCase(),
        );

        final outcome = await useCase(
          userId: 'uid-1',
          weekStart: DateTime(2026, 5, 4),
          now: DateTime(2026, 5, 11),
          weekEntries: const [],
          dailyHealthHistory: const [],
        );
        expect(outcome, isA<Err<WeeklyGarden, HarvestFailure>>());
        outcome.fold(
          ok: (_) => fail('expected Err'),
          err: (f) => expect(f.runtimeType.toString(), contains('NoEntries')),
        );
        expect(repo.archives, isEmpty);
      },
    );

    test('alreadyArchived collision is forwarded as Err', () async {
      final repo = _FakeHarvestRepository()
        ..failNext = const HarvestFailure.alreadyArchived('2026-W19');
      final useCase = ArchiveWeeklyGardenUseCase(
        repository: repo,
        computeSummary: const ComputeWeeklySummaryUseCase(),
      );
      final outcome = await useCase(
        userId: 'uid-1',
        weekStart: DateTime(2026, 5, 4),
        now: DateTime(2026, 5, 11),
        weekEntries: [
          _entry(createdAt: DateTime(2026, 5, 6), mood: MoodType.happy),
        ],
        dailyHealthHistory: const [0.1],
      );
      expect(outcome, isA<Err<WeeklyGarden, HarvestFailure>>());
      outcome.fold(
        ok: (_) => fail('expected Err'),
        err: (f) =>
            expect(f.runtimeType.toString(), contains('AlreadyArchived')),
      );
    });
  });

  group('formatWeekId — ISO 8601 semantics', () {
    test('ordinary mid-year week → YYYY-Www padded', () {
      // Mon 2026-05-04 is in ISO week 19 of 2026.
      expect(
        ArchiveWeeklyGardenUseCase.formatWeekId(DateTime(2026, 5, 4)),
        '2026-W19',
      );
    });

    test('first week of year (2026-01-04 is Sunday → ISO 2026-W01)', () {
      // 2026-01-01 (Thu) → week 1; 2026-01-04 (Sun) → still week 1.
      expect(
        ArchiveWeeklyGardenUseCase.formatWeekId(DateTime(2026, 1, 4)),
        '2026-W01',
      );
    });

    test('year-boundary case: 2027-01-01 (Fri) is in ISO 2026-W53', () {
      // 2027-01-01 is a Friday; the Thursday of that ISO week is
      // 2026-12-31, which lands in 2026 week 53.
      expect(
        ArchiveWeeklyGardenUseCase.formatWeekId(DateTime(2027, 1, 1)),
        '2026-W53',
      );
    });
  });
}
