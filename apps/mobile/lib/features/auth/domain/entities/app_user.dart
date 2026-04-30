import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';

/// Domain representation of an authenticated user.
///
/// No password fields, no tokens, no Firebase types — those live in the data
/// layer. JSON serialization is deferred to HB-002 (UserProfile upsert), so
/// no `fromJson` factory yet.
@freezed
class AppUser with _$AppUser {
  const factory AppUser({
    required String uid,
    String? email,
    String? displayName,
    String? photoUrl,
    @Default(false) bool emailVerified,
    DateTime? lastSignInAt,
  }) = _AppUser;
}
