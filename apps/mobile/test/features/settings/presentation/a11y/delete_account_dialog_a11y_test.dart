import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/settings/presentation/widgets/delete_account_dialog.dart';

import '../../../auth/domain/fakes/fake_auth_repository.dart';

/// Sprint 5 Day 3 a11y sweep — delete-account dialog (S5-new surface
/// from WBS 2.4 wired in via Settings).
///
/// Two-step destructive confirmation. Covered:
///   1. Step 1 — title "Delete account?", body, Cancel + Continue
///      buttons all announce distinctly.
///   2. Step 2 — title "Confirm your password", password field is
///      `obscureText: true`, "Delete forever" + Cancel buttons.
///   3. Destructive button (Delete forever / Continue) is visually
///      prominent — verify it's a FilledButton, not a TextButton,
///      so the screen reader's role announcement matches the visual
///      weight.
///   4. 200% type: both step dialogs render without RenderFlex
///      overflow.

Future<void> _pumpDialog(
  WidgetTester tester, {
  required FakeAuthRepository repo,
  TextScaler textScaler = const TextScaler.linear(1.0),
  Size surfaceSize = const Size(420, 900),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        currentUserStreamProvider.overrideWith(
          (_) => Stream<AppUser?>.value(
            const AppUser(uid: 'u-1', email: 'user@example.com'),
          ),
        ),
      ],
      child: MaterialApp(
        theme: buildLightTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => DeleteAccountDialog.show(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  group('DeleteAccountDialog — step 1 semantics', () {
    testWidgets(
      'title + body + Cancel + Continue announce with distinct labels',
      (tester) async {
        await _pumpDialog(
          tester,
          repo: FakeAuthRepository(
            currentUserOverride: const AppUser(
              uid: 'u-1',
              email: 'user@example.com',
            ),
          ),
        );

        // Title — destructive intent must be unambiguous.
        expect(
          find.text('Delete account?'),
          findsOneWidget,
          reason:
              'Step 1 title must include the question mark — "delete '
              'account" alone reads imperative, not confirmational.',
        );
        // Body — communicates irreversibility.
        expect(
          find.textContaining('permanently deletes your account'),
          findsOneWidget,
        );

        // Cancel button — non-destructive role.
        final cancel = tester.getSemantics(
          find.widgetWithText(TextButton, 'Cancel'),
        );
        expect(cancel.label, equals('Cancel'));
        expect(cancel.hasFlag(SemanticsFlag.isButton), isTrue);

        // Continue button — destructive intent advances to step 2.
        // FilledButton role is the visual weight; the label IS the verb.
        final cont = tester.getSemantics(
          find.widgetWithText(FilledButton, 'Continue'),
        );
        expect(cont.label, equals('Continue'));
        expect(cont.hasFlag(SemanticsFlag.isButton), isTrue);
      },
    );
  });

  group('DeleteAccountDialog — step 2 semantics', () {
    testWidgets(
      'password field is obscured + Delete-forever button announces correctly',
      (tester) async {
        await _pumpDialog(
          tester,
          repo: FakeAuthRepository(
            currentUserOverride: const AppUser(
              uid: 'u-1',
              email: 'user@example.com',
            ),
          ),
        );

        // Advance to step 2.
        await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
        await tester.pumpAndSettle();

        // Title clarifies the why ("for your security").
        expect(find.text('Confirm your password'), findsOneWidget);
        expect(
          find.textContaining('For your security'),
          findsOneWidget,
          reason: 'Step 2 body must explain why password is requested.',
        );

        // Password field obscured — critical for shoulder-surfing
        // protection. The screen reader announces "password, edit text"
        // but never the characters themselves.
        final field = tester.widget<TextField>(find.byType(TextField));
        expect(
          field.obscureText,
          isTrue,
          reason: 'Password field MUST be obscured.',
        );

        // Delete-forever button — destructive role. The dialog uses
        // FilledButton with error-toned background for visual weight;
        // the semantic label IS the verb so screen readers announce
        // "Delete forever, button" with no ambiguity.
        final delete = tester.getSemantics(
          find.widgetWithText(FilledButton, 'Delete forever'),
        );
        expect(delete.label, equals('Delete forever'));
        expect(delete.hasFlag(SemanticsFlag.isButton), isTrue);

        // Cancel keeps the escape hatch reachable.
        expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
      },
    );
  });

  group('DeleteAccountDialog — 200% type readability', () {
    testWidgets('step 1 renders without RenderFlex overflow at 200% type', (
      tester,
    ) async {
      final exceptions = <Object>[];
      FlutterError.onError = (details) => exceptions.add(details.exception);
      addTearDown(() => FlutterError.onError = FlutterError.dumpErrorToConsole);

      await _pumpDialog(
        tester,
        repo: FakeAuthRepository(
          currentUserOverride: const AppUser(
            uid: 'u-1',
            email: 'user@example.com',
          ),
        ),
        textScaler: const TextScaler.linear(2.0),
        // Tablet width keeps the two action buttons on one Row at 2x.
        surfaceSize: const Size(600, 900),
      );

      final overflows = exceptions
          .map((e) => e.toString())
          .where((s) => s.contains('overflowed') || s.contains('RenderFlex'))
          .toList();
      expect(
        overflows,
        isEmpty,
        reason: 'Step 1 dialog must not overflow at 200% type. Got: $overflows',
      );
    });

    testWidgets('step 2 renders without RenderFlex overflow at 200% type', (
      tester,
    ) async {
      final exceptions = <Object>[];
      FlutterError.onError = (details) => exceptions.add(details.exception);
      addTearDown(() => FlutterError.onError = FlutterError.dumpErrorToConsole);

      await _pumpDialog(
        tester,
        repo: FakeAuthRepository(
          currentUserOverride: const AppUser(
            uid: 'u-1',
            email: 'user@example.com',
          ),
        ),
        textScaler: const TextScaler.linear(2.0),
        surfaceSize: const Size(600, 900),
      );

      // Advance to step 2 at 200% type. The password field + spinner
      // are the overflow risk zone.
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();

      final overflows = exceptions
          .map((e) => e.toString())
          .where((s) => s.contains('overflowed') || s.contains('RenderFlex'))
          .toList();
      expect(
        overflows,
        isEmpty,
        reason: 'Step 2 dialog must not overflow at 200% type. Got: $overflows',
      );

      // Sanity — both load-bearing controls remain on screen.
      expect(find.byType(TextField), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Delete forever'),
        findsOneWidget,
      );
    });
  });
}
