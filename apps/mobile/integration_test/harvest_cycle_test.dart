import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moodbloom/features/garden/domain/entities/plant_tier.dart';
import 'package:moodbloom/features/harvest/domain/entities/weekly_garden.dart';
import 'package:moodbloom/features/harvest/domain/harvest_failure.dart';
import 'package:moodbloom/features/harvest/domain/repositories/harvest_repository.dart';
import 'package:moodbloom/features/harvest/domain/usecases/archive_weekly_garden.dart';
import 'package:moodbloom/features/harvest/domain/usecases/compute_weekly_summary.dart';
import 'package:moodbloom/features/harvest/presentation/weekly_summary_screen.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

/// Recording fake [HarvestRepository]. Captures every [archive] call so
/// the test can assert that the harvest cycle reached the persistence
/// boundary, and with what payload — the weekId + entry count + summary
/// stats are all visible on the captured [WeeklyGarden].
class _RecordingHarvestRepository implements HarvestRepository {
  final List<WeeklyGarden> archiveCalls = <WeeklyGarden>[];

  @override
  Future<Result<WeeklyGarden, HarvestFailure>> archive({
    required String userId,
    required WeeklyGarden garden,
  }) async {
    archiveCalls.add(garden);
    return Ok(garden);
  }

  @override
  Stream<List<WeeklyGarden>> watchHistory({required String userId}) =>
      const Stream<List<WeeklyGarden>>.empty();

  @override
  Future<Result<WeeklyGarden, HarvestFailure>> getByWeekId({
    required String userId,
    required String weekId,
  }) async {
    return const Err(HarvestFailure.unknown('not-implemented-by-fake'));
  }
}

/// Seven-day mood entry seed for the harvest flow.
List<MoodEntry> _sevenDaysFor(String uid, DateTime weekStart) {
  return <MoodEntry>[
    MoodEntry(
      id: 'h-1',
      userId: uid,
      mood: MoodType.happy,
      intensity: 4,
      text: '',
      createdAt: weekStart,
    ),
    MoodEntry(
      id: 'h-2',
      userId: uid,
      mood: MoodType.calm,
      intensity: 3,
      text: '',
      createdAt: weekStart.add(const Duration(days: 1)),
    ),
    MoodEntry(
      id: 'h-3',
      userId: uid,
      mood: MoodType.sad,
      intensity: 2,
      text: '',
      createdAt: weekStart.add(const Duration(days: 2)),
    ),
    MoodEntry(
      id: 'h-4',
      userId: uid,
      mood: MoodType.okay,
      intensity: 3,
      text: '',
      createdAt: weekStart.add(const Duration(days: 3)),
    ),
    MoodEntry(
      id: 'h-5',
      userId: uid,
      mood: MoodType.happy,
      intensity: 3,
      text: '',
      createdAt: weekStart.add(const Duration(days: 4)),
    ),
    MoodEntry(
      id: 'h-6',
      userId: uid,
      mood: MoodType.calm,
      intensity: 4,
      text: '',
      createdAt: weekStart.add(const Duration(days: 5)),
    ),
    MoodEntry(
      id: 'h-7',
      userId: uid,
      mood: MoodType.happy,
      intensity: 5,
      text: '',
      createdAt: weekStart.add(const Duration(days: 6)),
    ),
  ];
}

