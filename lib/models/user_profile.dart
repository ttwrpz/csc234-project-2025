import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model representing a user's profile stored in Firestore.
class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;
  final int streakCount;
  final DateTime? lastMoodDate;

  UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.createdAt,
    this.streakCount = 0,
    this.lastMoodDate,
  });

  UserProfile copyWith({
    String? displayName,
    String? photoUrl,
    int? streakCount,
    DateTime? lastMoodDate,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      streakCount: streakCount ?? this.streakCount,
      lastMoodDate: lastMoodDate ?? this.lastMoodDate,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'streakCount': streakCount,
      'lastMoodDate':
          lastMoodDate != null ? Timestamp.fromDate(lastMoodDate!) : null,
    };
  }

  factory UserProfile.fromFirestore(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      streakCount: data['streakCount'] as int? ?? 0,
      lastMoodDate: (data['lastMoodDate'] as Timestamp?)?.toDate(),
    );
  }
}
