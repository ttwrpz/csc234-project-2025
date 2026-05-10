import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../features/mood/data/local/mood_database.dart';

import 'feature_flags.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);
final firebaseStorageProvider = Provider<FirebaseStorage>(
  (ref) => FirebaseStorage.instance,
);

/// Shared preferences singleton. Resolved on first read; tests override with a
/// `SharedPreferences.setMockInitialValues({...})` plus a fresh container
/// scope, or override this provider directly with a fake.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);

/// Singleton Drift database. Closed automatically when the provider scope is
/// disposed. PR-1 ships the schema; PR-2 wires it to the sync manager and
/// PR-3 routes `MoodRepositoryImpl` through it.
final databaseProvider = Provider<MoodDatabase>((ref) {
  final db = MoodDatabase();
  ref.onDispose(() async => db.close());
  return db;
});

/// Per-install UUID stored in SharedPreferences under `mood.device_id`.
/// Used as the LWW tiebreak in [MoodDao.upsertFromRemote] (ADR-0005).
/// Generated lazily on first read; never PII (random per install).
final deviceIdProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final existing = prefs.getString('mood.device_id');
  if (existing != null) return existing;
  final fresh = const Uuid().v4();
  await prefs.setString('mood.device_id', fresh);
  return fresh;
});

/// Singleton handle to Crashlytics. Wired up in `main.dart`.
final crashlyticsProvider = Provider<FirebaseCrashlytics>(
  (ref) => FirebaseCrashlytics.instance,
);

/// Singleton handle to Remote Config. Defaults + min-fetch-interval are set in
/// `main.dart` before any consumer reads this provider.
final remoteConfigProvider = Provider<FirebaseRemoteConfig>(
  (ref) => FirebaseRemoteConfig.instance,
);

/// Production [FeatureFlagSource] backed by Firebase Remote Config. Tests
/// override this provider with a hand-rolled fake.
final featureFlagSourceProvider = Provider<FeatureFlagSource>((ref) {
  return _RemoteConfigFlagSource(ref.watch(remoteConfigProvider));
});

/// Snapshot of all Remote Config feature flags. Falls back to
/// [FeatureFlags.defaults] when the source is uninitialised or throws so
/// callers never have to handle a null/loading state for kill-switches.
final featureFlagsProvider = Provider<FeatureFlags>((ref) {
  final source = ref.watch(featureFlagSourceProvider);
  try {
    return FeatureFlags(
      aiPatternAnalysisEnabled: source.getBool('ai_pattern_analysis_enabled'),
      geminiDetectionEnabled: source.getBool('gemini_detection_enabled'),
      interventionDispatchEnabled: source.getBool(
        'intervention_dispatch_enabled',
      ),
    );
  } catch (_) {
    // Source throws if RC hasn't been initialised yet (e.g. before
    // setDefaults runs in main.dart). Defaults guarantee a usable app.
    return FeatureFlags.defaults();
  }
});

class _RemoteConfigFlagSource implements FeatureFlagSource {
  const _RemoteConfigFlagSource(this._rc);

  final FirebaseRemoteConfig _rc;

  @override
  bool getBool(String key) => _rc.getBool(key);
}
