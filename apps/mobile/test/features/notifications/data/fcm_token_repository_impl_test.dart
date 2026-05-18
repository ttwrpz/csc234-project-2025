import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/notifications/data/datasources/fcm_datasource.dart';
import 'package:moodbloom/features/notifications/data/datasources/notifications_firestore_datasource.dart';
import 'package:moodbloom/features/notifications/data/datasources/notifications_preference_datasource.dart';
import 'package:moodbloom/features/notifications/data/fcm_token_repository_impl.dart';
import 'package:moodbloom/features/notifications/domain/notification_failure.dart';
import 'package:moodbloom/features/notifications/domain/notifications_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

/// In-memory stand-in for [NotificationsFirestoreDatasource]. Records a
/// per-uid settings doc and replays the same `mutate` semantics (read →
/// transform → merge-write) without any real Firestore.
class _FakeFirestore implements NotificationsFirestoreDatasource {
  final Map<String, NotificationsSettings> docs = {};
  Object? mutateThrows;
  int mutateCalls = 0;

  @override
  Future<void> mutate(
    String uid,
    NotificationsSettings Function(NotificationsSettings current) mutate,
  ) async {
    mutateCalls += 1;
    if (mutateThrows != null) {
      final t = mutateThrows;
      mutateThrows = null;
      throw t!;
    }
    final current = docs[uid] ?? NotificationsSettings.initial();
    docs[uid] = mutate(current);
  }

  @override
  Stream<NotificationsSettings> watch(String uid) async* {
    yield docs[uid] ?? NotificationsSettings.initial();
  }
}

class _FakeFcm implements FcmDatasource {
  FcmPermissionOutcome permissionOutcome = FcmPermissionOutcome.granted;
  String? token = 'token-A';
  NotificationPlatform platform = NotificationPlatform.android;
  int requestPermissionCalls = 0;

  @override
  Future<FcmPermissionOutcome> requestPermission() async {
    requestPermissionCalls += 1;
    return permissionOutcome;
  }

  @override
  Future<FcmPermissionOutcome?> currentPermission() async => permissionOutcome;

  @override
  Future<String?> getToken() async => token;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  NotificationPlatform currentPlatform() => platform;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('FcmTokenRepositoryImpl', () {
    late _FakeFirestore firestore;
    late _FakeFcm fcm;
    late NotificationsPreferenceDatasource pref;
    late FcmTokenRepositoryImpl repo;
    const uid = 'user-1';

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      firestore = _FakeFirestore();
      fcm = _FakeFcm();
      pref = NotificationsPreferenceDatasource(prefs);
      repo = FcmTokenRepositoryImpl(
        firestore: firestore,
        fcm: fcm,
        preference: pref,
      );
    });

    test('upsertToken — writes a new token row', () async {
      final result = await repo.upsertToken(uid: uid);
      expect(result, isA<Ok<void, NotificationFailure>>());
      expect(firestore.docs[uid]!.tokens.length, 1);
      expect(firestore.docs[uid]!.tokens.single.token, 'token-A');
    });

    test(
      'upsertToken — re-running with same token dedups (no duplicate row)',
      () async {
        await repo.upsertToken(uid: uid);
        await repo.upsertToken(uid: uid);
        expect(firestore.docs[uid]!.tokens.length, 1);
        expect(firestore.docs[uid]!.tokens.single.token, 'token-A');
      },
    );

    test('upsertToken — multi-device: distinct tokens both stored', () async {
      fcm.token = 'token-A';
      fcm.platform = NotificationPlatform.android;
      await repo.upsertToken(uid: uid);

      fcm.token = 'token-B';
      fcm.platform = NotificationPlatform.web;
      await repo.upsertToken(uid: uid);

      expect(firestore.docs[uid]!.tokens.length, 2);
      expect(firestore.docs[uid]!.tokens.map((t) => t.token).toSet(), {
        'token-A',
        'token-B',
      });
    });

    test('upsertToken — permissionDenied outcome surfaces failure', () async {
      fcm.permissionOutcome = FcmPermissionOutcome.denied;
      final result = await repo.upsertToken(uid: uid);
      expect(result, isA<Err<void, NotificationFailure>>());
      final failure = (result as Err<void, NotificationFailure>).failure;
      expect(failure, isA<NotificationFailure>());
      expect(failure.message.toLowerCase(), contains('phone settings'));
      expect(firestore.docs.containsKey(uid), isFalse);
    });

    test('upsertToken — null token returns tokenUnavailable', () async {
      fcm.token = null;
      final result = await repo.upsertToken(uid: uid);
      expect(result, isA<Err<void, NotificationFailure>>());
      expect(firestore.docs.containsKey(uid), isFalse);
    });

    test(
      'upsertToken — empty uid returns tokenUnavailable without calling fcm',
      () async {
        final result = await repo.upsertToken(uid: '');
        expect(result, isA<Err<void, NotificationFailure>>());
        expect(fcm.requestPermissionCalls, 0);
      },
    );

    test('setEnabled(false) — flips Firestore flag and local mirror', () async {
      // Seed with a token + cheer-up enabled.
      await repo.upsertToken(uid: uid);
      expect(firestore.docs[uid]!.cheerUpEnabled, isTrue);

      final result = await repo.setEnabled(uid: uid, enabled: false);
      expect(result, isA<Ok<void, NotificationFailure>>());
      expect(firestore.docs[uid]!.cheerUpEnabled, isFalse);
      // Local mirror updated as well.
      expect(pref.isCheerUpEnabled(), isFalse);
      // Tokens are NOT cleared on disable (multi-device, easy re-enable).
      expect(firestore.docs[uid]!.tokens.length, 1);
    });

    test('setEnabled(true) — flips flag back on', () async {
      await repo.setEnabled(uid: uid, enabled: false);
      expect(firestore.docs[uid]!.cheerUpEnabled, isFalse);

      final result = await repo.setEnabled(uid: uid, enabled: true);
      expect(result, isA<Ok<void, NotificationFailure>>());
      expect(firestore.docs[uid]!.cheerUpEnabled, isTrue);
      expect(pref.isCheerUpEnabled(), isTrue);
    });

    test(
      'setEnabled — Firebase exception maps to NotificationFailure.network',
      () async {
        firestore.mutateThrows = FirebaseException(plugin: 'cloud_firestore');
        final result = await repo.setEnabled(uid: uid, enabled: true);
        expect(result, isA<Err<void, NotificationFailure>>());
      },
    );

    test('watchSettings — returns null for empty uid', () {
      expect(repo.watchSettings(uid: ''), isNull);
    });

    test('watchSettings — emits the current doc state', () async {
      await repo.upsertToken(uid: uid);
      final stream = repo.watchSettings(uid: uid)!;
      final settings = await stream.first;
      expect(settings.tokens.length, 1);
      expect(settings.cheerUpEnabled, isTrue);
    });
  });
}
