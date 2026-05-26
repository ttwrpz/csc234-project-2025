// Widget tests for the "Use security key" affordance on
// [PrivacyLockScreen] — ADR-0014 Decision D.
//
// The button appears only when WebAuthn is reachable AND the user has
// a credential registered (via `webauthnCredentialProvider`). The test
// overrides both providers; on tap, the use case is invoked through a
// `FakeWebauthnRepository` and we assert the session unlock flag flips.

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/auth/domain/entities/biometric_capability.dart';
import 'package:moodbloom/features/auth/domain/entities/webauthn_credential.dart';
import 'package:moodbloom/features/auth/domain/entities/webauthn_verify_failure.dart';
import 'package:moodbloom/features/auth/presentation/screens/privacy_lock_screen.dart';

import '../domain/fakes/fake_webauthn_repository.dart';

Future<void> _pumpPrivacyLock(
  WidgetTester tester, {
  required FakeWebauthnRepository repo,
  bool webauthnAvailable = true,
  WebauthnCredential? credential,
}) async {
  await tester.binding.setSurfaceSize(const Size(420, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  // The screen pushes via `context.go` on unlock, so we wrap in a
  // GoRouter with a no-op destination. The router config is the
  // smallest viable surface to satisfy `context.go(...)`.
  final router = GoRouter(
    initialLocation: '/privacy-lock',
    routes: [
      GoRoute(
        path: '/privacy-lock',
        builder: (_, _) => const PrivacyLockScreen(returnTo: '/home'),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('HOME-PUMP'))),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (_, _) => const Scaffold(body: Text('SIGN-IN')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // `Stream.value` emits via a microtask; one `tester.pump()`
        // after `pumpWidget` drains it. The prior version of this
        // helper used a StreamController that deadlocked when
        // `.close()` raced with a Riverpod listener during the
        // post-frame callback chain on the privacy-lock screen.
        currentUserStreamProvider.overrideWith(
          (_) => Stream<AppUser?>.value(
            const AppUser(uid: 'u-1', email: 'u@example.com'),
          ),
        ),
        biometricCapabilityProvider.overrideWith(
          (ref) async => const BiometricCapability(
            isAvailable: false,
            hasEnrolledBiometrics: false,
            userOptedIn: false,
          ),
        ),
        webauthnAvailableProvider.overrideWithValue(webauthnAvailable),
        webauthnCredentialProvider.overrideWith(
          (_) => Stream<WebauthnCredential?>.value(credential),
        ),
        webauthnRepositoryProvider.overrideWithValue(repo),
      ],
      child: Consumer(
        // Eagerly subscribe to `currentUserStreamProvider` so the
        // underlying `Stream.value` source starts emitting before the
        // screen's event handlers reach for `ref.read(...).value`.
        // Without this consumer the provider is never observed (the
        // screen only `.read`s the user inside callbacks), so the
        // stream subscription never starts and the AsyncValue stays
        // in the loading state.
        builder: (context, ref, child) {
          ref.watch(currentUserStreamProvider);
          return child!;
        },
        child: MaterialApp.router(
          theme: buildLightTheme(),
          routerConfig: router,
        ),
      ),
    ),
  );
  // Drain the StreamProvider microtasks (user + credential) and let
  // the FutureProvider for biometric capability resolve. Each pump
  // covers one microtask boundary; we run several because the
  // post-frame `_tryBiometric()` reads the capability provider and
  // toggles `_biometricInProgress` which the build branches against.
  // The async FutureProvider override for biometric capability also
  // needs an extra tick to land in cache, and the StreamProvider for
  // the user needs a `runAsync` boundary so the inner `Stream.value`
  // microtask completes before the next `ref.read(...).value`.
  await tester.pump();
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  });
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

void main() {
  group('PrivacyLockScreen — Use security key', () {
    testWidgets('button appears when webauthnAvailable && credential != null', (
      tester,
    ) async {
      await _pumpPrivacyLock(
        tester,
        repo: FakeWebauthnRepository(),
        webauthnAvailable: true,
        credential: WebauthnCredential(
          credentialId: 'cred-1',
          createdAt: DateTime.utc(2026, 5, 15),
        ),
      );

      expect(find.text('Use security key'), findsOneWidget);
    });

    testWidgets('button is absent when no credential is registered', (
      tester,
    ) async {
      await _pumpPrivacyLock(
        tester,
        repo: FakeWebauthnRepository(),
        webauthnAvailable: true,
        credential: null,
      );

      expect(find.text('Use security key'), findsNothing);
    });

    testWidgets('button is absent when webauthnAvailable is false', (
      tester,
    ) async {
      await _pumpPrivacyLock(
        tester,
        repo: FakeWebauthnRepository(),
        webauthnAvailable: false,
        credential: WebauthnCredential(
          credentialId: 'cred-1',
          createdAt: DateTime.utc(2026, 5, 15),
        ),
      );

      expect(find.text('Use security key'), findsNothing);
    });

    testWidgets(
      'tap dispatches verify use case and unlocks the session on Ok',
      (tester) async {
        final repo = FakeWebauthnRepository(
          verifyResult: const Ok<void, WebauthnVerifyFailure>(null),
        );
        await _pumpPrivacyLock(
          tester,
          repo: repo,
          webauthnAvailable: true,
          credential: WebauthnCredential(
            credentialId: 'cred-1',
            createdAt: DateTime.utc(2026, 5, 15),
          ),
        );
        // Find the security-key TextButton ancestor of the label text.
        // Calling `onPressed` directly (rather than via `tester.tap`)
        // avoids the off-screen hit-test ambiguity that
        // TextButton.icon's nested _TextButtonWithIcon layout exposes
        // under the 420×1200 surface — the tap target's exact bounds
        // depend on the icon-plus-label flex resolution. The handler
        // is a plain Dart callback; invoking it directly exercises the
        // same code path and asserts the use case is dispatched.
        final button = find.ancestor(
          of: find.text('Use security key'),
          matching: find.byType(TextButton),
        );
        expect(button, findsOneWidget);
        final btnWidget = tester.widget<TextButton>(button);
        expect(
          btnWidget.onPressed,
          isNotNull,
          reason: 'security-key button must be enabled before invocation',
        );
        btnWidget.onPressed!();
        // Drain the use-case Future. The fake records the call
        // synchronously at the top of `verify()`, so a single pump is
        // enough to surface the dispatched call. We then run a few
        // more pumps so the post-unlock `context.go('/home')`
        // navigation has time to settle.
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 10));
        }

        expect(repo.verifyCalls, ['u-1']);
        // Verify navigated to /home (the unlock-then-go path).
        expect(find.text('HOME-PUMP'), findsOneWidget);
      },
    );
  });
}
