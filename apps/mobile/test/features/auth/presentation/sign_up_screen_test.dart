import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/auth/presentation/sign_up_screen.dart';

import '../domain/fakes/fake_auth_repository.dart';

Future<void> _pumpSignUp(
  WidgetTester tester, {
  required FakeAuthRepository repo,
}) async {
  await tester.binding.setSurfaceSize(const Size(420, 1300));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        currentUserStreamProvider.overrideWith(
          (_) => Stream<AppUser?>.value(null),
        ),
      ],
      child: MaterialApp(theme: buildLightTheme(), home: const SignUpScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('SignUpScreen', () {
    testWidgets(
      'mismatched passwords surface inline error and skip the repo call',
      (tester) async {
        final repo = FakeAuthRepository();
        await _pumpSignUp(tester, repo: repo);

        // Field order: email, password, confirm-password.
        await tester.enterText(find.byType(TextField).at(0), 'u@example.com');
        await tester.enterText(find.byType(TextField).at(1), 'longenoughpw');
        await tester.enterText(find.byType(TextField).at(2), 'something-else');

        await tester.tap(find.widgetWithText(MbPrimaryButton, 'Create account'));
        await tester.pumpAndSettle();

        // Hard-coded message from sign_up_controller.dart line 28.
        expect(find.text('Passwords do not match.'), findsOneWidget);
        expect(
          repo.registerCalls,
          isEmpty,
          reason: 'mismatch must short-circuit before calling the repository',
        );
      },
    );

    testWidgets(
      'matching passwords invoke RegisterWithEmailUseCase against the repo',
      (tester) async {
        final repo = FakeAuthRepository(
          registerResult: const Ok(AppUser(uid: 'u-1', email: 'u@example.com')),
        );
        await _pumpSignUp(tester, repo: repo);

        await tester.enterText(find.byType(TextField).at(0), 'u@example.com');
        await tester.enterText(find.byType(TextField).at(1), 'longenoughpw');
        await tester.enterText(find.byType(TextField).at(2), 'longenoughpw');

        await tester.tap(find.widgetWithText(MbPrimaryButton, 'Create account'));
        await tester.pumpAndSettle();

        expect(
          repo.registerCalls,
          hasLength(1),
          reason: 'matching credentials must reach the register use case',
        );
        expect(repo.registerCalls.single.email, equals('u@example.com'));
        expect(repo.registerCalls.single.password, equals('longenoughpw'));
      },
    );

    testWidgets('tapping Continue with Google invokes SignInWithGoogleUseCase', (
      tester,
    ) async {
      final repo = FakeAuthRepository(
        googleResult: const Ok(AppUser(uid: 'u-1', email: 'u@example.com')),
      );
      await _pumpSignUp(tester, repo: repo);

      // The Google button is rendered via GoogleSignInButton which uses
      // an OutlinedButton.icon under the hood; locating by label text
      // matches the sign_in_screen_test pattern.
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(
        repo.googleCalls,
        equals(1),
        reason:
            'tapping the Google button on sign-up must call the Google use case',
      );
    });
  });
}
