import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';

import '../domain/entities/mood_entry.dart';
import '../domain/mood_failure.dart';
import '../domain/mood_repository.dart';
import 'datasources/mood_firestore_datasource.dart';
import 'mappers/mood_entry_mapper.dart';

class MoodRepositoryImpl implements MoodRepository {
  const MoodRepositoryImpl({
    required MoodFirestoreDatasource datasource,
    MoodEntryMapper mapper = const MoodEntryMapper(),
    Logger logger = const Logger('mood.repo'),
  }) : _datasource = datasource,
       _mapper = mapper,
       _logger = logger;

  final MoodFirestoreDatasource _datasource;
  final MoodEntryMapper _mapper;
  final Logger _logger;

  @override
  Stream<List<MoodEntry>> watchAll({required String userId}) {
    return _datasource.watchAll(userId).map((dtos) {
      // Filter out malformed entries; never throw from a stream so the UI
      // doesn't blow up if one historical doc is bad.
      final entries = <MoodEntry>[];
      for (final dto in dtos) {
        final result = _mapper.toEntity(dto);
        switch (result) {
          case Ok(:final value):
            entries.add(value);
          case Err(:final failure):
            // PII rule: log only the failure category, never the entry text or
            // userId+text correlation.
            _logger.warn('skipping malformed entry', data: failure.message);
        }
      }
      return entries;
    });
  }

  @override
  Future<Result<MoodEntry, MoodFailure>> findById({
    required String userId,
    required String id,
  }) async {
    try {
      final dto = await _datasource.findById(userId: userId, id: id);
      if (dto == null) return Err(MoodFailure.notFound(id));
      return _mapper.toEntity(dto);
    } on FirebaseException catch (e) {
      return Err(_firebaseToFailure(e));
    } catch (e) {
      return Err(MoodFailure.unknown(e));
    }
  }

  @override
  Future<Result<MoodEntry, MoodFailure>> save(MoodEntry entry) async {
    try {
      final dto = _mapper.toDtoForCreate(
        userId: entry.userId,
        mood: entry.mood,
        intensity: entry.intensity,
        text: entry.text,
        mediaRefs: entry.mediaRefs,
      );
      final saved = await _datasource.create(dto);
      return _mapper.toEntity(saved);
    } on FirebaseException catch (e) {
      return Err(_firebaseToFailure(e));
    } catch (e) {
      return Err(MoodFailure.unknown(e));
    }
  }

  @override
  Future<Result<MoodEntry, MoodFailure>> update(MoodEntry entry) async {
    if (entry.isLocked()) return const Err(MoodFailure.locked());
    try {
      final dto = _mapper
          .toDtoForCreate(
            userId: entry.userId,
            mood: entry.mood,
            intensity: entry.intensity,
            text: entry.text,
            mediaRefs: entry.mediaRefs,
          )
          .copyWith(id: entry.id);
      final saved = await _datasource.update(dto);
      return _mapper.toEntity(saved);
    } on FirebaseException catch (e) {
      return Err(_firebaseToFailure(e));
    } catch (e) {
      return Err(MoodFailure.unknown(e));
    }
  }

  @override
  Future<Result<void, MoodFailure>> delete({
    required String userId,
    required String id,
  }) async {
    try {
      await _datasource.delete(userId: userId, id: id);
      return const Ok(null);
    } on FirebaseException catch (e) {
      return Err(_firebaseToFailure(e));
    } catch (e) {
      return Err(MoodFailure.unknown(e));
    }
  }

  MoodFailure _firebaseToFailure(FirebaseException e) {
    if (e.code == 'unavailable' || e.code == 'network-request-failed') {
      return const MoodFailure.network();
    }
    return MoodFailure.server(e.code);
  }
}
