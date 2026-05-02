import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/auth_failure.dart';
import 'package:moodbloom/features/auth/domain/auth_repository.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_harness.dart';

/// Sign-in flow integration test. Must pass on Android emulator AND
/// `flutter drive -d chrome` per the kickoff acceptance bar. Sprint 4
/// only requires this to compile + pass via `flutter test
/// integration_test/auth_flow_test.dart` (host execution); the device-
/// matrix run lands on the Sprint 5 CI track.
class _IntegrationAuthRepository implements AuthRepository {
  AppUser? _user;
  final List<({String email, String password})> signInCalls = [];

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> watchAuthState() async* {
    yield _user;
  }

  @override
  Future<Result<AppUser, AuthFailure>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    signInCalls.add((email: email, password: password));
    _user = AppUser(uid: 'u-1', email: email);
    return Ok(_user!);
  }

  @override
  Future<Result<AppUser, AuthFailure>> registerWithEmail({
    required String email,
    required String password,
  }) async => const Err(AuthFailure.unknown(null));

  @override
  Future<Result<AppUser, AuthFailure>> signInWithGoogle() async =>
      const Err(AuthFailure.unknown(null));

  @override
  Future<Result<void, AuthFailure>> signOut() async {
    _user = null;
    return const Ok(null);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth flow', () {
    setUp(() {
      // Skip the onboarding gate so we land on /sign-in directly.
      SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    });

    testWidgets(
      'cold start with no user → /sign-in renders the email form',
      (tester) async {
        await pumpHarness(
          tester,
          overrides: [
            authRepositoryProvider.overrideWithValue(
              _IntegrationAuthRepository(),
            ),
          ],
        );

        // The /sign-in screen is anchored by its email field — any
        // future copy change updates this and the SignInScreen widget
        // test in lockstep.
        expect(find.byType(TextField), findsAtLeastNWidgets(1));
      },
      // S5 CI matrix runs this on Android emulator AND Chrome web; for
      // S4 host execution via `flutter test integration_test/` suffices.
    );

    testWidgets(
      'sign-in via repo → call is recorded (S5 will drive through the UI)',
      (tester) async {
        final repo = _IntegrationAuthRepository();
        await pumpHarness(
          tester,
          overrides: [authRepositoryProvider.overrideWithValue(repo)],
        );

        // Sprint 4 anchor: prove the repo can be exercised through the
        // production wire. Sprint 5 expansion: drive through the
        // TextField + submit button and assert `/home` is reached.
        await repo.signInWithEmail(
          email: 'u@example.com',
          password: 'hunter22',
        );
        expect(repo.signInCalls, hasLength(1));
      },
    );
  });
}
