import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moodbloom/features/intervention/domain/entities/intervention_dispatch.dart';
import 'package:moodbloom/features/intervention/presentation/controllers/intervention_controller.dart';
import 'package:moodbloom/features/intervention/presentation/screens/crisis_resources_screen.dart';
import 'package:moodbloom/features/intervention/presentation/widgets/intervention_opt_out_button.dart';
import 'package:moodbloom/features/pattern_engine/domain/entities/tier.dart';

/// Sprint 5 Day 3 a11y sweep — Tier 3 crisis resources screen.
///
/// CRITICAL contrast check: the Hotline tile is the load-bearing
/// affordance for the highest-acuity tier. The tile MUST pass WCAG 2.2
/// AA contrast (≥ 4.5:1 for body, ≥ 3.0:1 for large text) for both its
/// title and subtitle.
///
/// We compute the ratio in-test using the WCAG formula:
///   1. sRGB integer (0..255) → linear channel:
///        c_lin = c / 12.92                  if c ≤ 0.03928
///        c_lin = ((c + 0.055) / 1.055)^2.4  otherwise
///   2. Relative luminance:
///        L = 0.2126*R + 0.7152*G + 0.0722*B
///   3. Contrast ratio:
///        (max(L1, L2) + 0.05) / (min(L1, L2) + 0.05)
///
/// We read the live theme's resolved colors (NOT raw hex) so a future
/// token re-mapping invalidates the test cleanly.
///
/// Read the production crisis_resources_screen.dart: the Hotline tile
/// background is `colorScheme.primaryContainer`, NOT `errorContainer`
/// (verified line 244). Text + icon use `onPrimaryContainer`. The
/// banner is the only Tier 3 surface that uses `errorContainer`.

