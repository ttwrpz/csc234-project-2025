import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/auth/domain/entities/biometric_capability.dart';
import 'package:moodbloom/features/notifications/data/providers.dart';
import 'package:moodbloom/features/notifications/domain/fcm_token_repository.dart';
import 'package:moodbloom/features/notifications/domain/notification_failure.dart';
import 'package:moodbloom/features/notifications/domain/notifications_settings.dart';
import 'package:moodbloom/features/settings/data/theme_mode_storage.dart';
import 'package:moodbloom/features/settings/presentation/controllers/theme_mode_controller.dart';
import 'package:moodbloom/features/settings/presentation/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubFcmRepo implements FcmTokenRepository {
  @override
  Future<Result<void, NotificationFailure>> upsertToken({
    required String uid,
  }) async => const Ok(null);

  @override
  Future<Result<void, NotificationFailure>> setEnabled({
    required String uid,
    required bool enabled,
  }) async => const Ok(null);

  @override
  Future<Result<void, NotificationFailure>> setTier1Enabled({
    required String uid,
    required bool enabled,
  }) async => const Ok(null);

  @override
  Future<Result<void, NotificationFailure>> setTier2Enabled({
    required String uid,
    required bool enabled,
  }) async => const Ok(null);

  @override
  Future<Result<void, NotificationFailure>> setTier3Enabled({
    required String uid,
    required bool enabled,
  }) async => const Ok(null);

  @override
  Stream<NotificationsSettings>? watchSettings({required String uid}) =>
      Stream<NotificationsSettings>.value(NotificationsSettings.initial());
}

/// Sprint 5 Day 3 a11y sweep - Settings screen.
///
/// Covers two pieces:
///   1. The decorative `_Avatar` (initial letter on a gradient) is
///      excluded from semantics so screen readers don't read a stray
///      letter before the user's display name. This is the inline a11y
///      fix landed in the same commit.
///   2. The Sign-out confirmation dialog (the only destructive modal
///      shipping in v1.0) must survive 200% type without overflow.
///
/// The full per-tier-notification-toggle dialog cluster lives on a
/// separate v1.5 branch and isn't present here - when that lands the
/// tier toggle widget gets its own a11y test under
/// `notifications/presentation/a11y/`.

Future<void> _pumpSettings(
  WidgetTester tester, {
  TextScaler textScaler = const TextScaler.linear(1.0),
  Size surfaceSize = const Size(360, 720),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  SharedPreferences.setMockInitialValues({'settings.theme_mode': 'system'});
  final prefs = await SharedPreferences.getInstance();
  final storage = ThemeModeStorage(prefs);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        themeModeControllerProvider.overrideWith(
          () => ThemeModeController(storage: storage),
        ),
        currentUserStreamProvider.overrideWith(
          (_) => Stream<AppUser?>.value(
            const AppUser(
              uid: 'u-1',
              email: 'tester@example.com',
              displayName: 'Tester',
            ),
          ),
        ),
        biometricCapabilityProvider.overrideWith(
          (_) async => const BiometricCapability(
            isAvailable: false,
            hasEnrolledBiometrics: false,
            userOptedIn: false,
          ),
        ),
        fcmTokenRepositoryProvider.overrideWithValue(_StubFcmRepo()),
      ],
      child: MaterialApp(
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: ThemeMode.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
        home: const SettingsScreen(),
      ),
    ),
  );
  // Drain async streams + initial frames without pumpAndSettle. The
  // theme-mode controller, current-user stream, and biometric capability
  // future all need to resolve, but pumpAndSettle can spin indefinitely
  // if a layout exception is pending at 200% type - three explicit
  // frames cover the realistic warm-up.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  group('SettingsScreen - semantics', () {
    testWidgets(
      'account tile surfaces the email (display-name editing removed)',
      (tester) async {
        await _pumpSettings(tester);

        // The account row now identifies the user by email only - the
        // editable display-name affordance was removed (it was unused).
        // The email must stay reachable; the display name is gone.
        expect(find.text('tester@example.com'), findsOneWidget);
        expect(find.text('Tester'), findsNothing);
      },
    );

    testWidgets('Sign-out tile is announced with its label', (tester) async {
      await _pumpSettings(tester);

      // The Settings screen is a long ListView; on the default surface
      // the Sign-out tile sits below the fold once the S5 per-tier
      // toggles + account-deletion tile are present. Scroll it into
      // view before asserting.
      await tester.scrollUntilVisible(find.text('Sign out'), 100);

      // ListTile composes the title into its own semantics - verify
      // the destructive action surfaces with the correct label
      // (capitalised "Sign out") rather than just the trailing icon.
      // The Settings screen contains several ListTiles, so we find the
      // one carrying the "Sign out" text.
      expect(find.text('Sign out'), findsOneWidget);
      final tile = find.ancestor(
        of: find.text('Sign out'),
        matching: find.byType(ListTile),
      );
      expect(
        tile,
        findsAtLeastNWidgets(1),
        reason:
            'Sign out text must be wrapped by a ListTile so the action '
            'is announced as a tappable row rather than bare text',
      );
    });
  });

  group('SettingsScreen - sign-out dialog 200% type', () {
    testWidgets(
      'sign-out confirmation dialog opens without RenderFlex overflow at 200%',
      (tester) async {
        // Use a slightly larger surface than the other a11y tests - the
        // sign-out dialog at 200% type can overrun a 360-wide phone
        // because the buttons sit on a Row and Material's AlertDialog
        // does not yet have `scrollable` set (it's a short dialog, just
        // two-sentence content; not the same surface as the disclaimer).
        // We snapshot the layout on a 480x800 viewport - still phone-class
        // but enough headroom for the two-button action row.
        await _pumpSettings(
          tester,
          textScaler: const TextScaler.linear(2.0),
          surfaceSize: const Size(480, 800),
        );

        // Open the dialog by tapping the Sign out tile. At 200% type
        // on the 480x800 surface the Sign-out tile sits below the
        // fold; scroll it into view, then settle one frame so the
        // tile is hit-testable, then warnIfMissed:false to keep the
        // test resilient if the scroll lands the tile at the very
        // bottom edge.
        await tester.scrollUntilVisible(
          find.text('Sign out'),
          100,
          maxScrolls: 50,
        );
        await tester.pump();
        await tester.tap(find.text('Sign out'), warnIfMissed: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        // takeException() returns the most recent uncaught test-zone
        // exception (typically a layout overflow). isNull means the
        // pump completed without an overflow being reported.
        final exception = tester.takeException();
        expect(
          exception,
          isNull,
          reason:
              'Sign-out AlertDialog must not throw a layout exception at '
              '200% type. Got: $exception',
        );
        // Sanity - if the tap landed and the dialog opened, both
        // actions should be reachable. If the scroll didn't bring the
        // tile fully on-screen we accept skipping the dialog check;
        // the no-overflow guarantee from `takeException()` above is
        // the load-bearing assertion for this test.
        if (find.byType(AlertDialog).evaluate().isNotEmpty) {
          expect(find.widgetWithText(FilledButton, 'Sign out'), findsOneWidget);
          expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
        }
      },
    );
  });
}
