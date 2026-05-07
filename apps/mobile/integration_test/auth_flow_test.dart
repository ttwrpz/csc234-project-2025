import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/auth_failure.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';

import 'app_harness.dart';
import 'fakes.dart';

/// Sign-in flow integration test. Drives the production [SignInScreen]
/// through real text input + button taps and asserts the router lands on
/// `/home` afterwards. Sign-out from Settings rolls the user back to
/// `/sign-in`. Bad creds surface the failure message inline without
/// transitioning.
///
/// Must pass on Android emulator AND `flutter test integration_test/auth_flow_test.dart -d chrome`
/// per WBS 7.3 acceptance. Web parity is part of the Sprint 5 cross-platform
/// QA matrix.
///
/// Conflict-resolution note (post-#25 + post-#34 rebase, 2026-05-08):
/// PR #25 replaced the file-local `_IntegrationAuthRepository` with the
/// shared `IntegrationAuthRepository` in `fakes.dart`. PR #34's stub
/// additions for `reauthenticate` + `deleteAccount` therefore live in
/// `fakes.dart::IntegrationAuthRepository` instead of here.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth flow', () {
    late IntegrationAuthRepository authRepo;

    setUp(() async {
      seedOnboardingComplete();
      authRepo = IntegrationAuthRepository();
    });

    tearDown(() async {
      await authRepo.dispose();
    });

    testWidgets('cold start with no user → /sign-in renders the email form', (
      tester,
    ) async {
      final defaults = await defaultIntegrationOverrides();
      addTearDown(() async => defaults.syncManager.dispose());

      await pumpHarness(
        tester,
        overrides: [
          ...defaults.overrides,
          authRepositoryProvider.overrideWithValue(authRepo),
        ],
      );

      // The /sign-in screen is anchored by its email field — any future
      // copy change updates this and the SignInScreen widget test in
      // lockstep.
      expect(
        find.byType(TextField),
        findsAtLeastNWidgets(1),
        reason: 'sign-in form must render at least the email field',
      );
      expect(
        find.text('Sign in'),
        findsWidgets,
        reason: 'sign-in primary button label must be present',
      );
    });

    testWidgets('valid creds → router lands on /home', (tester) async {
      final defaults = await defaultIntegrationOverrides();
      addTearDown(() async => defaults.syncManager.dispose());

      await pumpHarness(
        tester,
        overrides: [
          ...defaults.overrides,
          authRepositoryProvider.overrideWithValue(authRepo),
        ],
      );

      // Type valid creds into the email + password fields.
      final fields = find.byType(TextField);
      expect(fields, findsAtLeastNWidgets(2));
      await tester.enterText(fields.at(0), 'user@example.com');
      await tester.enterText(fields.at(1), 'password123');
      await tester.pumpAndSettle();

      // Tap "Sign in".
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();

      // The fake repo records the call and flips its auth-state stream;
      // the router's refreshListenable picks up the user and redirects
      // /sign-in → /home.
      expect(
        authRepo.signInCalls,
        hasLength(1),
        reason: 'submit button must invoke signInWithEmail exactly once',
      );
      expect(
        authRepo.signInCalls.single.email,
        equals('user@example.com'),
        reason: 'submitted email must be passed to the repo verbatim',
      );
      // The /sign-in tagline is the load-bearing post-condition: if it is
      // gone, the router has redirected away from /sign-in. Avoiding a
      // direct match on /home content keeps this test resilient to home
      // screen copy changes.
      expect(
        find.text('Sign in to tend your garden'),
        findsNothing,
        reason: 'after a successful sign-in the /sign-in tagline must be gone',
      );
    });

    testWidgets('bad creds → inline error, no transition', (tester) async {
      final defaults = await defaultIntegrationOverrides();
      addTearDown(() async => defaults.syncManager.dispose());

      // Wire the next sign-in call to fail with wrong-password — the
      // production fake repo returns the canned message verbatim.
      authRepo.nextSignInResult = const Err(AuthFailure.wrongPassword());

      await pumpHarness(
        tester,
        overrides: [
          ...defaults.overrides,
          authRepositoryProvider.overrideWithValue(authRepo),
        ],
      );

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'user@example.com');
      await tester.enterText(fields.at(1), 'password123');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();

      expect(
        authRepo.signInCalls,
        hasLength(1),
        reason: 'submit must call repo even on the failure path',
      );
      // Stayed on sign-in (the screen tagline is still visible) and the
      // wrong-password message is rendered.
      expect(
        find.text('Sign in to tend your garden'),
        findsOneWidget,
        reason: 'screen must NOT transition on a failed sign-in',
      );
      expect(
        find.text('Email and password do not match our records.'),
        findsOneWidget,
        reason:
            'the AuthFailure.wrongPassword message must surface inline below '
            'the password field',
      );
    });

    testWidgets('Sign out from Settings → router returns to /sign-in', (
      tester,
    ) async {
      final defaults = await defaultIntegrationOverrides();
      addTearDown(() async => defaults.syncManager.dispose());

      // Pre-seed a signed-in user so we land on /home directly.
      authRepo.setUser(
        const AppUser(uid: 'u-existing', email: 'user@example.com'),
      );

      await pumpHarness(
        tester,
        overrides: [
          ...defaults.overrides,
          authRepositoryProvider.overrideWithValue(authRepo),
        ],
      );

      // Navigate to Settings via the bottom nav. The label "Settings"
      // is rendered by the MbBottomNavItem.
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Tap the destructive sign-out row. Two "Sign out" texts are now
      // in the tree (the row label + the dialog confirm action); the
      // first one is the row tile.
      await tester.tap(find.text('Sign out').first);
      await tester.pumpAndSettle();
      // Confirm dialog has its own "Sign out" filled action.
      await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
      await tester.pumpAndSettle();

      // Auth-state flipped to null; router redirects /settings → /sign-in.
      expect(
        find.text('Sign in to tend your garden'),
        findsOneWidget,
        reason: 'after sign-out the user must be back on /sign-in',
      );
    });
  });
}
