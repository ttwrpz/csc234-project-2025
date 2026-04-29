import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../features/mood/data/local/mood_database.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
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
