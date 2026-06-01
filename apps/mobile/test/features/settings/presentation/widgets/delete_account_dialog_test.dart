import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/auth_failure.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/settings/presentation/widgets/delete_account_dialog.dart';

import '../../../auth/domain/fakes/fake_auth_repository.dart';

/// Pumps a tiny harness that opens [DeleteAccountDialog] on first
/// frame. Returns a future that completes when the dialog is closed.
/// Tests inspect [repo]'s call counters after each user gesture.
Future<void> _pumpDialog(
  WidgetTester tester, {
  required FakeAuthRepository repo,
}) async {
  await tester.binding.setSurfaceSize(const Size(420, 900));
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
  group('DeleteAccountDialog - step 1 (confirm intent)', () {
    testWidgets('renders title, body, Cancel and Continue buttons', (
      tester,
    ) async {
      await _pumpDialog(tester, repo: FakeAuthRepository());

      expect(find.text('Delete account?'), findsOneWidget);
      expect(
        find.textContaining('permanently deletes your account'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
    });

    testWidgets('Cancel closes the dialog without calling the use case', (
      tester,
    ) async {
      final repo = FakeAuthRepository(
        currentUserOverride: const AppUser(
          uid: 'u-1',
          email: 'user@example.com',
        ),
      );
      await _pumpDialog(tester, repo: repo);

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Delete account?'), findsNothing);
      expect(repo.reauthenticateCalls, isEmpty);
      expect(repo.deleteAccountCalls, equals(0));
      expect(repo.signOutCalls, equals(0));
    });

    testWidgets('Continue advances to step 2', (tester) async {
      await _pumpDialog(
        tester,
        repo: FakeAuthRepository(
          currentUserOverride: const AppUser(
            uid: 'u-1',
            email: 'user@example.com',
          ),
        ),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm your password'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Delete forever'),
        findsOneWidget,
      );
    });
  });

  group('DeleteAccountDialog - step 2 (reauth + final confirm)', () {
    Future<void> goToStep2(
      WidgetTester tester, {
      required FakeAuthRepository repo,
    }) async {
      await _pumpDialog(tester, repo: repo);
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'Delete-forever button disabled when password < 6 chars; enabled at >= 6',
      (tester) async {
        final repo = FakeAuthRepository(
          currentUserOverride: const AppUser(
            uid: 'u-1',
            email: 'user@example.com',
          ),
        );
        await goToStep2(tester, repo: repo);

        final deleteButtonFinder = find.widgetWithText(
          FilledButton,
          'Delete forever',
        );

        // Initial: empty password → disabled.
        FilledButton button = tester.widget<FilledButton>(deleteButtonFinder);
        expect(button.onPressed, isNull);

        // 5 chars → still disabled.
        await tester.enterText(find.byType(TextField), '12345');
        await tester.pump();
        button = tester.widget<FilledButton>(deleteButtonFinder);
        expect(button.onPressed, isNull);

        // 6 chars → enabled.
        await tester.enterText(find.byType(TextField), '123456');
        await tester.pump();
        button = tester.widget<FilledButton>(deleteButtonFinder);
        expect(button.onPressed, isNotNull);
      },
    );

    testWidgets('wrong password - inline error shown, dialog stays open', (
      tester,
    ) async {
      final repo = FakeAuthRepository(
        currentUserOverride: const AppUser(
          uid: 'u-1',
          email: 'user@example.com',
        ),
        reauthenticateResult: const Err(AuthFailure.wrongPassword()),
      );
      await goToStep2(tester, repo: repo);

      await tester.enterText(find.byType(TextField), 'badpass');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete forever'));
      await tester.pumpAndSettle();

      // Dialog still open - title visible.
      expect(find.text('Confirm your password'), findsOneWidget);
      // Inline error visible.
      expect(find.textContaining('did not match'), findsOneWidget);
      // No destructive call past reauth.
      expect(repo.reauthenticateCalls, hasLength(1));
      expect(repo.deleteAccountCalls, equals(0));
      expect(repo.signOutCalls, equals(0));
    });

    testWidgets(
      'happy path - use case called once, signOut triggered, dialog closes',
      (tester) async {
        final repo = FakeAuthRepository(
          currentUserOverride: const AppUser(
            uid: 'u-1',
            email: 'user@example.com',
          ),
        );
        await goToStep2(tester, repo: repo);

        await tester.enterText(find.byType(TextField), 'goodpass');
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Delete forever'));
        await tester.pumpAndSettle();

        // Use case orchestration ran through all four steps.
        expect(repo.reauthenticateCalls, hasLength(1));
        expect(repo.deleteAccountCalls, equals(1));
        expect(repo.deleteCurrentUserCalls, equals(1));
        expect(repo.signOutCalls, equals(1));
        // Dialog closed.
        expect(find.text('Confirm your password'), findsNothing);
      },
    );
  });
}
