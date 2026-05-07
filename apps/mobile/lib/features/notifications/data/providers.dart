import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/fcm_token_repository.dart';
import 'datasources/fcm_datasource.dart';
import 'datasources/notifications_firestore_datasource.dart';
import 'datasources/notifications_preference_datasource.dart';
import 'fcm_token_repository_impl.dart';

/// Singleton handle to the platform `FirebaseMessaging` instance. Tests
/// override this with a fake.
final firebaseMessagingProvider = Provider<FirebaseMessaging>(
  (ref) => FirebaseMessaging.instance,
);

final fcmDatasourceProvider = Provider<FcmDatasource>((ref) {
  return FcmDatasource(ref.watch(firebaseMessagingProvider));
});

/// Reads the async [sharedPreferencesProvider] and exposes a synchronous
/// preference datasource. Mirrors the auth feature's pattern.
///
/// If SharedPreferences is still resolving (e.g. early frames in a
/// widget test that hasn't yet pumped), this provider returns `null`.
/// Consumers tolerate the null and fall back to a transient default
/// (cheer-up enabled per O13) until the real instance arrives.
final notificationsPreferenceDatasourceProvider =
    Provider<NotificationsPreferenceDatasource?>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return prefs.whenOrNull(data: NotificationsPreferenceDatasource.new);
    });

final notificationsFirestoreDatasourceProvider =
    Provider<NotificationsFirestoreDatasource>((ref) {
      return NotificationsFirestoreDatasource(ref.watch(firestoreProvider));
    });

final fcmTokenRepositoryProvider = Provider<FcmTokenRepository>((ref) {
  return FcmTokenRepositoryImpl(
    firestore: ref.watch(notificationsFirestoreDatasourceProvider),
    fcm: ref.watch(fcmDatasourceProvider),
    preference: ref.watch(notificationsPreferenceDatasourceProvider),
  );
});