/// WBS 8.3 Test 4 — Weekly Harvest cycle (TC-15 + TC-23 + CLAUDE.md copy).
///
/// The harvest screen is the only place where a week is "completed" and
/// moved into history. This test verifies three contracts:
///
///   1. **Banner copy is compassionate.** The locked
///      `WeeklySummaryScreen.harvestBanner` constant uses the ecosystem
///      vocabulary ("harvested", "new week", "fresh canvas") and contains
///      NONE of the forbidden words ("delete", "clear", "reset", "lost",
///      "destroyed", "wilted", "dead", "dying"). The constant is the
///      single source of truth — a regression that swaps "harvested" for
///      "deleted" gets caught here even if the screen still renders.
///
///   2. **The real archive use case persists a WeeklyGarden.** Calling
///      [ArchiveWeeklyGardenUseCase] with seeded entries against a
///      recording [HarvestRepository] verifies the round-trip through
///      the production logic: weekId derivation, summary computation,
///      and the additive write.
///
///   3. **Archive entries are immutable.** Once written, the
///      [WeeklyGarden.entries] list is constructed via
///      `List.unmodifiable`. A mutation attempt throws. This is the
///      "history is a record, not a redo" contract from CLAUDE.md
///      "Firestore data model" §`weeklyGardens`.
///
/// The router-driven flow (GardenScreen detects pending → pushes
/// WeeklySummaryScreen via MaterialPageRoute → user taps Continue →
/// controller invokes the use case) is exercised by
/// `weekly_summary_screen_test.dart` at the widget level. This
/// integration test re-asserts the same contract at the use-case
/// boundary against a recording repo — the missing link between the
/// widget-level acknowledge() and the data-layer persist write.
///
/// Domain purity: tests-only file; touches no production code.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Weekly Harvest cycle (WBS 8.3 — Test 4)', () {
    late _RecordingHarvestRepository harvestRepo;
    late DateTime weekStart;
    late List<MoodEntry> weekEntries;

    setUp(() {
      // Anchor the week start to a known Monday so the weekId is
      // deterministic. 2026-05-04 is a Monday (ISO week 2026-W19).
      weekStart = DateTime(2026, 5, 4);
      weekEntries = _sevenDaysFor('u-harvest', weekStart);
      harvestRepo = _RecordingHarvestRepository();
    });

    testWidgets(
      'banner copy is compassionate — no forbidden vocabulary in rendered text',
      (tester) async {
        const summary = WeeklySummary(
          averageMoodScore: 0.24,
          moodCounts: {MoodType.happy: 3, MoodType.calm: 2, MoodType.okay: 1},
          endingPlantTier: PlantTier.thriving,
          totalEntryCount: 6,
          triggeredTierCount: 0,
        );

        await tester.binding.setSurfaceSize(const Size(800, 1800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: WeeklySummaryScreen(summary: summary)),
          ),
        );
        await tester.pumpAndSettle();

        // Locked banner phrase renders verbatim.
        expect(
          find.text(WeeklySummaryScreen.harvestBanner),
          findsOneWidget,
          reason:
              'WeeklySummaryScreen.harvestBanner must render verbatim — '
              'the constant is the single source of truth (CLAUDE.md '
              "Pre-approved intervention phrasing § 'Weekly harvest banner')",
        );

        // The locked string itself must obey the copy rules. A
        // regression that swaps "harvested" for "deleted" or "lost"
        // gets caught here even if the constant still compiles.
        const banner = WeeklySummaryScreen.harvestBanner;
        const forbidden = <String>[
          'delete',
          'clear',
          'reset',
          'lost',
          'destroyed',
          'wilted',
          'wilting',
          'dead',
          'dying',
        ];
        for (final word in forbidden) {
          expect(
            banner.toLowerCase().contains(word),
            isFalse,
            reason:
                'CLAUDE.md "Copy rules" forbids "$word" in garden copy. '
                'The harvest banner must use ecosystem vocabulary only.',
          );
        }

        // The compassionate vocabulary IS present.
        expect(
          banner.toLowerCase(),
          contains('harvested'),
          reason: 'harvest banner must use "harvested" — the canonical word',
        );
        expect(
          banner.toLowerCase(),
          contains('new week'),
          reason:
              'harvest banner must signal "new week" — fresh canvas framing',
        );
        expect(
          banner.toLowerCase(),
          contains('fresh canvas'),
          reason:
              'harvest banner must use "fresh canvas" — narrative '
              'externalization (CLAUDE.md "Compassionate imperatives")',
        );

        // Continue CTA label is also locked.
        expect(
          find.text(WeeklySummaryScreen.continueLabel),
          findsOneWidget,
          reason: 'the Continue CTA label must render verbatim',
        );
        const cta = WeeklySummaryScreen.continueLabel;
        for (final word in forbidden) {
          expect(
            cta.toLowerCase().contains(word),
            isFalse,
            reason: 'continue CTA must avoid "$word"',
          );
        }
      },
    );

    test('real ArchiveWeeklyGardenUseCase persists a WeeklyGarden — '
        'weekId is YYYY-Www, payload carries all 7 seeded entries', () async {
      // The router-driven flow ends here: the controller's
      // acknowledge() invokes this very use case after building the
      // WeeklyGarden. Test the use case directly so we observe the
      // weekId derivation + the additive write reaching the
      // (recording) repository.
      final useCase = ArchiveWeeklyGardenUseCase(
        repository: harvestRepo,
        computeSummary: const ComputeWeeklySummaryUseCase(),
      );

      final result = await useCase(
        userId: 'u-harvest',
        weekStart: weekStart,
        now: weekStart.add(const Duration(days: 8)),
        weekEntries: weekEntries,
        dailyHealthHistory: const [0.0, 0.1, 0.05, -0.1, 0.0, 0.05, 0.1],
      );

      // Hard assertion 1: the use case succeeded.
      expect(
        result,
        isA<Ok<WeeklyGarden, HarvestFailure>>(),
        reason:
            'archive must succeed for a populated week — only empty '
            'weeks return Err(noEntries)',
      );

      // Hard assertion 2: exactly one archive call reached the repo.
      expect(
        harvestRepo.archiveCalls,
        hasLength(1),
        reason:
            'the archive use case must reach HarvestRepository.archive '
            'exactly once per call',
      );

      final archived = harvestRepo.archiveCalls.single;

      // Hard assertion 3: weekId is `YYYY-Www`. The Firestore rule
      // pins doc id to this format; the use case's `formatWeekId`
      // is the canonical helper. We assert both the regex shape AND
      // exact-match against the helper so a derivation drift gets
      // caught.
      expect(
        archived.weekId,
        matches(RegExp(r'^\d{4}-W\d{2}$')),
        reason:
            'archived WeeklyGarden.weekId must follow "YYYY-Www" — '
            'the Firestore rule pins doc id to this format',
      );
      expect(
        archived.weekId,
        equals(ArchiveWeeklyGardenUseCase.formatWeekId(weekStart)),
        reason:
            'the archived weekId must match the use case helper for '
            'the seeded weekStart — guards against drift between the '
            'controller-side and use-case-side derivation',
      );

      // Hard assertion 4: the archive payload carries the 7
      // entries verbatim. The use case threads `weekEntries`
      // straight through; a regression that drops or duplicates
      // entries gets caught.
      expect(
        archived.entries,
        hasLength(7),
        reason:
            'the archived WeeklyGarden must carry all 7 seeded entries — '
            'weekly harvest is purely additive',
      );
      expect(
        archived.weekStart,
        equals(weekStart),
        reason: 'weekStart must round-trip through the use case verbatim',
      );
      expect(
        archived.weekEnd,
        equals(weekStart.add(const Duration(days: 7))),
        reason: 'weekEnd is exactly weekStart + 7 days',
      );

      // Hard assertion 5: the summary was computed by the real
      // use case. averageMoodScore must be in [-1, +1] and reflect
      // the seeded mix.
      expect(
        archived.summary.averageMoodScore,
        inInclusiveRange(-1.0, 1.0),
        reason: 'averageMoodScore is bounded by the mood-score formula',
      );
      // The seeded week has 5 positive + 2 mildly-negative entries
      // so the average is positive. Pinning the sign is enough to
      // catch a regression that inverts the formula.
      expect(
        archived.summary.averageMoodScore,
        greaterThan(0.0),
        reason:
            'seeded week is net positive (5 happy/calm + okay + 1 sad); '
            'average must be > 0',
      );
      expect(
        archived.summary.totalEntryCount,
        equals(7),
        reason: 'totalEntryCount must equal the seeded entry count',
      );
    });

    test('WeeklyGarden entries + healthHistory are immutable post-archive '
        '(TC-23 — history is a record, not a redo)', () async {
      // The brief asks: "Verify past entries remain readable in
      // History." History is a stream of [WeeklyGarden] docs from
      // the repo. The audit-trail invariant is that those docs are
      // FROZEN once written — both at the entity level
      // (List.unmodifiable) and at the Firestore-rules level
      // (write-once-on-archive per ADR-0010 §6).
      //
      // This test exercises the entity-level invariant. The rules-
      // level invariant is covered by the security-reviewer's
      // emulator test (out of scope for the QA integration suite).
      final useCase = ArchiveWeeklyGardenUseCase(
        repository: harvestRepo,
        computeSummary: const ComputeWeeklySummaryUseCase(),
      );

      final result = await useCase(
        userId: 'u-harvest',
        weekStart: weekStart,
        now: weekStart.add(const Duration(days: 8)),
        weekEntries: weekEntries,
        dailyHealthHistory: const [0.0, 0.1, 0.05, -0.1, 0.0, 0.05, 0.1],
      );

      final garden = (result as Ok<WeeklyGarden, HarvestFailure>).value;

      // WeeklyGarden.entries is built via List.unmodifiable —
      // mutation attempt must throw.
      expect(
        () => garden.entries.add(weekEntries.first),
        throwsUnsupportedError,
        reason:
            'WeeklyGarden.entries must be unmodifiable so once a week '
            'is archived its mood log cannot be retroactively edited '
            '(write-once-on-archive per ADR-0010 §6)',
      );
      expect(
        () => garden.healthHistory.add(0.5),
        throwsUnsupportedError,
        reason:
            'WeeklyGarden.healthHistory must be unmodifiable — same '
            'write-once contract as entries',
      );

      // The repository saw exactly one archive call — defensive
      // double-write would surface here too.
      expect(
        harvestRepo.archiveCalls,
        hasLength(1),
        reason: 'the additive archive must reach the repo exactly once',
      );
    });
  });
}
