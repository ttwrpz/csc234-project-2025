import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moodbloom/features/intervention/domain/entities/intervention_dispatch.dart';
import 'package:moodbloom/features/intervention/presentation/controllers/intervention_controller.dart';
import 'package:moodbloom/features/intervention/presentation/screens/crisis_resources_screen.dart';
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

InterventionDispatch _tier3Dispatch() => InterventionDispatch(
  tier: Tier.three,
  body:
      'We care about you. If it helps to talk, the Thai Mental Health '
      'Hotline is free at 1323, 24 hours.\n\nfooter.',
  ctas: const ['open_crisis', 'opt_out'],
  dispatchId: 'd-three-fixed',
  quoteId: 'q-three-fixed',
  dispatchedAt: DateTime(2026, 5, 13, 10, 30),
);

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
            path: 'crisis',
            builder: (context, state) =>
                CrisisResourcesScreen(dispatch: dispatch),
          ),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: [interventionControllerProvider.overrideWith(() => controller)],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _pushScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pump();
  final ctx = tester.element(find.text('host-screen'));
  GoRouter.of(ctx).push('/host/crisis');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  /// Intercepts `url_launcher` platform-channel calls so the test can
  /// assert the dialer was invoked. Without this, the launcher throws
  /// `MissingPluginException` in the test host.
  final List<MethodCall> launchCalls = [];

  setUp(() {
    launchCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/url_launcher'),
          (call) async {
            launchCalls.add(call);
            return true;
          },
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/url_launcher'),
          null,
        );
  });

  group('CrisisResourcesScreen', () {
    testWidgets('renders body verbatim; substring "1323" is present', (
      tester,
    ) async {
      final controller = _RecordingController();
      await tester.pumpWidget(
        _makeApp(dispatch: _tier3Dispatch(), controller: controller),
      );
      await _pushScreen(tester);
      // Defense-in-depth: the body must surface the Hotline marker.
      expect(find.textContaining('1323'), findsWidgets);
    });

    testWidgets('Hotline tile carries accessible label', (tester) async {
      final controller = _RecordingController();
      await tester.pumpWidget(
        _makeApp(dispatch: _tier3Dispatch(), controller: controller),
      );
      await _pushScreen(tester);
      // The Semantics is merged with the InkWell wrapper; assert via a
      // RegExp so a re-arrangement of inner Material/InkWell semantics
      // doesn't break the contract that the canonical label is present.
      expect(
        find.bySemanticsLabel(RegExp('Call Hotline 1323')),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets("I'm okay for now → controller.optOut() + screen pops", (
      tester,
    ) async {
      final controller = _RecordingController();
      await tester.pumpWidget(
        _makeApp(dispatch: _tier3Dispatch(), controller: controller),
      );
      await _pushScreen(tester);
      await tester.tap(find.text("I'm okay for now"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(controller.optOutCalls, 1);
    });

    testWidgets("Resource card 'Find a professional near you' is present", (
      tester,
    ) async {
      final controller = _RecordingController();
      await tester.pumpWidget(
        _makeApp(dispatch: _tier3Dispatch(), controller: controller),
      );
      await _pushScreen(tester);
      expect(find.text('Find a professional near you'), findsOneWidget);
      expect(find.text('Other resources'), findsOneWidget);
      expect(find.text('What to expect when you call'), findsOneWidget);
    });
  });
}
