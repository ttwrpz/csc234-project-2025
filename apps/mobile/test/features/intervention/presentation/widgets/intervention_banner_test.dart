import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moodbloom/app/router.dart' show routerProvider;
import 'package:moodbloom/features/intervention/domain/entities/intervention_dispatch.dart';
import 'package:moodbloom/features/intervention/presentation/controllers/intervention_controller.dart';
import 'package:moodbloom/features/intervention/presentation/widgets/intervention_banner.dart';
import 'package:moodbloom/features/pattern_engine/domain/entities/tier.dart';

class _SeededController extends InterventionController {
  _SeededController(this.initial);

  final InterventionControllerState initial;
  int optOutCalls = 0;

  @override
  InterventionControllerState build() => initial;

  @override
  Future<void> optOut() async {
    optOutCalls += 1;
    state = const InterventionIdle();
  }
}

InterventionDispatch _dispatch(Tier tier) => InterventionDispatch(
  tier: tier,
  body:
      'A compassionate quote for tier ${tier.name}. There is more text after '
      'the first sentence to exercise the truncation logic.',
  ctas: const ['open', 'opt_out'],
  dispatchId: 'd-${tier.name}',
  quoteId: 'q-${tier.name}',
  dispatchedAt: DateTime(2026, 5, 13, 10, 30),
);

Widget _makeApp({required _SeededController controller}) {
  return ProviderScope(
    overrides: [interventionControllerProvider.overrideWith(() => controller)],
    child: const MaterialApp(home: Scaffold(body: InterventionBanner())),
  );
}

Widget _makeAppWithRouter({
  required _SeededController controller,
  required void Function(String routeName, Object? extra) onOpen,
}) {
  final router = GoRouter(
    initialLocation: '/host',
    routes: [
      GoRoute(
        path: '/host',
        builder: (context, state) => const Scaffold(body: InterventionBanner()),
      ),
      GoRoute(
        path: '/intervention/breathing',
        name: 'intervention.breathing',
        builder: (context, state) {
          onOpen('intervention.breathing', state.extra);
          return const Scaffold(body: Text('breathing'));
        },
      ),
      GoRoute(
        path: '/intervention/journal',
        name: 'intervention.journal',
        builder: (context, state) {
          onOpen('intervention.journal', state.extra);
          return const Scaffold(body: Text('journal'));
        },
      ),
      GoRoute(
        path: '/intervention/crisis',
        name: 'intervention.crisis',
        builder: (context, state) {
          onOpen('intervention.crisis', state.extra);
          return const Scaffold(body: Text('crisis'));
        },
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      interventionControllerProvider.overrideWith(() => controller),
      // The banner navigates via `ref.read(routerProvider)` (it's hosted
      // above the Router's Navigator, so a context lookup can't find the
      // GoRouter). Override the provider with this test router so the tap
      // drives the same instance that builds the MaterialApp.
      routerProvider.overrideWithValue(router),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('InterventionBanner', () {
    testWidgets('Idle state → renders SizedBox.shrink (no card)', (
      tester,
    ) async {
      final controller = _SeededController(const InterventionIdle());
      await tester.pumpWidget(_makeApp(controller: controller));
      await tester.pump();
      expect(find.byType(InterventionBanner), findsOneWidget);
      expect(find.byType(Card), findsNothing);
      expect(find.text('Open'), findsNothing);
    });

    testWidgets('Pending state → banner visible with preview text', (
      tester,
    ) async {
      final controller = _SeededController(
        InterventionPending(_dispatch(Tier.one)),
      );
      await tester.pumpWidget(_makeApp(controller: controller));
      await tester.pump();
      expect(
        find.textContaining('A compassionate quote for tier one'),
        findsOneWidget,
      );
      expect(find.text('Open'), findsOneWidget);
      expect(find.text("I'm okay"), findsOneWidget);
    });

    testWidgets(
      'Tap "Open" → navigates to the tier-1 named route with dispatch '
      'forwarded as extra',
      (tester) async {
        final captured = <({String name, Object? extra})>[];
        final controller = _SeededController(
          InterventionPending(_dispatch(Tier.one)),
        );
        await tester.pumpWidget(
          _makeAppWithRouter(
            controller: controller,
            onOpen: (name, extra) => captured.add((name: name, extra: extra)),
          ),
        );
        await tester.pump();
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(captured, hasLength(1));
        expect(captured.first.name, 'intervention.breathing');
        expect(captured.first.extra, isA<InterventionDispatch>());
      },
    );

    testWidgets("Tap 'I'm okay' → controller.optOut() called", (tester) async {
      final controller = _SeededController(
        InterventionPending(_dispatch(Tier.one)),
      );
      await tester.pumpWidget(_makeApp(controller: controller));
      await tester.pump();
      await tester.tap(find.text("I'm okay"));
      await tester.pumpAndSettle();
      expect(controller.optOutCalls, 1);
    });

    testWidgets(
      'Swipe horizontal → Dismissible fires → controller.optOut() called',
      (tester) async {
        final controller = _SeededController(
          InterventionPending(_dispatch(Tier.one)),
        );
        await tester.pumpWidget(_makeApp(controller: controller));
        await tester.pump();
        await tester.fling(
          find.byType(Dismissible),
          const Offset(500, 0),
          1000,
        );
        await tester.pumpAndSettle();
        expect(controller.optOutCalls, 1);
      },
    );

    testWidgets(
      'Tier 3 dispatch → banner card paints with the dark-glass surface',
      (tester) async {
        final controller = _SeededController(
          InterventionPending(_dispatch(Tier.three)),
        );
        await tester.pumpWidget(_makeApp(controller: controller));
        await tester.pump();
        final materials = tester
            .widgetList<Material>(find.byType(Material))
            .toList();
        // The banner was unified to the saved-mood MbAppToast dark-glass
        // look across all tiers (near-black ARGB 235,20,24,30).
        const darkGlass = Color.fromARGB(235, 20, 24, 30);
        expect(
          materials.any((m) => m.color == darkGlass),
          isTrue,
          reason: 'Tier 3 banner must use the dark-glass toast surface.',
        );
      },
    );
  });
}
