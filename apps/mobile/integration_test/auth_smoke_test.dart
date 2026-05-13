import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';

import 'app_harness.dart';
import 'fakes.dart';

/// WBS 8.3 Test 1 — smoke test for the auth surface.
///
/// Verifies that the harness boots, the router renders the sign-in form
/// when the auth-state stream is null, and the router redirects to
/// `/home` once a signed-in [AppUser] reaches the stream. Sign-out flips
/// the stream back to null and the router returns to `/sign-in`.
///
/// Companion to the older `auth_flow_test.dart` (PR #25 + #34) — that
/// file drove the same surface through real text input and a failure
/// path. This smoke variant focuses on the harness contract (do
/// provider overrides + the [IntegrationAuthRepository] state-changes
/// flow through the router on the first frame?) and the sign-up route
/// renders without crashing on a cold tree.
///
/// Domain purity: tests-only file; touches no production code. The
/// [IntegrationAuthRepository] + [defaultIntegrationOverrides] do all
/// the wiring; the test asserts on visible signals only.
///
/// **Web parity:** the harness is platform-agnostic. The Day-4
/// cross-platform run drives the same file on `-d chrome`; for Day 3
/// (this work) the `flutter test` harness target is enough to assert
/// the wiring is correct (per the kickoff "Day 3 vs Day 4" split).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth smoke (WBS 8.3 — Test 1)', () {
    late IntegrationAuthRepository authRepo;

    setUp(() async {
      seedOnboardingComplete();
      authRepo = IntegrationAuthRepository();
    });

    tearDown(() async {
      await authRepo.dispose();
    });

    testWidgets('cold-start with no user lands on /sign-in', (tester) async {
      final defaults = await defaultIntegrationOverrides();
      addTearDown(() async => defaults.syncManager.dispose());

      await pumpHarness(
        tester,
        overrides: [
          ...defaults.overrides,
          authRepositoryProvider.overrideWithValue(authRepo),
        ],
      );

      // The sign-in tagline is the load-bearing anchor — if it's
      // present, the router resolved /sign-in correctly. Any future
      // copy change must update the SignInScreen widget test in
      // lockstep.
      expect(
        find.text('Sign in to tend your garden'),
        findsOneWidget,
        reason: 'cold-start with auth=null must render the /sign-in screen',
      );
      expect(
        find.byType(TextField),
        findsAtLeastNWidgets(2),
        reason: 'the email + password fields must render on first frame',
      );
    });

    testWidgets('pre-seeded user lands on /home immediately', (tester) async {
      final defaults = await defaultIntegrationOverrides();
      addTearDown(() async => defaults.syncManager.dispose());

      // Seed a signed-in user BEFORE pumping the harness so the very
      // first `currentUserStreamProvider` emission carries the user;
      // the router's redirect picks it up and lands on /home before
      // any `tester.pumpAndSettle` runs.
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

      // Absence of the /sign-in tagline is the load-bearing signal —
      // matches the "valid creds → /home" pattern from auth_flow_test.
      // Asserting the absence (vs. asserting on /home content) keeps
      // the smoke resilient to garden-screen copy churn.
      expect(
        find.text('Sign in to tend your garden'),
        findsNothing,
        reason:
            'with a pre-seeded user the router must redirect away from /sign-in',
      );
    });

    testWidgets('sign-out flips auth-state → back to /sign-in', (tester) async {
      final defaults = await defaultIntegrationOverrides();
      addTearDown(() async => defaults.syncManager.dispose());

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

      // Drive the auth transition manually — the production flow goes
      // through Settings, but for a smoke we exercise the router's
      // refreshListenable contract directly.
      authRepo.setUser(null);
      await tester.pumpAndSettle();

      expect(
        find.text('Sign in to tend your garden'),
        findsOneWidget,
        reason: 'auth-state → null must land the router back on /sign-in',
      );
    });

    testWidgets('navigates to /sign-up from /sign-in without crashing', (
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

      // SignInScreen has a "Create account" CTA that pushes /sign-up.
      // The route name is fixed; the visible label is the user-facing
      // anchor. Production wording: the SignInScreen renders a tap-
      // target with the text "Create account" near the bottom of the
      // form (see sign_in_screen.dart). We tap the first match and
      // assert the SignUpScreen primary CTA renders.
      final createAccount = find.text('Create account');
      expect(
        createAccount,
        findsAtLeastNWidgets(1),
        reason: 'sign-in must offer a "Create account" CTA',
      );
      await tester.tap(createAccount.first);
      await tester.pumpAndSettle();

      // SignUpScreen's primary button label is also "Create account"
      // (see sign_up_screen.dart). Two matches is the expected steady
      // state once we're on the sign-up route — the field, the
      // button. We assert at least one so the test does not depend on
      // the exact widget count.
      expect(
        find.text('Create account'),
        findsAtLeastNWidgets(1),
        reason: 'sign-up screen must render its primary submit CTA',
      );
      // The sign-up screen has a confirm-password field — three
      // TextFields total (email, password, confirm). This anchors the
      // route assertion without depending on a screen title.
      expect(
        find.byType(TextField),
        findsAtLeastNWidgets(3),
        reason:
            'sign-up form must render at least three text inputs '
            '(email, password, confirm password)',
      );
    });
  });
}
