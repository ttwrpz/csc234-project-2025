import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/disclaimer/data/providers.dart';
import 'package:moodbloom/features/disclaimer/domain/disclaimer_copy.dart';
import 'package:moodbloom/features/disclaimer/domain/disclaimer_failure.dart';
import 'package:moodbloom/features/disclaimer/domain/repositories/disclaimer_repository.dart';
import 'package:moodbloom/features/insights/data/providers.dart';
import 'package:moodbloom/features/insights/domain/entities/daily_insight.dart';
import 'package:moodbloom/features/insights/domain/entities/insight_window.dart';
import 'package:moodbloom/features/insights/domain/repositories/insights_repository.dart';
import 'package:moodbloom/features/insights/domain/usecases/load_insights.dart';
import 'package:moodbloom/features/insights/presentation/screens/insights_screen.dart';
import 'package:moodbloom/features/insights/presentation/widgets/mood_score_chart.dart';

/// Fake disclaimer repo. Replays the latest emitted value on every new
/// listener so each `disclaimerAckStreamProvider` subscription sees the
/// current state (production behaves the same — a Firestore snapshot
/// stream emits the doc to every subscriber).
class _FakeDisclaimerRepo implements DisclaimerRepository {
  _FakeDisclaimerRepo({bool initial = false}) : _state = initial;

  bool _state;
  final List<String> ackedUsers = [];

  // Per-listener controllers. Keeping a list lets multiple consumers
  // (the gate provider + any nested watcher) each get the current
  // state immediately on subscription.
  final List<StreamController<bool>> _listeners = [];

  void emit(bool acked) {
    _state = acked;
    for (final c in List.of(_listeners)) {
      if (!c.isClosed) c.add(acked);
    }
  }

  @override
  Stream<bool> watchAckState({required String userId}) {
    late StreamController<bool> controller;
    controller = StreamController<bool>(
      onListen: () {
        _listeners.add(controller);
        // Replay the current state to the new listener.
        controller.add(_state);
      },
      onCancel: () {
        _listeners.remove(controller);
      },
    );
    return controller.stream;
  }

  @override
  Future<Result<void, DisclaimerFailure>> ack({required String userId}) async {
    ackedUsers.add(userId);
    emit(true);
    return const Ok(null);
  }
}

class _FakeInsightsRepo implements InsightsRepository {
  _FakeInsightsRepo(this.data);

  final List<DailyInsight> data;

  @override
  Stream<List<DailyInsight>> watchInsights({
    required String userId,
    required InsightWindow window,
  }) => Stream.value(data);
}

const _testUser = AppUser(
  uid: 'u-test',
  email: 't@example.com',
  displayName: 'Tester',
  photoUrl: null,
);

Future<void> _pump(
  WidgetTester tester, {
  required _FakeDisclaimerRepo disclaimerRepo,
  List<DailyInsight> insights = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        disclaimerRepositoryProvider.overrideWithValue(disclaimerRepo),
        currentUserStreamProvider.overrideWith((_) => Stream.value(_testUser)),
        insightsRepositoryProvider.overrideWithValue(
          _FakeInsightsRepo(insights),
        ),
        loadInsightsUseCaseProvider.overrideWithValue(
          LoadInsightsUseCase(repository: _FakeInsightsRepo(insights)),
        ),
      ],
      child: MaterialApp(
        theme: buildLightTheme(),
        home: const InsightsScreen(),
      ),
    ),
  );
}

void main() {
  group('InsightsScreen disclaimer gate (TC-36 / TC-37)', () {
    testWidgets('TC-36: not-yet-acked → dialog appears, chart hidden', (
      tester,
    ) async {
      final repo = _FakeDisclaimerRepo(initial: false);
      await _pump(tester, disclaimerRepo: repo);

      // Pump once to let the StreamProvider resolve, then again to
      // let the post-frame callback open the dialog.
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        find.text(DisclaimerCopy.full),
        findsOneWidget,
        reason: 'mandatory disclaimer must open on first view',
      );
      expect(
        find.byType(MoodScoreChart),
        findsNothing,
        reason: 'chart MUST be hidden until ack lands',
      );
    });

    testWidgets(
      'TC-36: tapping "I understand" calls ack and reveals the chart',
      (tester) async {
        final repo = _FakeDisclaimerRepo(initial: false);
        final today = DateTime.now();
        final insights = List<DailyInsight>.generate(
          14,
          (i) => DailyInsight(
            date: DateTime(today.year, today.month, today.day - 13 + i),
            avgMoodScore: i == 0 ? 0.3 : null,
            gardenHealthH: i == 0 ? 0.1 : null,
            dominantEmotion: null,
            entryCount: i == 0 ? 1 : 0,
            triggeredTier: null,
          ),
        );
        await _pump(tester, disclaimerRepo: repo, insights: insights);
        await tester.pump();
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text(DisclaimerCopy.ackButton), findsOneWidget);
        await tester.tap(find.text(DisclaimerCopy.ackButton));
        await tester.pumpAndSettle();

        expect(repo.ackedUsers, ['u-test']);
        expect(
          find.text(DisclaimerCopy.full),
          findsNothing,
          reason: 'dialog must pop after ack',
        );
        expect(
          find.byType(MoodScoreChart),
          findsOneWidget,
          reason: 'chart must render after ack landed via the stream',
        );
      },
    );

    testWidgets('TC-37: already-acked → no dialog, chart visible immediately', (
      tester,
    ) async {
      final repo = _FakeDisclaimerRepo(initial: true);
      final today = DateTime.now();
      final insights = List<DailyInsight>.generate(
        14,
        (i) => DailyInsight(
          date: DateTime(today.year, today.month, today.day - 13 + i),
          avgMoodScore: i == 13 ? 0.5 : null,
          gardenHealthH: i == 13 ? 0.2 : null,
          dominantEmotion: null,
          entryCount: i == 13 ? 1 : 0,
          triggeredTier: null,
        ),
      );
      await _pump(tester, disclaimerRepo: repo, insights: insights);
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        find.text(DisclaimerCopy.full),
        findsNothing,
        reason: 'pre-acked users must never see the dialog',
      );
      expect(repo.ackedUsers, isEmpty);
      expect(find.byType(MoodScoreChart), findsOneWidget);
    });

    testWidgets(
      'TC-36 invariant: chart never renders while ack stream emits false, '
      'even if controller has data',
      (tester) async {
        final repo = _FakeDisclaimerRepo(initial: false);
        final today = DateTime.now();
        // Provide data — the chart MUST still be hidden because the
        // gate dominates.
        final insights = [
          DailyInsight(
            date: today,
            avgMoodScore: 0.5,
            gardenHealthH: 0.3,
            dominantEmotion: null,
            entryCount: 1,
            triggeredTier: null,
          ),
        ];
        await _pump(tester, disclaimerRepo: repo, insights: insights);
        await tester.pump();
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.byType(MoodScoreChart), findsNothing);
      },
    );

    testWidgets('dialog is non-dismissible — tapping outside leaves it open', (
      tester,
    ) async {
      final repo = _FakeDisclaimerRepo(initial: false);
      await _pump(tester, disclaimerRepo: repo);
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      // Tap the top-left corner — well outside the modal body.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(
        find.text(DisclaimerCopy.full),
        findsOneWidget,
        reason: 'barrier-tap must not dismiss the mandatory ack dialog',
      );
      expect(repo.ackedUsers, isEmpty);
    });
  });
}
