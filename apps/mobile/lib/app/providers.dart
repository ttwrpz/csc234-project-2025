import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

/// Async-resolved [SharedPreferences] handle. Features that need preferences
/// (biometric opt-in, onboarding flag, etc.) read this provider rather than
/// calling `SharedPreferences.getInstance()` directly so tests can override
/// with `SharedPreferences.setMockInitialValues({})` upstream.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);
