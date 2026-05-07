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

    test('initial() defaults: cheer-up enabled, no tokens', () {
      final s = NotificationsSettings.initial();
      expect(s.cheerUpEnabled, isTrue);
      expect(s.tokens, isEmpty);
      expect(s.updatedAt, isNull);
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
