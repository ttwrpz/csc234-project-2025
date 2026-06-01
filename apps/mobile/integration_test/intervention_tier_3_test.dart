import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/disclaimer/domain/disclaimer_copy.dart';
import 'package:moodbloom/features/garden/data/providers.dart'
    show interventionStateRepositoryProvider;
import 'package:moodbloom/features/intervention/data/providers.dart';
import 'package:moodbloom/features/intervention/data/quote_library_impl.dart';
import 'package:moodbloom/features/intervention/data/quote_safety_filter_impl.dart';
import 'package:moodbloom/features/intervention/domain/entities/ai_allowed_tier.dart';
import 'package:moodbloom/features/intervention/domain/entities/quote.dart';
import 'package:moodbloom/features/intervention/domain/entities/quote_failure.dart';
import 'package:moodbloom/features/intervention/presentation/controllers/intervention_controller.dart';
import 'package:moodbloom/features/intervention/presentation/screens/crisis_resources_screen.dart';
import 'package:moodbloom/features/intervention/presentation/widgets/intervention_banner.dart';
import 'package:moodbloom/features/mood/data/providers.dart';
import 'package:moodbloom/features/notifications/data/providers.dart';
import 'package:moodbloom/features/pattern_engine/data/providers.dart';
import 'package:moodbloom/features/pattern_engine/domain/entities/pattern_result.dart';
import 'package:moodbloom/features/pattern_engine/domain/entities/tier.dart';
import 'package:moodbloom/features/pattern_engine/domain/pattern_failure.dart';
import 'package:moodbloom/features/pattern_engine/domain/repositories/pattern_repository.dart';

import 'app_harness.dart';
import 'fakes.dart';
import 'intervention_fakes.dart';

