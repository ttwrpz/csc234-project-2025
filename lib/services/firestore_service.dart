import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';
import '../models/mood_entry.dart';
import '../models/user_profile.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- User Profile ---

  Future<void> createUserProfile(UserProfile profile) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(profile.uid)
        .set(profile.toFirestore());
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc =
        await _db.collection(AppConstants.usersCollection).doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromFirestore(uid, doc.data()!);
  }

  Future<void> updateUserProfile(
    String uid,
    Map<String, dynamic> data,
  ) async {
    await _db.collection(AppConstants.usersCollection).doc(uid).update(data);
  }

  Future<void> deleteUserProfile(String uid) async {
    await _db.collection(AppConstants.usersCollection).doc(uid).delete();
  }

  // --- Mood Entries ---

  Future<void> addMoodEntry(MoodEntry entry) async {
    await _db
        .collection(AppConstants.moodsCollection)
        .doc(entry.id)
        .set(entry.toFirestore());
  }

  Future<void> updateMoodEntry(MoodEntry entry) async {
    await _db
        .collection(AppConstants.moodsCollection)
        .doc(entry.id)
        .update(entry.toFirestore());
  }

  Future<void> deleteMoodEntry(String id) async {
    await _db.collection(AppConstants.moodsCollection).doc(id).delete();
  }

  Future<List<MoodEntry>> getMoodEntries(
    String userId, {
    int limit = AppConstants.entriesPerPage,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _db
        .collection(AppConstants.moodsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => MoodEntry.fromFirestore(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<MoodEntry>> getMoodEntriesForDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _db
        .collection(AppConstants.moodsCollection)
        .where('userId', isEqualTo: userId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => MoodEntry.fromFirestore(doc.data()))
        .toList();
  }

  Future<void> deleteAllUserMoods(String userId) async {
    final batch = _db.batch();
    final snapshot = await _db
        .collection(AppConstants.moodsCollection)
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
