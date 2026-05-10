import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/domain/entities/plant_tier.dart';
import 'package:moodbloom/features/harvest/domain/entities/weekly_garden.dart';
import 'package:moodbloom/features/harvest/presentation/controllers/weekly_summary_controller.dart';
import 'package:moodbloom/features/harvest/presentation/weekly_summary_screen.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

/// Recording fake controller. Tests override
/// [weeklySummaryControllerProvider] with a constructor that returns
/// this Notifier so we can spy on `acknowledge` calls.
class _FakeWeeklySummaryController extends WeeklySummaryController {
  int acknowledgeCalls = 0;

  @override
  Future<WeeklyGarden?> acknowledge() async {
    acknowledgeCalls += 1;
    return null;
  }
}

const _summary = WeeklySummary(
  averageMoodScore: 0.32,
  moodCounts: {MoodType.happy: 4, MoodType.calm: 2, MoodType.sad: 1},
  endingPlantTier: PlantTier.thriving,
  totalEntryCount: 7,
  triggeredTierCount: 1,
);

Future<_FakeWeeklySummaryController> _pumpScreen(
  WidgetTester tester, {
  WeeklySummary summary = _summary,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1800));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final fake = _FakeWeeklySummaryController();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [weeklySummaryControllerProvider.overrideWith(() => fake)],
      child: MaterialApp(
        theme: buildLightTheme(),
        home: WeeklySummaryScreen(summary: summary),
      ),
    ),
  );
  return fake;
}

void main() {
  testWidgets('renders app-bar title "Your week"', (tester) async {
    await _pumpScreen(tester);
    expect(find.text('Your week'), findsOneWidget);
  });

  testWidgets('renders the locked harvest banner verbatim', (tester) async {
    await _pumpScreen(tester);
    expect(find.text(WeeklySummaryScreen.harvestBanner), findsOneWidget);
  });

  testWidgets('renders the average-mood section + value', (tester) async {
    await _pumpScreen(tester);
    expect(find.text('AVERAGE MOOD'), findsOneWidget);
    // Numeric label rendered with two decimals.
    expect(find.text('0.32'), findsOneWidget);
  });

  testWidgets('renders the dominant emotions section + chip labels', (
    tester,
  ) async {
    await _pumpScreen(tester);
    expect(find.text('DOMINANT EMOTIONS'), findsOneWidget);
    // Top-3 by count → happy(4), calm(2), sad(1).
    expect(find.textContaining('happy · 4'), findsOneWidget);
    expect(find.textContaining('calm · 2'), findsOneWidget);
    expect(find.textContaining('sad · 1'), findsOneWidget);
  });

  testWidgets('renders the pattern check-ins compassionate copy', (
    tester,
  ) async {
    await _pumpScreen(tester);
    expect(find.text('PATTERN CHECK-INS'), findsOneWidget);
    expect(find.textContaining('the engine paused with you'), findsOneWidget);
  });

  testWidgets('renders the Continue CTA + tap calls acknowledge()', (
    tester,
  ) async {
    final fake = await _pumpScreen(tester);

    final cta = find.text(WeeklySummaryScreen.continueLabel);
    expect(cta, findsOneWidget);

    await tester.tap(cta);
    await tester.pump();

    expect(fake.acknowledgeCalls, 1);
  });
}
