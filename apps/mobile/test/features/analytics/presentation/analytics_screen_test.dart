import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/app/feature_flags.dart';
import 'package:moodbloom/app/providers.dart';
import 'package:moodbloom/features/analytics/presentation/analytics_screen.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/disclaimer/data/providers.dart';
import 'package:moodbloom/features/disclaimer/domain/disclaimer_failure.dart';
import 'package:moodbloom/features/disclaimer/domain/repositories/disclaimer_repository.dart';
import 'package:moodbloom/features/insights/data/providers.dart';
import 'package:moodbloom/features/insights/domain/entities/daily_insight.dart';
import 'package:moodbloom/features/insights/domain/entities/insight_window.dart';
import 'package:moodbloom/features/insights/domain/repositories/insights_repository.dart';

/// Tests for the v1.5.1 merged Patterns screen.
///
/// The former `/analytics` + `/analytics/insights` split is now one
/// surface. These tests pin down the only behaviour that's actually new:
///
///   1. Pre-ack — the inline disclaimer banner renders and the
///      "Pattern check-ins" tier-marker section is hidden.
///   2. Post-ack — the disclaimer banner disappears and the
///      "Pattern check-ins" section renders.
///
/// Existing widget-level tests in `test/features/insights/` cover the
/// individual cards (chart, marker band, recent triggers, legend, guide).

class _StaticFlagSource implements FeatureFlagSource {
  @override
  bool getBool(String key) => false; // Hide AI card so the test rig stays small.
}

class _FakeDisclaimerRepo implements DisclaimerRepository {
  _FakeDisclaimerRepo(this._acked);
  final bool _acked;

  @override
  Stream<bool> watchAckState({required String userId}) =>
      Stream<bool>.value(_acked);

  @override
  Future<Result<void, DisclaimerFailure>> ack({required String userId}) async =>
      const Ok(null);
}

class _FakeInsightsRepo implements InsightsRepository {
  _FakeInsightsRepo(this.insights);
  final List<DailyInsight> insights;

  @override
  Stream<List<DailyInsight>> watchInsights({
    required String userId,
    required InsightWindow window,
  }) => Stream<List<DailyInsight>>.value(insights);
}

const _user = AppUser(
  uid: 'u-1',
  displayName: 'Tester',
  email: 'tester@example.com',
  emailVerified: true,
);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required bool acked,
  List<DailyInsight> insights = const [],
}) async {
  await tester.binding.setSurfaceSize(const Size(420, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        featureFlagSourceProvider.overrideWithValue(_StaticFlagSource()),
        currentUserStreamProvider.overrideWith((_) => Stream.value(_user)),
        disclaimerRepositoryProvider.overrideWithValue(
          _FakeDisclaimerRepo(acked),
        ),
        insightsRepositoryProvider.overrideWithValue(
          _FakeInsightsRepo(insights),
        ),
      ],
      child: MaterialApp(
        theme: buildLightTheme(),
        home: const AnalyticsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the Fraunces "Patterns" header in every state', (
    tester,
  ) async {
    await _pumpScreen(tester, acked: false);
    expect(find.text('Patterns'), findsOneWidget);
  });

  testWidgets(
    'pre-ack: shows the inline disclaimer banner; hides Pattern check-ins',
    (tester) async {
      await _pumpScreen(tester, acked: false);

      // Banner title is present.
      expect(find.text('Unlock pattern check-ins'), findsOneWidget);
      // Diagnostic-looking tier section is gated off.
      expect(find.text('PATTERN CHECK-INS'), findsNothing);
    },
  );

  testWidgets(
    'post-ack: hides the disclaimer banner and renders Pattern check-ins '
    'when insights have entries',
    (tester) async {
      final today = DateTime(2026, 5, 20);
      final insights = [
        DailyInsight(
          date: today.subtract(const Duration(days: 1)),
          avgMoodScore: -0.3,
          gardenHealthH: -0.1,
          dominantEmotion: null,
          entryCount: 1,
          triggeredTier: null,
          triggerReasonKey: null,
        ),
        DailyInsight(
          date: today,
          avgMoodScore: 0.4,
          gardenHealthH: 0.2,
          dominantEmotion: null,
          entryCount: 2,
          triggeredTier: null,
          triggerReasonKey: null,
        ),
      ];

      await _pumpScreen(tester, acked: true, insights: insights);

      // Banner is gone post-ack.
      expect(find.text('Unlock pattern check-ins'), findsNothing);
      // Pattern check-ins section appears.
      expect(find.text('PATTERN CHECK-INS'), findsOneWidget);
    },
  );

  testWidgets('window chips are 7d / 14d / 30d', (tester) async {
    await _pumpScreen(tester, acked: false);
    // v1.6 locked the picker to 7d / 14d / 30d (the prototype's middle
    // tab is 14d / fortnight). The 90d / quarter preset was dropped.
    expect(find.text('7d'), findsOneWidget);
    expect(find.text('14d'), findsOneWidget);
    expect(find.text('30d'), findsOneWidget);
    expect(find.text('90d'), findsNothing);
  });
}
