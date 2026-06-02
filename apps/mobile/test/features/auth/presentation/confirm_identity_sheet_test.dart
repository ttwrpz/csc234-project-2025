// Widget tests for [ConfirmIdentitySheet] / showConfirmIdentitySheet.
//
// Each factor (security key, PIN, password) drives the sheet to a
// successful pop(true); cancel pops false. The factor use cases are wired
// to hand-rolled fakes via Riverpod overrides so no platform channel or
// real ceremony is touched.

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/auth/domain/entities/biometric_capability.dart';
import 'package:moodbloom/features/auth/domain/entities/webauthn_credential.dart';
import 'package:moodbloom/features/auth/presentation/widgets/confirm_identity_sheet.dart';

import '../domain/fakes/fake_auth_repository.dart';
import '../domain/fakes/fake_pin_repository.dart';
import '../domain/fakes/fake_webauthn_repository.dart';

const _cap = BiometricCapability(
  isAvailable: false,
  hasEnrolledBiometrics: false,
  userOptedIn: false,
);

WebauthnCredential _credential() => WebauthnCredential(
  credentialId: 'cred-1',
  createdAt: DateTime.utc(2026, 5),
);

/// Hosts a button that opens the sheet and records the bool it returns.
class _Host extends StatefulWidget {
  const _Host();
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool? result;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final r = await showConfirmIdentitySheet(context);
            setState(() => result = r);
          },
          child: const Text('open'),
        ),
      ),
    );
  }
}

Future<_HostState> _pump(
  WidgetTester tester, {
  required FakeWebauthnRepository webauthn,
  required FakePinRepository pin,
  required FakeAuthRepository auth,
  bool webauthnAvailable = false,
}) async {
  await tester.binding.setSurfaceSize(const Size(500, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserStreamProvider.overrideWith(
          (_) => Stream<AppUser?>.value(
            const AppUser(uid: 'u-1', email: 'u@example.com'),
          ),
        ),
        biometricCapabilityProvider.overrideWith((_) async => _cap),
        webauthnAvailableProvider.overrideWithValue(webauthnAvailable),
        webauthnRepositoryProvider.overrideWithValue(webauthn),
        pinRepositoryProvider.overrideWithValue(pin),
        authRepositoryProvider.overrideWithValue(auth),
      ],
      child: MaterialApp(theme: buildLightTheme(), home: const _Host()),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return tester.state<_HostState>(find.byType(_Host));
}

void main() {
  group('ConfirmIdentitySheet', () {
    testWidgets('security-key success pops true', (tester) async {
      final host = await _pump(
        tester,
        webauthn: FakeWebauthnRepository(credential: _credential()),
        pin: FakePinRepository(),
        auth: FakeAuthRepository(),
        webauthnAvailable: true,
      );

      expect(find.text("Confirm it's you"), findsOneWidget);
      // The factor buttons sit below the keypad in a scroll view; scroll
      // the target into view before tapping (a real user scrolls too).
      final keyBtn = find.text('Use security key');
      await tester.ensureVisible(keyBtn);
      await tester.pumpAndSettle();
      await tester.tap(keyBtn);
      await tester.pumpAndSettle();

      expect(host.result, isTrue);
    });

    testWidgets('correct PIN pops true', (tester) async {
      final host = await _pump(
        tester,
        webauthn: FakeWebauthnRepository(),
        pin: FakePinRepository(correctPin: '123456'),
        auth: FakeAuthRepository(),
      );

      for (final d in ['1', '2', '3', '4', '5', '6']) {
        await tester.tap(find.text(d));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(host.result, isTrue);
    });

    testWidgets('password success pops true', (tester) async {
      final host = await _pump(
        tester,
        webauthn: FakeWebauthnRepository(),
        pin: FakePinRepository(),
        // reauthenticate defaults to Ok in the fake.
        auth: FakeAuthRepository(reauthenticateResult: const Ok(null)),
      );

      final pwOption = find.text('Use password instead');
      await tester.ensureVisible(pwOption);
      await tester.pumpAndSettle();
      await tester.tap(pwOption);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'hunter2');
      final confirm = find.widgetWithText(FilledButton, 'Confirm');
      await tester.ensureVisible(confirm);
      await tester.pumpAndSettle();
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(host.result, isTrue);
    });

    testWidgets('cancel pops false', (tester) async {
      final host = await _pump(
        tester,
        webauthn: FakeWebauthnRepository(),
        pin: FakePinRepository(),
        auth: FakeAuthRepository(),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(host.result, isFalse);
    });
  });
}