double _relativeLuminance(Color color) {
  final r = _toLinearChannel(color.r);
  final g = _toLinearChannel(color.g);
  final b = _toLinearChannel(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// `channel` arrives as a 0..1 double from `Color.r/g/b` (Flutter 3.27+
/// migrated away from the legacy 0..255 int channels). The WCAG formula
/// uses sRGB-relative values directly without re-dividing by 255.
double _toLinearChannel(double channel) {
  if (channel <= 0.03928) return channel / 12.92;
  return math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
}

double _contrastRatio(Color fg, Color bg) {
  final l1 = _relativeLuminance(fg);
  final l2 = _relativeLuminance(bg);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

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
  body: 'We care about you. If it helps to talk, the Thai Mental Health '
      'Hotline is free at 1323, 24 hours.\n\n'
      'MoodBloom is not a medical device. Not a substitute for professional '
      'care.',
  ctas: const ['open_crisis', 'opt_out'],
  dispatchId: 'd-three-a11y',
  quoteId: 'q-three-a11y',
  dispatchedAt: DateTime(2026, 5, 13, 10, 30),
);

Widget _makeApp({
  required _RecordingController controller,
  Brightness brightness = Brightness.light,
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
            builder: (_, _) =>
                CrisisResourcesScreen(dispatch: _tier3Dispatch()),
          ),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: [interventionControllerProvider.overrideWith(() => controller)],
    child: MaterialApp.router(
      routerConfig: router,
      theme: brightness == Brightness.dark
          ? buildDarkTheme()
          : buildLightTheme(),
    ),
  );
}

Future<void> _pushCrisis(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pump();
  final ctx = tester.element(find.text('host-screen'));
  GoRouter.of(ctx).push('/host/crisis');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  // Stub url_launcher so the Hotline tile's onTap doesn't crash on
  // MissingPluginException. The exact tap is exercised in
  // crisis_resources_screen_test.dart; here we just need the screen to
  // mount.
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/url_launcher'),
          (call) async => true,
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/url_launcher'),
          null,
        );
  });

  group('CrisisResourcesScreen — Hotline 1323 contrast (WCAG 2.2 AA)', () {
    testWidgets(
      'Hotline tile title contrast ≥ 4.5:1 on light theme',
      (tester) async {
        await tester.pumpWidget(
          _makeApp(controller: _RecordingController()),
        );
        await _pushCrisis(tester);

        // Read the resolved theme colors directly. The Hotline tile uses
        // primaryContainer for its background and onPrimaryContainer for
        // its text — verified at crisis_resources_screen.dart line 244.
        final ctx = tester.element(find.byType(CrisisResourcesScreen));
        final scheme = Theme.of(ctx).colorScheme;
        final ratio = _contrastRatio(
          scheme.onPrimaryContainer,
          scheme.primaryContainer,
        );
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason:
              'Hotline 1323 tile (light) — onPrimaryContainer vs '
              'primaryContainer contrast is $ratio:1, WCAG AA requires ≥4.5:1. '
              'This is the Tier 3 load-bearing affordance.',
        );
      },
    );

    testWidgets(
      'Hotline tile title contrast ≥ 4.5:1 on dark theme',
      (tester) async {
        await tester.pumpWidget(
          _makeApp(
            controller: _RecordingController(),
            brightness: Brightness.dark,
          ),
        );
        await _pushCrisis(tester);

        final ctx = tester.element(find.byType(CrisisResourcesScreen));
        final scheme = Theme.of(ctx).colorScheme;
        final ratio = _contrastRatio(
          scheme.onPrimaryContainer,
          scheme.primaryContainer,
        );
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason:
              'Hotline 1323 tile (dark) — onPrimaryContainer vs '
              'primaryContainer contrast is $ratio:1, WCAG AA requires ≥4.5:1.',
        );
      },
    );
  });

  group('CrisisResourcesScreen — semantics labels', () {
    testWidgets(
      'Hotline tile is announced with a call-action label including "1323"',
      (tester) async {
        await tester.pumpWidget(
          _makeApp(controller: _RecordingController()),
        );
        await _pushCrisis(tester);

        // The tile wraps an InkWell + Material in a Semantics(button:
        // true, label: 'Call Hotline 1323, free, 24 hours, in Thai').
        // RegExp keeps the test resilient to a future re-arrangement of
        // the comma-separated fragments.
        expect(
          find.bySemanticsLabel(RegExp('Call Hotline 1323')),
          findsAtLeastNWidgets(1),
          reason: 'Hotline tile must announce "Call Hotline 1323" + context.',
        );
      },
    );

    testWidgets(
      'all three resource cards are reachable via their title text',
      (tester) async {
        await tester.pumpWidget(
          _makeApp(controller: _RecordingController()),
        );
        await _pushCrisis(tester);

        expect(find.text('Find a professional near you'), findsOneWidget);
        expect(find.text('What to expect when you call'), findsOneWidget);
        expect(find.text('Other resources'), findsOneWidget);
      },
    );

    testWidgets(
      '"I\'m okay for now" opt-out announces with dismiss-action context',
      (tester) async {
        await tester.pumpWidget(
          _makeApp(controller: _RecordingController()),
        );
        await _pushCrisis(tester);

        // The Tier 3 screen passes the custom label "I'm okay for now"
        // because a curt "I'm okay" reads dismissive at this tier (per
        // intervention_opt_out_button.dart). The Semantics wrapper
        // composes "$label, dismiss this reminder".
        expect(
          find.bySemanticsLabel(
            RegExp("I'm okay for now, dismiss this reminder"),
          ),
          findsAtLeastNWidgets(1),
        );
        expect(find.byType(InterventionOptOutButton), findsOneWidget);
      },
    );

    testWidgets(
      'back-gesture exit confirmation has accessible "Stay" / "Close" buttons',
      (tester) async {
        // PopScope only intercepts native-back. The dialog is shown by
        // _confirmExit(); we exercise the same path by reading the
        // PopScope and calling onPopInvokedWithResult directly. The dialog
        // structure under assertion is identical regardless of trigger.
        await tester.pumpWidget(
          _makeApp(controller: _RecordingController()),
        );
        await _pushCrisis(tester);

        // The dialog has 2 actions: TextButton("Stay") + FilledButton("Close").
        // Trigger via the navigator's pop attempt — PopScope intercepts.
        final ctx = tester.element(find.byType(CrisisResourcesScreen));
        // The PopScope's onPopInvokedWithResult is async — we call it
        // directly to skip the platform-channel pop simulation.
        await Navigator.of(ctx).maybePop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));

        // Both buttons must be reachable with distinct labels.
        expect(find.widgetWithText(TextButton, 'Stay'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Close'), findsOneWidget);

        final stay = tester.getSemantics(
          find.widgetWithText(TextButton, 'Stay'),
        );
        expect(stay.label, equals('Stay'));
        expect(stay.hasFlag(SemanticsFlag.isButton), isTrue);

        final close = tester.getSemantics(
          find.widgetWithText(FilledButton, 'Close'),
        );
        expect(close.label, equals('Close'));
        expect(close.hasFlag(SemanticsFlag.isButton), isTrue);
      },
    );
  });

  group('CrisisResourcesScreen — 200% type readability', () {
    testWidgets(
      'dispatch body + Hotline tile + 3 cards + opt-out render without overflow',
      (tester) async {
        final exceptions = <Object>[];
        FlutterError.onError = (details) => exceptions.add(details.exception);
        addTearDown(
          () => FlutterError.onError = FlutterError.dumpErrorToConsole,
        );

        final controller = _RecordingController();
        final router = GoRouter(
          initialLocation: '/host',
          routes: [
            GoRoute(
              path: '/host',
              builder: (_, _) => const Scaffold(body: Text('host-screen')),
              routes: [
                GoRoute(
                  path: 'crisis',
                  builder: (_, _) =>
                      CrisisResourcesScreen(dispatch: _tier3Dispatch()),
                ),
              ],
            ),
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              interventionControllerProvider.overrideWith(() => controller),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              theme: buildLightTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(2.0),
                ),
                child: child!,
              ),
            ),
          ),
        );
        // ListView body absorbs vertical overflow; the per-card
        // Row(Icon + Column) is the risk zone. Use a tablet-class width.
        tester.view.physicalSize = const Size(1200, 3200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pump();
        final ctx = tester.element(find.text('host-screen'));
        GoRouter.of(ctx).push('/host/crisis');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final overflows = exceptions
            .map((e) => e.toString())
            .where(
              (s) => s.contains('overflowed') || s.contains('RenderFlex'),
            )
            .toList();
        expect(
          overflows,
          isEmpty,
          reason:
              'CrisisResourcesScreen must not overflow at 200% type. '
              'Got: $overflows',
        );

        // Sanity: the load-bearing affordance is still on screen.
        expect(
          find.text('Call Hotline 1323'),
          findsOneWidget,
          reason: 'Hotline 1323 must remain visible at 200% type.',
        );
      },
    );
  });
}