/// WBS 8.3 Test 6 - Tier 3 end-to-end (TC-40 + TC-41 + TC-33 + TC-38).
///
/// **This is the highest-stakes test in the project.** ADR-0012 commits
/// the team to a structural guarantee: Tier 3 dispatches NEVER call
/// `AIQuoteRepository.requestSuggestion` and NEVER traverse the
/// `QuoteSafetyFilter`. The unit test at
/// `apps/mobile/test/features/intervention/domain/services/
/// tiered_intervention_dispatcher_test.dart` covers the dispatcher in
/// isolation; this integration test re-asserts the SAME invariant at
/// the integration boundary - pumping the full app, letting the
/// production controller dispatch through the production dispatcher
/// against a recording fake AI repository.
///
/// **Hard assertion (TC-40):** after a Tier 3 emission settles, the
/// recording [RecordingAIQuoteRepository.calls] list MUST be empty.
/// A future refactor that routes Tier 3 through Gemini (intentionally
/// or accidentally) fails this assertion in CI on the same PR.
///
/// **TC-41 sub-flow:** feeds 30 off-script / forbidden / over-length
/// inputs through the production [QuoteSafetyFilterImpl] inside the
/// running app's `ProviderContainer`. The unit test in
/// `quote_safety_filter_impl_test.dart` covers the canonical 55
/// inputs; this integration re-assertion exercises a 30-input subset
/// to confirm the filter is wired correctly from the app side.
///
/// Domain purity: tests-only file; touches no production code.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Intervention Tier 3 - TC-40 end-to-end (WBS 8.3 - Test 6)', () {
    late IntegrationAuthRepository authRepo;
    late IntegrationMoodRepository moodRepo;
    late _ControllablePatternRepository patternRepo;
    late RecordingAIQuoteRepository aiRepo;
    late FakeInterventionRepository interventionRepo;
    late FakeInterventionStateRepository stateRepo;
    late FakeFcmTokenRepository fcmRepo;

    setUp(() async {
      seedOnboardingComplete();
      authRepo = IntegrationAuthRepository(
        initialUser: const AppUser(uid: 'u-tier3', email: 'tier3@x.com'),
      );
      moodRepo = IntegrationMoodRepository();
      patternRepo = _ControllablePatternRepository();
      aiRepo = RecordingAIQuoteRepository();
      interventionRepo = FakeInterventionRepository();
      stateRepo = FakeInterventionStateRepository();
      fcmRepo = FakeFcmTokenRepository(allTiersOnSettings());
    });

    tearDown(() async {
      await authRepo.dispose();
      await moodRepo.dispose();
      await patternRepo.dispose();
    });

    Future<void> pump(WidgetTester tester) async {
      final defaults = await defaultIntegrationOverrides();
      addTearDown(() async => defaults.syncManager.dispose());

      await pumpHarness(
        tester,
        overrides: [
          ...defaults.overrides,
          authRepositoryProvider.overrideWithValue(authRepo),
          moodRepositoryProvider.overrideWithValue(moodRepo),
          patternRepositoryProvider.overrideWithValue(patternRepo),
          // Critical: the RecordingAIQuoteRepository's `.calls` list
          // is the load-bearing assertion in TC-40. Wiring the SAME
          // fake into the production aiQuoteRepositoryProvider so the
          // production dispatcher reaches THIS instance (and only
          // this instance) on every dispatch.
          aiQuoteRepositoryProvider.overrideWithValue(aiRepo),
          interventionRepositoryProvider.overrideWithValue(interventionRepo),
          interventionStateRepositoryProvider.overrideWith(
            (_) async => stateRepo,
          ),
          fcmTokenRepositoryProvider.overrideWithValue(fcmRepo),
          notificationsPreferenceDatasourceProvider.overrideWithValue(null),
        ],
      );

      // Settle the FutureProvider for the state repo + the initial
      // pattern stream attach.
      for (var i = 0; i < 6; i += 1) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    Future<void> emitTier3AndSettle(WidgetTester tester) async {
      patternRepo.emit(_patternForTier3());
      for (var i = 0; i < 16; i += 1) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    testWidgets(
      'TC-40 - Tier 3 dispatch NEVER calls AIQuoteRepository.requestSuggestion '
      '(the hard assertion, ADR-0012 §"Decision" point 3)',
      (tester) async {
        await pump(tester);
        await emitTier3AndSettle(tester);

        // The banner is mounted - the controller successfully
        // dispatched Tier 3.
        expect(
          find.byType(InterventionBanner),
          findsOneWidget,
          reason:
              'Tier 3 emission must surface the InterventionBanner - '
              'the dispatcher takes the curated branch and the controller '
              'transitions to InterventionPending',
        );

        // ────────────────────────────────────────────────────────
        // THE HARD ASSERTION - TC-40 + ADR-0012 §"Decision" point 3.
        // ────────────────────────────────────────────────────────
        expect(
          aiRepo.calls,
          isEmpty,
          reason:
              'ADR-0012 §"Decision" point 1: Tier 3 must NEVER invoke '
              'AIQuoteRepository.requestSuggestion. Real-world harm at '
              "the user's most vulnerable moment is structurally "
              'impossible - not "very unlikely", not "tested", but '
              'unreachable in the call graph. A future refactor that '
              'routes Tier 3 through Gemini (intentionally or accidentally) '
              'fails THIS assertion on the same PR.',
        );

        // Read the dispatch off the controller and assert the body
        // contents match the curated Tier 3 pool byte-for-byte.
        final element = tester.element(find.byType(InterventionBanner));
        final container = ProviderScope.containerOf(element);
        final controllerState = container.read(interventionControllerProvider);
        expect(
          controllerState,
          isA<InterventionPending>(),
          reason: 'Tier 3 emission must leave the controller in Pending',
        );
        final pending = controllerState as InterventionPending;
        final body = pending.dispatch.body;

        // The body contains one of the 8 curated Tier 3 phrases
        // verbatim. The pool is the only place curated text lives;
        // a regression that hand-rolls a different phrase fails here.
        expect(
          QuoteLibraryImpl.tier3Pool.any((phrase) => body.contains(phrase)),
          isTrue,
          reason:
              'Tier 3 dispatch body must contain one of the 8 '
              'team-reviewed curated phrases from QuoteLibraryImpl.tier3Pool '
              '- HB-008 + ADR-0012 §"Decision" point 5 (curated pool '
              'reviewed aloud)',
        );

        // TC-33: Hotline 1323 must appear in every Tier 3 body.
        expect(
          body,
          contains('Hotline 1323'),
          reason:
              'TC-33: every Tier 3 dispatch body must reference '
              '"Hotline 1323" - the canonical Thai mental-health line. '
              'CLAUDE.md "Hotline 1323 footer appears on Tier 3 only"',
        );

        // TC-38: the disclaimer footer must be the body suffix.
        expect(
          body.endsWith(DisclaimerCopy.notificationFooter),
          isTrue,
          reason:
              'TC-38: every Tier 1/2/3 dispatch body must end with '
              'DisclaimerCopy.notificationFooter. The dispatcher '
              'appends it once; the renderer never adds another.',
        );
        expect(
          body,
          contains(DisclaimerCopy.notificationFooter),
          reason:
              'disclaimer footer must be present (substring) - '
              'defence-in-depth for the suffix assertion above',
        );

        // The Quote source for Tier 3 is always curated - never AI.
        expect(
          pending.dispatch.tier,
          Tier.three,
          reason: 'controller state must reflect Tier 3 on a Tier 3 emission',
        );
        // Tier 3 CTA is `open_crisis` (CrisisResourcesScreen).
        expect(
          pending.dispatch.ctas,
          contains('open_crisis'),
          reason:
              'Tier 3 CTAs must contain open_crisis - '
              'HB-007 §"Dispatcher state machine"',
        );
        expect(
          pending.dispatch.ctas,
          contains('opt_out'),
          reason:
              'every tier must offer an opt-out CTA - '
              "CLAUDE.md 'compassionate imperatives'",
        );
      },
    );

    testWidgets(
      'Tier 3 banner Open → CrisisResourcesScreen renders with the hotline '
      'tile + 3 resource cards',
      (tester) async {
        await pump(tester);
        await emitTier3AndSettle(tester);

        expect(find.byType(InterventionBanner), findsOneWidget);
        // Tap "Open" → router pushes /intervention/crisis.
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(
          find.byType(CrisisResourcesScreen),
          findsOneWidget,
          reason:
              'Tier 3 banner Open must route to CrisisResourcesScreen - '
              'the crisis-resources surface anchored on Hotline 1323',
        );
        // The Hotline tile renders "Call Hotline 1323" as its title.
        expect(
          find.text('Call Hotline 1323'),
          findsOneWidget,
          reason: 'CrisisResourcesScreen must render the Hotline 1323 tile',
        );
        // The screen also surfaces three resource entries: a directory
        // link, the "what to expect" expansion, and the "other
        // resources" expansion. We assert each visible label so a
        // refactor that drops one tile fails here.
        expect(
          find.text('Find a professional near you'),
          findsOneWidget,
          reason:
              'CrisisResourcesScreen must include the "Find a '
              'professional near you" tile (Department of Mental Health '
              'directory link)',
        );
        expect(
          find.text('What to expect when you call'),
          findsOneWidget,
          reason:
              'CrisisResourcesScreen must include the "What to expect '
              'when you call" expansion',
        );
        expect(
          find.text('Other resources'),
          findsOneWidget,
          reason:
              'CrisisResourcesScreen must include the "Other resources" '
              'expansion with three child hotlines (Thai Suicide Helpline, '
              'iCare Foundation, Emergency services 1669)',
        );

        // TC-38 again - the body inside the screen must carry the
        // disclaimer footer.
        expect(
          find.textContaining(DisclaimerCopy.notificationFooter),
          findsOneWidget,
          reason:
              'CrisisResourcesScreen must render the dispatched body '
              'including the disclaimer footer',
        );
      },
    );

    testWidgets('TC-41 re-assertion - QuoteSafetyFilterImpl rejects every off-script / '
        'forbidden / over-length input from inside the running app', (tester) async {
      await pump(tester);

      // Resolve the production [QuoteSafetyFilterImpl] from the
      // app's ProviderContainer. We do NOT emit a Tier 3 pattern
      // here - this sub-flow validates the filter wiring, not the
      // dispatcher. The filter is the Tier 1/2 sieve; the unit
      // test in `quote_safety_filter_impl_test.dart` covers the
      // canonical 55 inputs. We re-exercise a 30-input subset
      // through the app's resolved filter to prove the
      // `quoteSafetyFilterProvider` is wired to the production
      // implementation and not a no-op stub.
      final element = tester.element(find.byType(InterventionBanner));
      final container = ProviderScope.containerOf(element);
      final filter = container.read(quoteSafetyFilterProvider);

      // 30 rejection inputs spanning all four canonical categories
      // from the unit test. ~10 forbidden-word + 10 over-length +
      // 5 off-script + 5 almost-OK = the 30-input integration
      // contract from the brief ("20-30 inputs is acceptable for
      // the integration suite if the unit test already covers the
      // full 55").
      const forbiddenInputs = <String>[
        'Your depression may pass if you breathe slowly.',
        'A short pause can help with bipolar weather.',
        'We will not diagnose you here, only invite a pause.',
        'A diagnosis is not what you need right now.',
        'Your medication regime aside, a gentle breath helps.',
        'We prescribe nothing - only a kind moment.',
        'Outside of therapy, a short pause is welcome.',
        'Your therapist might agree a breath is gentle.',
        'You must take a slow breath right now.',
        'You should breathe slowly and the storm will pass.',
      ];
      final overLengthInputs = <String>[
        'A gentle breath can help the soil settle when the weather feels heavy and the garden has held many quiet moments through the week and the day before now.',
        'When rainy days happen the roots still hold and a soft breath can be a kind moment to yourself and the garden has been through gentle pauses many times before now.',
        'Would you like a soft pause for the garden today as a gentle breath can soften the moment and the soil has held many soft rainy days through this week ahead.',
        'Soft breaths help the garden hold steady when the weather feels heavy and the gentle pause can be enough for the moment to settle into a kind quiet space here.',
        'A few slow breaths can be enough for the garden to soften and the soil to settle as the weather passes and the gentle moment can hold for as long as you like.',
        'Rainy days happen in the garden and a short gentle breath can be a kind moment to yourself if it feels welcome to pause for a soft and quiet moment together here.',
        'The garden has weathered a long stretch and a gentle breath can help the soil settle for as long as you like to pause and the moment will hold for a quiet while here.',
        'Soft breathing can be a kind moment in the garden as the weather softens and the soil settles into a quiet pause for as long as you would like to breathe gently now today.',
        'A quiet breath can help the moment hold when the garden has had a heavy stretch and the soil has been through many rainy days through this week and the one before too.',
        'The garden is still here and a gentle breath can help you notice it for as long as you like to pause and the soft moment will hold for a kind quiet while together here.',
      ];
      const offScriptInputs = <String>[
        'The weather in Lyon is wonderful today.',
        'Apples roll downhill quickly during autumn.',
        'My cat enjoys chasing red dot lasers.',
        'Carburetors require periodic maintenance schedules.',
        'Quantum mechanics confuses many graduate students.',
      ];
      const almostOkInputs = <String>[
        'Maybe a short breathing exercise would help - you should try it.',
        'A gentle pause might help; you must breathe slowly for a moment.',
        'Soft breaths can be kind - you have to give it a try.',
        'A quiet breath would be welcome now if it helps.',
        'Writing a few lines could help you overcome the weather.',
      ];

      final allInputs = <String>[
        ...forbiddenInputs,
        ...overLengthInputs,
        ...offScriptInputs,
        ...almostOkInputs,
      ];
      expect(
        allInputs,
        hasLength(30),
        reason:
            'TC-41 integration subset is 30 rejection inputs '
            '(10 forbidden + 10 over-length + 5 off-script + 5 '
            'almost-OK). The full 55 lives in '
            'quote_safety_filter_impl_test.dart.',
      );

      // Sanity: the filter is the production impl.
      expect(
        filter,
        isA<QuoteSafetyFilterImpl>(),
        reason:
            'quoteSafetyFilterProvider must resolve to '
            'QuoteSafetyFilterImpl in the integration harness - a '
            'no-op stub would let everything through and silently '
            'pass the rejection-rate test',
      );

      var passThroughs = 0;
      for (final input in allInputs) {
        final result = filter.gate(input, tier: AiAllowedTier.one);
        if (result is Ok<Quote, QuoteFailure>) {
          passThroughs += 1;
          fail(
            'Safety filter let through input verbatim: '
            '"${result.value.text}" (input was: "$input")',
          );
        }
      }

      expect(
        passThroughs,
        0,
        reason:
            'TC-41 invariant: ZERO pass-throughs across the rejection '
            'set. 30/30 inputs must return Err(FilterReject). A single '
            'pass-through fails the build - that is the entire point.',
      );
    });
  });
}

