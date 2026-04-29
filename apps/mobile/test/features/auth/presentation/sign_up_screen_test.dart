import 'package:core/core.dart';
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
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        currentUserStreamProvider.overrideWith(
          (_) => Stream<AppUser?>.value(null),
        ),
      ],
      child: const MaterialApp(home: SignUpScreen()),
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

        await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
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

        await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
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
  });
}
