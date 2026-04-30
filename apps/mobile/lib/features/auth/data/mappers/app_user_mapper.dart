import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../domain/entities/app_user.dart';

/// Converts a Firebase `User` into the domain [AppUser]. No DTO step — the
/// architect's HB-001 default (open question 3) was "delete the DTO and add it
/// in HB-002 when UserProfile upsert lands".
class AppUserMapper {
  const AppUserMapper();

  AppUser fromFirebaseUser(fb.User user) {
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      emailVerified: user.emailVerified,
      lastSignInAt: user.metadata.lastSignInTime,
    );
  }
}
