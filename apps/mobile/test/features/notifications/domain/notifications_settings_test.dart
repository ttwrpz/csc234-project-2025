import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/notifications/domain/notifications_settings.dart';

void main() {
  group('NotificationsSettings', () {
    final t1Old = FcmTokenRecord(
      token: 'token-1',
      platform: NotificationPlatform.android,
      lastSeenAt: DateTime.utc(2026, 5, 1, 10),
    );
    final t1Fresh = FcmTokenRecord(
      token: 'token-1',
      platform: NotificationPlatform.android,
      lastSeenAt: DateTime.utc(2026, 5, 7, 14),
    );
    final t2 = FcmTokenRecord(
      token: 'token-2',
      platform: NotificationPlatform.web,
      lastSeenAt: DateTime.utc(2026, 5, 7, 12),
    );

    test('initial() defaults: every flag enabled, no tokens', () {
      final s = NotificationsSettings.initial();
      expect(s.cheerUpEnabled, isTrue);
      expect(s.tier1Enabled, isTrue);
      expect(s.tier2Enabled, isTrue);
      expect(s.tier3Enabled, isTrue);
      expect(s.tokens, isEmpty);
      expect(s.updatedAt, isNull);
    });

    test('anyTierEnabled — true when any tier flag is true', () {
      final s = NotificationsSettings.initial();
      expect(s.anyTierEnabled, isTrue);
      expect(s.copyWith(tier1Enabled: false).anyTierEnabled, isTrue);
      expect(
        s.copyWith(tier1Enabled: false, tier2Enabled: false).anyTierEnabled,
        isTrue,
      );
    });

    test('anyTierEnabled — false only when ALL three are false', () {
      final s = NotificationsSettings.initial().copyWith(
        tier1Enabled: false,
        tier2Enabled: false,
        tier3Enabled: false,
      );
      expect(s.anyTierEnabled, isFalse);
    });

    test(
      'withTier1Enabled — keeps cheer-up shim true while another tier is on',
      () {
        final s = NotificationsSettings.initial().withTier1Enabled(false);
        expect(s.tier1Enabled, isFalse);
        expect(s.tier2Enabled, isTrue);
        expect(s.tier3Enabled, isTrue);
        // Shim stays true because Tier 2 + Tier 3 remain on.
        expect(s.cheerUpEnabled, isTrue);
      },
    );

    test(
      'withTier3Enabled(false) on the last enabled tier flips cheerUpEnabled off',
      () {
        final s = NotificationsSettings.initial()
            .withTier1Enabled(false)
            .withTier2Enabled(false)
            .withTier3Enabled(false);
        expect(s.tier1Enabled, isFalse);
        expect(s.tier2Enabled, isFalse);
        expect(s.tier3Enabled, isFalse);
        // All three tiers off → cheer-up CF should stop firing.
        expect(s.cheerUpEnabled, isFalse);
      },
    );

    test('re-enabling a tier flips cheerUpEnabled back on', () {
      final off = NotificationsSettings.initial()
          .withTier1Enabled(false)
          .withTier2Enabled(false)
          .withTier3Enabled(false);
      expect(off.cheerUpEnabled, isFalse);

      final reEnabled = off.withTier2Enabled(true);
      expect(reEnabled.tier2Enabled, isTrue);
      expect(reEnabled.cheerUpEnabled, isTrue);
    });

    test('copyWith — new tier flags round-trip independently', () {
      final s = NotificationsSettings.initial().copyWith(
        tier1Enabled: false,
        tier2Enabled: true,
        tier3Enabled: false,
      );
      expect(s.tier1Enabled, isFalse);
      expect(s.tier2Enabled, isTrue);
      expect(s.tier3Enabled, isFalse);
      // Direct copyWith bypasses the `withTierN` shim re-derivation —
      // by design, so callers (e.g. the migration helper) can write a
      // legacy-mirrored snapshot without the helper inferring a stale
      // shim from the partially-built state.
    });

    test('withToken — appends a new token', () {
      final s = NotificationsSettings.initial().withToken(t1Old);
      expect(s.tokens, [t1Old]);
    });

    test('withToken — same-token re-register replaces, does not duplicate', () {
      final s = NotificationsSettings.initial()
          .withToken(t1Old)
          .withToken(t1Fresh);
      expect(s.tokens.length, 1);
      expect(s.tokens.single, t1Fresh);
      expect(s.tokens.single.lastSeenAt, t1Fresh.lastSeenAt);
    });

    test('withToken — multi-device: distinct tokens both kept', () {
      final s = NotificationsSettings.initial().withToken(t1Old).withToken(t2);
      expect(s.tokens.length, 2);
      expect(s.tokens, containsAll([t1Old, t2]));
    });

    test('withToken — refresh keeps the other device intact', () {
      final s = NotificationsSettings.initial()
          .withToken(t1Old)
          .withToken(t2)
          .withToken(t1Fresh);
      expect(s.tokens.length, 2);
      // t1 has been refreshed.
      expect(s.tokens.where((t) => t.token == 'token-1').single, t1Fresh);
      // t2 untouched.
      expect(s.tokens.where((t) => t.token == 'token-2').single, t2);
    });

    test('withoutToken — removes the matching token', () {
      final s = NotificationsSettings.initial()
          .withToken(t1Old)
          .withToken(t2)
          .withoutToken('token-1');
      expect(s.tokens.length, 1);
      expect(s.tokens.single.token, 'token-2');
    });

    test('withoutToken — no-op when token not present', () {
      final base = NotificationsSettings.initial().withToken(t1Old);
      final after = base.withoutToken('not-there');
      expect(identical(after, base), isTrue);
    });

    test('cheerUpEnabled flag mutates via copyWith', () {
      final s = NotificationsSettings.initial().copyWith(cheerUpEnabled: false);
      expect(s.cheerUpEnabled, isFalse);
    });
  });
}