/// Controllable [PatternRepository] for the integration suite. Tests
/// call [emit] to push a synthetic [PatternResult]; the controller's
/// stream subscription receives it and dispatches.
class _ControllablePatternRepository implements PatternRepository {
  final StreamController<PatternResult?> _controller =
      StreamController<PatternResult?>.broadcast();

  void emit(PatternResult? result) => _controller.add(result);

  Future<void> dispose() async => _controller.close();

  @override
  Stream<PatternResult?> watch({
    required String userId,
    required String dateId,
  }) => _controller.stream;

  @override
  Future<Result<void, PatternFailure>> save({
    required String userId,
    required PatternResult result,
  }) async => const Ok(null);

  @override
  Stream<List<PatternResult>> watchRange({
    required String userId,
    required String startDateId,
    required String endDateId,
  }) => const Stream<List<PatternResult>>.empty();
}

PatternResult _patternForTier3() => PatternResult(
  dateId: _today(),
  mannKendallZ: null,
  slidingNegCount: 0,
  // 3 consecutive entries at S ≤ -0.6 is the canonical Tier 3 trigger;
  // we set the field to >= 3 here so a future audit reader can see the
  // synthetic shape mirrors the real engine's output. The engine
  // itself is not in the loop on this test - we are testing the
  // DOWNSTREAM dispatcher path, with Tier 3 already escalated.
  consecutiveHighIntensity: 3,
  zScoreToday: -3.0,
  cusumC: 5.0,
  triggeredTier: Tier.three,
);

String _today() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}
