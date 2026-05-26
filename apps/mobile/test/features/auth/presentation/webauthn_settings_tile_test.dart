// Widget tests for [WebauthnSettingsTile] — ADR-0014 Decision D.
//
// The build-time `kEnableWebauthn` const and `kIsWeb` short-circuit
// through `webauthnAvailableProvider`. The tests override that provider
// to `true` to reach the interactive path without needing a real web
// build target.

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/auth/domain/entities/webauthn_credential.dart';
import 'package:moodbloom/features/auth/domain/entities/webauthn_register_failure.dart';
import 'package:moodbloom/features/auth/presentation/widgets/webauthn_settings_tile.dart';

import '../domain/fakes/fake_webauthn_repository.dart';

Future<void> _pump(
  WidgetTester tester, {
  required FakeWebauthnRepository repo,
  AppUser? user = const AppUser(uid: 'u-1', email: 'u@example.com'),
  bool available = true,
}) async {
  await tester.binding.setSurfaceSize(const Size(420, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  // The tile uses `context.go('/privacy/setup')` on the pinRequired
  // failure branch, so we wrap in a minimal GoRouter so that call doesn't
  // throw `No GoRouter found in context`.
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) =>
            const Scaffold(body: SafeArea(child: WebauthnSettingsTile())),
      ),
      GoRoute(
        path: '/privacy/setup',
        builder: (_, _) => const Scaffold(body: Text('PRIVACY-SETUP')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        webauthnAvailableProvider.overrideWithValue(available),
        webauthnRepositoryProvider.overrideWithValue(repo),
        currentUserStreamProvider.overrideWith(
          (_) => Stream<AppUser?>.value(user),
        ),
      ],
      child: MaterialApp.router(theme: buildLightTheme(), routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('WebauthnSettingsTile', () {
    testWidgets(
      'tap on "Set up a security key" invokes register use case with the current uid',
      (tester) async {
        final repo = FakeWebauthnRepository();
        await _pump(tester, repo: repo);

        // The no-credential state shows the "Set up a security key" CTA.
        final cta = find.text('Set up a security key');
        expect(cta, findsOneWidget);

        await tester.tap(cta);
        await tester.pumpAndSettle();

        expect(repo.registerCalls, ['u-1']);
      },
    );

    testWidgets('pinRequired failure routes to /privacy/setup', (tester) async {
      final repo = FakeWebauthnRepository(
        registerResult: const Err(WebauthnRegisterFailure.pinRequired()),
      );
      await _pump(tester, repo: repo);

      await tester.tap(find.text('Set up a security key'));
      // Drain the async + the GoRouter navigation.
      await tester.pumpAndSettle();

      // The sentinel screen on /privacy/setup must be visible — that
      // proves `context.go('/privacy/setup')` actually fired.
      expect(find.text('PRIVACY-SETUP'), findsOneWidget);
    });

    testWidgets('userCanceled failure is silent (no snackbar)', (tester) async {
      final repo = FakeWebauthnRepository(
        registerResult: const Err(WebauthnRegisterFailure.userCanceled()),
      );
      await _pump(tester, repo: repo);

      await tester.tap(find.text('Set up a security key'));
      await tester.pumpAndSettle();

      // Snackbar copy from `WebauthnRegisterFailure.userCanceled` is
      // "Security key setup canceled." — the silent contract means this
      // text never appears.
      expect(find.textContaining('canceled'), findsNothing);
    });

    testWidgets(
      'disabled state renders when webauthnAvailableProvider is false',
      (tester) async {
        await _pump(tester, repo: FakeWebauthnRepository(), available: false);

        // Subtitle copy differs between off-web and on-web-flag-off; one
        // of them must render.
        final hasWebOnly = find
            .textContaining('Web only')
            .evaluate()
            .isNotEmpty;
        final hasComing = find
            .textContaining('Coming in a future release')
            .evaluate()
            .isNotEmpty;
        expect(
          hasWebOnly || hasComing,
          isTrue,
          reason: 'disabled state must render a friendly subtitle',
        );
      },
    );

    testWidgets(
      'registered credential renders "Security key registered" with date',
      (tester) async {
        final repo = FakeWebauthnRepository(
          credential: WebauthnCredential(
            credentialId: 'cred-1',
            createdAt: DateTime.utc(2026, 5, 15),
          ),
        );
        await _pump(tester, repo: repo);

        expect(find.text('Security key registered'), findsOneWidget);
        expect(find.textContaining('May 15'), findsOneWidget);
      },
    );
  });
}
