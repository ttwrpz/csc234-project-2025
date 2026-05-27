import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/auth/presentation/sign_in_screen.dart';

import '../domain/fakes/fake_auth_repository.dart';

/// Pumps [SignInScreen] under a [ProviderScope] with [authRepositoryProvider]
/// overridden by [repo]. The router's auth-state listener is short-circuited
/// by overriding [currentUserStreamProvider] with a stream that only emits
/// `null` so we never accidentally drive a redirect.
Future<void> _pumpSignIn(
  WidgetTester tester, {
  required FakeAuthRepository repo,
}) async {
  // Tall surface so every ListView item lays out at once. The default
  // 800×600 viewport clips the Google sign-in button below the fold.
  await tester.binding.setSurfaceSize(const Size(420, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        currentUserStreamProvider.overrideWith(
          (_) => Stream<AppUser?>.value(null),
        ),
      ],
      child: MaterialApp(theme: buildLightTheme(), home: const SignInScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('SignInScreen', () {
    testWidgets('renders email field, password field, and core actions', (
      tester,
    ) async {
      await _pumpSignIn(tester, repo: FakeAuthRepository());

      // Two AuthTextFields (email + password) render two underlying TextFields.
      expect(
        find.byType(TextField),
        findsNWidgets(2),
        reason: 'sign-in form must expose exactly two text fields',
      );
      // Labels are rendered inside MbInputField as upper-cased dim text.
      expect(find.text('EMAIL'), findsOneWidget);
      expect(find.text('PASSWORD'), findsOneWidget);
      // Primary action.
      expect(find.widgetWithText(MbPrimaryButton, 'Sign in'), findsOneWidget);
      // Footer link (v1.6: prompt + action split across two TextSpans
      // inside a Text.rich; `find.text` does not descend into
      // TextSpans). Walk the RichText widgets and match on the
      // composed plain text - "Create one" is the action verb.
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && (w.text.toPlainText()).contains('Create one'),
        ),
        findsOneWidget,
      );
      // Google button is shown on non-Web (kIsWeb is false in flutter_test).
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets(
      'submitting empty form surfaces inline error and does not call repo',
      (tester) async {
        final repo = FakeAuthRepository();
        await _pumpSignIn(tester, repo: repo);

        await tester.tap(find.widgetWithText(MbPrimaryButton, 'Sign in'));
        await tester.pumpAndSettle();

        // The use case rejects an empty email before hitting the repo.
        expect(
          repo.signInCalls,
          isEmpty,
          reason: 'invalid email must short-circuit before reaching the repo',
        );
        // Error copy comes from AuthFailure.invalidEmail.message.
        expect(find.text('That email address looks off.'), findsOneWidget);
      },
    );

    testWidgets(
      'valid input invokes SignInWithEmailUseCase against the repository',
      (tester) async {
        final repo = FakeAuthRepository(
          signInResult: const Ok(AppUser(uid: 'u-1', email: 'u@example.com')),
        );
        await _pumpSignIn(tester, repo: repo);

        // Fill email and password through the TextFields.
        await tester.enterText(find.byType(TextField).at(0), 'u@example.com');
        await tester.enterText(find.byType(TextField).at(1), 'longenoughpw');
        await tester.tap(find.widgetWithText(MbPrimaryButton, 'Sign in'));
        await tester.pumpAndSettle();

        expect(
          repo.signInCalls,
          hasLength(1),
          reason: 'controller must forward valid input to the repository',
        );
        expect(repo.signInCalls.single.email, equals('u@example.com'));
        expect(repo.signInCalls.single.password, equals('longenoughpw'));
      },
    );

    testWidgets(
      'tapping Continue with Google invokes SignInWithGoogleUseCase',
      (tester) async {
        final repo = FakeAuthRepository(
          googleResult: const Ok(AppUser(uid: 'u-1', email: 'u@example.com')),
        );
        await _pumpSignIn(tester, repo: repo);

        // Use OutlinedButton + label text — the GoogleSignInButton uses
        // OutlinedButton.icon under the hood.
        await tester.tap(find.text('Continue with Google'));
        await tester.pumpAndSettle();

        expect(
          repo.googleCalls,
          equals(1),
          reason: 'tapping the Google button must call the Google use case',
        );
      },
    );
  });
}
