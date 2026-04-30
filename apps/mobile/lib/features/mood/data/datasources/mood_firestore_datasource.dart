import 'package:cloud_firestore/cloud_firestore.dart';

import '../dtos/mood_entry_dto.dart';

/// Thin Firestore wrapper. No domain types here — this is the boundary
/// between cloud_firestore and the rest of the app.
class MoodFirestoreDatasource {
  const MoodFirestoreDatasource(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _moodsRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('moods');

  Stream<List<MoodEntryDto>> watchAll(String userId) {
    return _moodsRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(MoodEntryDto.fromFirestore).toList());
  }

  Future<MoodEntryDto?> findById({
    required String userId,
    required String id,
  }) async {
    final snap = await _moodsRef(userId).doc(id).get();
    if (!snap.exists) return null;
    return MoodEntryDto.fromFirestore(snap);
  }

  Future<MoodEntryDto> create(MoodEntryDto dto) async {
    final ref = await _moodsRef(dto.userId).add(dto.toFirestoreOnCreate());
    final snap = await ref.get();
    return MoodEntryDto.fromFirestore(snap);
  }

  Future<MoodEntryDto> update(MoodEntryDto dto) async {
    await _moodsRef(dto.userId).doc(dto.id).update(dto.toFirestoreOnUpdate());
    final snap = await _moodsRef(dto.userId).doc(dto.id).get();
    return MoodEntryDto.fromFirestore(snap);
  }

  Future<void> delete({required String userId, required String id}) {
    return _moodsRef(userId).doc(id).delete();
  }
}
