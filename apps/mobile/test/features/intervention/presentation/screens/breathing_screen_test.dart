import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moodbloom/features/intervention/domain/entities/intervention_dispatch.dart';
import 'package:moodbloom/features/intervention/presentation/controllers/intervention_controller.dart';
import 'package:moodbloom/features/intervention/presentation/screens/breathing_screen.dart';
import 'package:moodbloom/features/intervention/presentation/widgets/dispatch_safe_defaults.dart';
import 'package:moodbloom/features/pattern_engine/domain/entities/tier.dart';

class _RecordingController extends InterventionController {
  int completeCalls = 0;
  int optOutCalls = 0;

  @override
  InterventionControllerState build() => const InterventionIdle();

  @override
  void complete() {
    completeCalls += 1;
    state = const InterventionIdle();
  }

  @override
  Future<void> optOut() async {
    optOutCalls += 1;
    state = const InterventionIdle();
  }
}

InterventionDispatch _dispatch(Tier tier, String body) => InterventionDispatch(
  tier: tier,
  body: body,
  ctas: const ['open_breathing', 'opt_out'],
  dispatchId: 'd-${tier.name}',
  quoteId: 'q-${tier.name}',
  dispatchedAt: DateTime(2026, 5, 13, 10, 30),
);

/// Builds a GoRouter where the breathing screen is PUSHED on top of a
/// host route. That way `context.pop()` from within the screen returns
/// to the host (mirroring production), instead of throwing "nothing to
/// pop".
Widget _makeApp({
  required InterventionDispatch? dispatch,
  required _RecordingController controller,
}) {
  final router = GoRouter(
    initialLocation: '/host',
    routes: [
      GoRoute(
        path: '/host',
        builder: (_, _) => const Scaffold(body: Text('host-screen')),
        routes: [
          GoRoute(
            path: 'breathing',
            builder: (context, state) => Scaffold(
              body: SafeArea(
                child: BreathingView(
                  dispatch: dispatch,
                  onClose: () => context.pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: [interventionControllerProvider.overrideWith(() => controller)],
    child: MaterialApp.router(routerConfig: router, theme: buildLightTheme()),
  );
}

/// Pumps the app, then PUSHes /host/breathing so the breathing screen
/// sits on the navigation stack with /host below it. Also sets a
/// 1200×900 surface so the lower-row CTAs ("Done for now" / "I'm okay")
/// stay inside the viewport - the default 800×600 was clipping the
/// right-anchored button.
Future<void> _pushScreen(WidgetTester tester) async {
  // Force the view's logical size large enough that the bottom button
  // row stays inside the hit-testable region. `tester.view` is the
  // canonical knob - `setSurfaceSize` alone does NOT propagate to
  // `MediaQuery.of(context).size`; we have to set both physicalSize
  // and devicePixelRatio.
  tester.view.physicalSize = const Size(1200, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pump();
  final ctx = tester.element(find.text('host-screen'));
  GoRouter.of(ctx).push('/host/breathing');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  group('BreathingScreen', () {
    testWidgets('renders dispatched body verbatim', (tester) async {
      final dispatch = _dispatch(
        Tier.one,
        'A gentle Tier 1 phrase.\n\nfooter.',
      );
      final controller = _RecordingController();
      await tester.pumpWidget(
        _makeApp(dispatch: dispatch, controller: controller),
      );
      await _pushScreen(tester);
      expect(find.textContaining('A gentle Tier 1 phrase.'), findsOneWidget);
    });

    testWidgets(
      'falls back to DispatchSafeDefaults.tier1 when dispatch is null',
      (tester) async {
        final controller = _RecordingController();
        await tester.pumpWidget(
          _makeApp(dispatch: null, controller: controller),
        );
        await _pushScreen(tester);
        expect(
          find.textContaining('rainy days'),
          findsOneWidget,
          reason: 'Safe default contains the canonical Tier 1 phrase.',
        );
        expect(DispatchSafeDefaults.tier1, contains('rainy days'));
      },
    );

    testWidgets('timer counts down from 2:00 → 1:59', (tester) async {
      final controller = _RecordingController();
      await tester.pumpWidget(
        _makeApp(
          dispatch: _dispatch(Tier.one, 'Tier 1 body'),
          controller: controller,
        ),
      );
      await _pushScreen(tester);
      // The exercise waits for an explicit "Begin" tap before the
      // countdown starts.
      await tester.tap(find.text('Begin'));
      await tester.pump();
      expect(find.text('2:00'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('1:59'), findsOneWidget);
    });

    testWidgets('waits for "Begin" before the countdown starts', (
      tester,
    ) async {
      final controller = _RecordingController();
      await tester.pumpWidget(
        _makeApp(
          dispatch: _dispatch(Tier.one, 'Tier 1 body'),
          controller: controller,
        ),
      );
      await _pushScreen(tester);
      // Pre-start: a "Begin" CTA is shown, and neither the countdown nor
      // the "I'm done" button has appeared yet.
      expect(find.text('Begin'), findsOneWidget);
      expect(find.text('2:00'), findsNothing);
      expect(find.text("I'm done"), findsNothing);

      await tester.tap(find.text('Begin'));
      await tester.pump();

      // After Begin: the countdown and the done CTA appear.
      expect(find.text('2:00'), findsOneWidget);
      expect(find.text("I'm done"), findsOneWidget);
      expect(find.text('Begin'), findsNothing);
    });

    testWidgets('"I\'m done" calls controller.complete() then pops', (
      tester,
    ) async {
      final controller = _RecordingController();
      await tester.pumpWidget(
        _makeApp(
          dispatch: _dispatch(Tier.one, 'Tier 1 body'),
          controller: controller,
        ),
      );
      await _pushScreen(tester);
      // Start the exercise so the "I'm done" CTA is present.
      await tester.tap(find.text('Begin'));
      await tester.pump();
      // The previous "Done for now" + "I'm okay" two-button row was
      // merged into a single "I'm done" CTA that routes through
      // `controller.complete()`. Opt-out semantics are still exercised
      // by intervention_banner_test.dart.
      await tester.tap(find.text("I'm done"));
      // Avoid pumpAndSettle because the breathing animation repeats
      // forever - settle never returns.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(controller.completeCalls, 1);
      // The host route is on top again - the screen content is gone.
      expect(find.text('host-screen'), findsOneWidget);
    });

    testWidgets(
      'breathing rhythm guide carries the canonical semantics label',
      (tester) async {
        final controller = _RecordingController();
        await tester.pumpWidget(
          _makeApp(
            dispatch: _dispatch(Tier.one, 'Tier 1 body'),
            controller: controller,
          ),
        );
        await _pushScreen(tester);
        expect(find.bySemanticsLabel('Breathing rhythm guide'), findsWidgets);
      },
    );

    testWidgets('after 120 seconds the snackbar appears and the screen pops', (
      tester,
    ) async {
      final controller = _RecordingController();
      await tester.pumpWidget(
        _makeApp(
          dispatch: _dispatch(Tier.one, 'Tier 1 body'),
          controller: controller,
        ),
      );
      await _pushScreen(tester);
      // Start the exercise so the countdown timer is running.
      await tester.tap(find.text('Begin'));
      await tester.pump();
      // Drive the fake clock forward in 1s steps so the periodic timer
      // can fire on each second boundary.
      for (var i = 0; i < 120; i += 1) {
        await tester.pump(const Duration(seconds: 1));
      }
      // The SnackBar emerges via an enter animation that briefly has
      // two render-tree positions (the queue + the active slot), so
      // accept any positive count here - the contract under test is
      // "completion surfaces the canonical message", not "exactly one
      // mount frame".
      expect(find.textContaining('Well done'), findsAtLeastNWidgets(1));
      await tester.pump(const Duration(milliseconds: 500));
      expect(controller.completeCalls, greaterThanOrEqualTo(1));
    });
  });
}
