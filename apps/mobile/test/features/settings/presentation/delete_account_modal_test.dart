import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/settings/presentation/widgets/delete_account_modal.dart';

/// Widget tests for [DeleteAccountModal].
///
/// HB-004 + O12: copy is locked verbatim. The body, primary label, and
/// cancel label must be byte-identical to the brief — these assertions
/// are the contract security-reviewer relies on.
///
/// The modal is intentionally state-free: it renders, returns a bool
/// from `Navigator.pop`, and never invokes a controller. The
/// "Cancel pops with false" test confirms that contract by asserting
/// the returned value is `false` (not null, not true) and that no
/// other side-effect can fire because the modal owns no callbacks.
void main() {
  group('DeleteAccountModal', () {
    /// Pumps a Scaffold with an "open" button that, on tap, opens the
    /// modal via `showDialog`. The future returned by `showDialog`
    /// resolves with whatever the modal pops; we hold a reference to
    /// it on the test rig so each assertion can inspect the result.
    Future<({Future<bool?> popped})> openModal(WidgetTester tester) async {
      late Future<bool?> popped;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  popped = showDialog<bool>(
                    context: context,
                    builder: (_) => const DeleteAccountModal(),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return (popped: popped);
    }

    testWidgets('renders title and body verbatim per HB-004', (tester) async {
      final rig = await openModal(tester);

      expect(find.text('Delete your account?'), findsOneWidget);
      expect(
        find.text(
          'This permanently deletes your account, all entries, and '
          'photos. This cannot be undone.',
        ),
        findsOneWidget,
      );
      expect(find.text('I understand, delete'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Drain the pending future so the test ends cleanly.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await rig.popped;
    });

    testWidgets(
      'destructive button uses theme.colorScheme.error for foreground',
      (tester) async {
        final rig = await openModal(tester);

        // Resolve the BuildContext that owns the theme so the test
        // asserts against the same ColorScheme the widget reads.
        final BuildContext dialogContext = tester.element(
          find.text('I understand, delete'),
        );
        final expectedError = Theme.of(dialogContext).colorScheme.error;

        // The FilledButton.styleFrom foregroundColor materialises into
        // the ButtonStyle's foregroundColor — that's the rendering
        // truth the user sees.
        final filled = tester.widget<FilledButton>(find.byType(FilledButton));
        final fg = filled.style?.foregroundColor?.resolve(<WidgetState>{});
        expect(fg, expectedError);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        await rig.popped;
      },
    );

    testWidgets('Cancel pops with false; no controller is invoked', (
      tester,
    ) async {
      final rig = await openModal(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // The modal returns `false` on Cancel — distinct from `true` on
      // confirm and `null` on barrier-dismiss. The Settings screen
      // treats anything other than `true` as "do nothing", so a
      // controller invocation is structurally impossible from a Cancel
      // tap; the modal carries no callback wiring.
      expect(await rig.popped, isFalse);
    });

    testWidgets(
      'primary tap pops with true so the screen can run the reauth flow',
      (tester) async {
        final rig = await openModal(tester);

        await tester.tap(find.text('I understand, delete'));
        await tester.pumpAndSettle();

        expect(await rig.popped, isTrue);
      },
    );
  });
}
