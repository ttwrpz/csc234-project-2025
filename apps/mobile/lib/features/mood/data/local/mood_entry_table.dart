import 'dart:convert';

import 'package:drift/drift.dart';

/// JSON-encoded `List<String>` for the `media_refs` column. Drift requires a
/// non-null `String` representation so the canonical empty value is `'[]'`.
class MediaRefsConverter extends TypeConverter<List<String>, String> {
  const MediaRefsConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty) return const <String>[];
    final decoded = jsonDecode(fromDb);
    if (decoded is! List) return const <String>[];
    return decoded.map((e) => e.toString()).toList(growable: false);
  }

  @override
  String toSql(List<String> value) => jsonEncode(value);
}

/// Local mirror of the Firestore `users/{uid}/moods/{moodId}` document plus
/// the offline-first sync bookkeeping columns (`sync_state`, `device_id`,
/// `deleted_at`). Times are stored as INTEGER epoch milliseconds UTC — never
/// Firestore `Timestamp`, never ISO strings (per ADR-0004).
@DataClassName('MoodEntryRow')
class MoodEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get mood => text()();

  // 1..5 invariant mirrors `MoodEntry.create`. customConstraint emits raw SQL
  // CHECK rather than Drift's column-DSL `check(...)` (which would make the
  // getter analyzer-recursive).
  IntColumn get intensity => integer().customConstraint(
    'NOT NULL CHECK (intensity BETWEEN 1 AND 5)',
  )();

  /// The 500-char limit is also enforced in domain (`MoodEntry.create`);
  /// we mirror it at the schema layer as a defence-in-depth check.
  /// `note` rather than `text` to avoid shadowing the column-builder helper.
  TextColumn get note => text()
      .named('text')
      .customConstraint('NOT NULL CHECK (length(text) <= 500)')();

  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at').nullable()();

  TextColumn get mediaRefs => text()
      .named('media_refs')
      .map(const MediaRefsConverter())
      .withDefault(const Constant('[]'))();

  /// `pending` / `syncing` / `synced` / `error` — see ADR-0004.
  TextColumn get syncState => text().named('sync_state')();

  /// Per-install UUID; LWW tiebreak on equal `updated_at` (ADR-0005).
  TextColumn get deviceId => text().named('device_id')();

  /// Tombstone marker. NULL means alive; non-NULL means soft-deleted.
  IntColumn get deletedAt => integer().named('deleted_at').nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
