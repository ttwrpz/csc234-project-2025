import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/presentation/widgets/per_flower_detail_modal.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

import '../../../../helpers/pump_app.dart';

MoodEntry _entry() => MoodEntry(
  id: 'e-responsive',
  userId: 'u-1',
  mood: MoodType.happy,
  intensity: 3,
  text: 'responsive launch test',
  createdAt: DateTime(2026, 5, 14, 12, 0),
);

/// Pumps a host page whose "open" button calls
/// `PerFlowerDetailModal.show(context, entry)`. The host's surface size
/// drives the launcher's chrome selection.
Future<void> _pumpHost(WidgetTester tester, Size size) async {
  // Pin physicalSize + devicePixelRatio explicitly on the TestFlutterView.
  // setSurfaceSize alone leaves DPR at the test default (3.0 on Android-
  // emulator), so a "1440 dp desktop" surface would be reported as 480 dp
  // to MediaQuery.sizeOf and the responsive launcher would fire the wrong
  // chrome.
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await pumpApp(
    tester,
    child: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () => PerFlowerDetailModal.show(context, _entry()),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('PerFlowerDetailModal — Wave B responsive launcher', () {
    testWidgets('phone viewport (360x800) presents a BottomSheet, no Dialog', (
      tester,
    ) async {
      await _pumpHost(tester, const Size(360, 800));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Absence of `Dialog` is the load-bearing proof that the phone
      // launcher used showModalBottomSheet — `BottomSheet` as a widget
      // type is not always surfaced in the flutter_test tree (modal-
      // bottom-sheet's internal wrapper varies across Material versions).
      expect(
        find.byType(Dialog),
        findsNothing,
        reason: 'phone-width launcher MUST NOT use a Dialog',
      );
      expect(find.byType(PerFlowerDetailModal), findsOneWidget);
    });

    testWidgets(
      'tablet viewport (768x1024) presents a centered Dialog at 480 dp max',
      (tester) async {
        await _pumpHost(tester, const Size(768, 1024));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(find.byType(Dialog), findsOneWidget);
        expect(find.byType(BottomSheet), findsNothing);
        expect(find.byType(PerFlowerDetailModal), findsOneWidget);

        final constrained = tester.widget<ConstrainedBox>(
          find
              .ancestor(
                of: find.byType(PerFlowerDetailModal),
                matching: find.byType(ConstrainedBox),
              )
              .first,
        );
        expect(
          constrained.constraints.maxWidth,
          480,
          reason:
              'per-flower modal is narrower than the skin grid — the content '
              'is a single entry summary, not a multi-card grid',
        );
      },
    );

    testWidgets(
      'desktop viewport (1440x900) presents a centered Dialog at 560 dp max',
      (tester) async {
        await _pumpHost(tester, const Size(1440, 900));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(find.byType(Dialog), findsOneWidget);
        expect(find.byType(BottomSheet), findsNothing);
        expect(find.byType(PerFlowerDetailModal), findsOneWidget);

        final constrained = tester.widget<ConstrainedBox>(
          find
              .ancestor(
                of: find.byType(PerFlowerDetailModal),
                matching: find.byType(ConstrainedBox),
              )
              .first,
        );
        expect(constrained.constraints.maxWidth, 560);
      },
    );
  });
}
