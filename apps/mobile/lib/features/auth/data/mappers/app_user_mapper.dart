import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../domain/entities/app_user.dart';

/// Converts a Firebase `User` into the domain [AppUser]. No DTO step -
/// a UserProfile DTO can be added if/when an upsert flow needs it.
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
