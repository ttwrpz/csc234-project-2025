// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mood_database.dart';

// ignore_for_file: type=lint
class $MoodEntriesTable extends MoodEntries
    with TableInfo<$MoodEntriesTable, MoodEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MoodEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<String> mood = GeneratedColumn<String>(
    'mood',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intensityMeta = const VerificationMeta(
    'intensity',
  );
  @override
  late final GeneratedColumn<int> intensity = GeneratedColumn<int>(
    'intensity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (intensity BETWEEN 1 AND 5)',
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(text) <= 500)',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> mediaRefs =
      GeneratedColumn<String>(
        'media_refs',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<String>>($MoodEntriesTable.$convertermediaRefs);
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    mood,
    intensity,
    note,
    createdAt,
    updatedAt,
    mediaRefs,
    syncState,
    deviceId,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mood_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<MoodEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('mood')) {
      context.handle(
        _moodMeta,
        mood.isAcceptableOrUnknown(data['mood']!, _moodMeta),
      );
    } else if (isInserting) {
      context.missing(_moodMeta);
    }
    if (data.containsKey('intensity')) {
      context.handle(
        _intensityMeta,
        intensity.isAcceptableOrUnknown(data['intensity']!, _intensityMeta),
      );
    } else if (isInserting) {
      context.missing(_intensityMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['text']!, _noteMeta),
      );
    } else if (isInserting) {
      context.missing(_noteMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStateMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MoodEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MoodEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      mood: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mood'],
      )!,
      intensity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}intensity'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
      mediaRefs: $MoodEntriesTable.$convertermediaRefs.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}media_refs'],
        )!,
      ),
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $MoodEntriesTable createAlias(String alias) {
    return $MoodEntriesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $convertermediaRefs =
      const MediaRefsConverter();
}

class MoodEntryRow extends DataClass implements Insertable<MoodEntryRow> {
  final String id;
  final String userId;
  final String mood;
  final int intensity;

  /// The 500-char limit is also enforced in domain (`MoodEntry.create`);
  /// we mirror it at the schema layer as a defence-in-depth check.
  /// `note` rather than `text` to avoid shadowing the column-builder helper.
  final String note;
  final int createdAt;
  final int? updatedAt;
  final List<String> mediaRefs;

  /// `pending` / `syncing` / `synced` / `error`.
  final String syncState;

  /// Per-install UUID; LWW tiebreak on equal `updated_at`.
  final String deviceId;

  /// Tombstone marker. NULL means alive; non-NULL means soft-deleted.
  final int? deletedAt;
  const MoodEntryRow({
    required this.id,
    required this.userId,
    required this.mood,
    required this.intensity,
    required this.note,
    required this.createdAt,
    this.updatedAt,
    required this.mediaRefs,
    required this.syncState,
    required this.deviceId,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['mood'] = Variable<String>(mood);
    map['intensity'] = Variable<int>(intensity);
    map['text'] = Variable<String>(note);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    {
      map['media_refs'] = Variable<String>(
        $MoodEntriesTable.$convertermediaRefs.toSql(mediaRefs),
      );
    }
    map['sync_state'] = Variable<String>(syncState);
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  MoodEntriesCompanion toCompanion(bool nullToAbsent) {
    return MoodEntriesCompanion(
      id: Value(id),
      userId: Value(userId),
      mood: Value(mood),
      intensity: Value(intensity),
      note: Value(note),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      mediaRefs: Value(mediaRefs),
      syncState: Value(syncState),
      deviceId: Value(deviceId),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory MoodEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MoodEntryRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      mood: serializer.fromJson<String>(json['mood']),
      intensity: serializer.fromJson<int>(json['intensity']),
      note: serializer.fromJson<String>(json['note']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
      mediaRefs: serializer.fromJson<List<String>>(json['mediaRefs']),
      syncState: serializer.fromJson<String>(json['syncState']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'mood': serializer.toJson<String>(mood),
      'intensity': serializer.toJson<int>(intensity),
      'note': serializer.toJson<String>(note),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int?>(updatedAt),
      'mediaRefs': serializer.toJson<List<String>>(mediaRefs),
      'syncState': serializer.toJson<String>(syncState),
      'deviceId': serializer.toJson<String>(deviceId),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  MoodEntryRow copyWith({
    String? id,
    String? userId,
    String? mood,
    int? intensity,
    String? note,
    int? createdAt,
    Value<int?> updatedAt = const Value.absent(),
    List<String>? mediaRefs,
    String? syncState,
    String? deviceId,
    Value<int?> deletedAt = const Value.absent(),
  }) => MoodEntryRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    mood: mood ?? this.mood,
    intensity: intensity ?? this.intensity,
    note: note ?? this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    mediaRefs: mediaRefs ?? this.mediaRefs,
    syncState: syncState ?? this.syncState,
    deviceId: deviceId ?? this.deviceId,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  MoodEntryRow copyWithCompanion(MoodEntriesCompanion data) {
    return MoodEntryRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      mood: data.mood.present ? data.mood.value : this.mood,
      intensity: data.intensity.present ? data.intensity.value : this.intensity,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      mediaRefs: data.mediaRefs.present ? data.mediaRefs.value : this.mediaRefs,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MoodEntryRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('mood: $mood, ')
          ..write('intensity: $intensity, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('mediaRefs: $mediaRefs, ')
          ..write('syncState: $syncState, ')
          ..write('deviceId: $deviceId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    mood,
    intensity,
    note,
    createdAt,
    updatedAt,
    mediaRefs,
    syncState,
    deviceId,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MoodEntryRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.mood == this.mood &&
          other.intensity == this.intensity &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.mediaRefs == this.mediaRefs &&
          other.syncState == this.syncState &&
          other.deviceId == this.deviceId &&
          other.deletedAt == this.deletedAt);
}

class MoodEntriesCompanion extends UpdateCompanion<MoodEntryRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> mood;
  final Value<int> intensity;
  final Value<String> note;
  final Value<int> createdAt;
  final Value<int?> updatedAt;
  final Value<List<String>> mediaRefs;
  final Value<String> syncState;
  final Value<String> deviceId;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const MoodEntriesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.mood = const Value.absent(),
    this.intensity = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.mediaRefs = const Value.absent(),
    this.syncState = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MoodEntriesCompanion.insert({
    required String id,
    required String userId,
    required String mood,
    required int intensity,
    required String note,
    required int createdAt,
    this.updatedAt = const Value.absent(),
    this.mediaRefs = const Value.absent(),
    required String syncState,
    required String deviceId,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       mood = Value(mood),
       intensity = Value(intensity),
       note = Value(note),
       createdAt = Value(createdAt),
       syncState = Value(syncState),
       deviceId = Value(deviceId);
  static Insertable<MoodEntryRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? mood,
    Expression<int>? intensity,
    Expression<String>? note,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? mediaRefs,
    Expression<String>? syncState,
    Expression<String>? deviceId,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (mood != null) 'mood': mood,
      if (intensity != null) 'intensity': intensity,
      if (note != null) 'text': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (mediaRefs != null) 'media_refs': mediaRefs,
      if (syncState != null) 'sync_state': syncState,
      if (deviceId != null) 'device_id': deviceId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MoodEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? mood,
    Value<int>? intensity,
    Value<String>? note,
    Value<int>? createdAt,
    Value<int?>? updatedAt,
    Value<List<String>>? mediaRefs,
    Value<String>? syncState,
    Value<String>? deviceId,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return MoodEntriesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mood: mood ?? this.mood,
      intensity: intensity ?? this.intensity,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mediaRefs: mediaRefs ?? this.mediaRefs,
      syncState: syncState ?? this.syncState,
      deviceId: deviceId ?? this.deviceId,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (mood.present) {
      map['mood'] = Variable<String>(mood.value);
    }
    if (intensity.present) {
      map['intensity'] = Variable<int>(intensity.value);
    }
    if (note.present) {
      map['text'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (mediaRefs.present) {
      map['media_refs'] = Variable<String>(
        $MoodEntriesTable.$convertermediaRefs.toSql(mediaRefs.value),
      );
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MoodEntriesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('mood: $mood, ')
          ..write('intensity: $intensity, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('mediaRefs: $mediaRefs, ')
          ..write('syncState: $syncState, ')
          ..write('deviceId: $deviceId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorCodeMeta = const VerificationMeta(
    'lastErrorCode',
  );
  @override
  late final GeneratedColumn<String> lastErrorCode = GeneratedColumn<String>(
    'last_error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _retryAfterMeta = const VerificationMeta(
    'retryAfter',
  );
  @override
  late final GeneratedColumn<int> retryAfter = GeneratedColumn<int>(
    'retry_after',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entryId,
    operation,
    payload,
    attemptCount,
    lastError,
    lastErrorCode,
    retryAfter,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('last_error_code')) {
      context.handle(
        _lastErrorCodeMeta,
        lastErrorCode.isAcceptableOrUnknown(
          data['last_error_code']!,
          _lastErrorCodeMeta,
        ),
      );
    }
    if (data.containsKey('retry_after')) {
      context.handle(
        _retryAfterMeta,
        retryAfter.isAcceptableOrUnknown(data['retry_after']!, _retryAfterMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      lastErrorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_code'],
      ),
      retryAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_after'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueRow extends DataClass implements Insertable<SyncQueueRow> {
  final int id;
  final String entryId;

  /// `create` / `update` / `delete`.
  final String operation;

  /// JSON snapshot of the entry at mutation time. Used by the sync worker so
  /// the row payload survives in-flight retries even if the local row mutates
  /// further before the network call lands.
  final String payload;
  final int attemptCount;

  /// Truncated to 200 chars at write time — see [SyncQueueDao.markFailed].
  /// Never include PII (entry text, email).
  final String? lastError;
  final String? lastErrorCode;
  final int retryAfter;
  final int createdAt;
  const SyncQueueRow({
    required this.id,
    required this.entryId,
    required this.operation,
    required this.payload,
    required this.attemptCount,
    this.lastError,
    this.lastErrorCode,
    required this.retryAfter,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entry_id'] = Variable<String>(entryId);
    map['operation'] = Variable<String>(operation);
    map['payload'] = Variable<String>(payload);
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || lastErrorCode != null) {
      map['last_error_code'] = Variable<String>(lastErrorCode);
    }
    map['retry_after'] = Variable<int>(retryAfter);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      entryId: Value(entryId),
      operation: Value(operation),
      payload: Value(payload),
      attemptCount: Value(attemptCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      lastErrorCode: lastErrorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorCode),
      retryAfter: Value(retryAfter),
      createdAt: Value(createdAt),
    );
  }

  factory SyncQueueRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueRow(
      id: serializer.fromJson<int>(json['id']),
      entryId: serializer.fromJson<String>(json['entryId']),
      operation: serializer.fromJson<String>(json['operation']),
      payload: serializer.fromJson<String>(json['payload']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      lastErrorCode: serializer.fromJson<String?>(json['lastErrorCode']),
      retryAfter: serializer.fromJson<int>(json['retryAfter']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entryId': serializer.toJson<String>(entryId),
      'operation': serializer.toJson<String>(operation),
      'payload': serializer.toJson<String>(payload),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'lastError': serializer.toJson<String?>(lastError),
      'lastErrorCode': serializer.toJson<String?>(lastErrorCode),
      'retryAfter': serializer.toJson<int>(retryAfter),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  SyncQueueRow copyWith({
    int? id,
    String? entryId,
    String? operation,
    String? payload,
    int? attemptCount,
    Value<String?> lastError = const Value.absent(),
    Value<String?> lastErrorCode = const Value.absent(),
    int? retryAfter,
    int? createdAt,
  }) => SyncQueueRow(
    id: id ?? this.id,
    entryId: entryId ?? this.entryId,
    operation: operation ?? this.operation,
    payload: payload ?? this.payload,
    attemptCount: attemptCount ?? this.attemptCount,
    lastError: lastError.present ? lastError.value : this.lastError,
    lastErrorCode: lastErrorCode.present
        ? lastErrorCode.value
        : this.lastErrorCode,
    retryAfter: retryAfter ?? this.retryAfter,
    createdAt: createdAt ?? this.createdAt,
  );
  SyncQueueRow copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueRow(
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payload: data.payload.present ? data.payload.value : this.payload,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      lastErrorCode: data.lastErrorCode.present
          ? data.lastErrorCode.value
          : this.lastErrorCode,
      retryAfter: data.retryAfter.present
          ? data.retryAfter.value
          : this.retryAfter,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueRow(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('retryAfter: $retryAfter, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entryId,
    operation,
    payload,
    attemptCount,
    lastError,
    lastErrorCode,
    retryAfter,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueRow &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.operation == this.operation &&
          other.payload == this.payload &&
          other.attemptCount == this.attemptCount &&
          other.lastError == this.lastError &&
          other.lastErrorCode == this.lastErrorCode &&
          other.retryAfter == this.retryAfter &&
          other.createdAt == this.createdAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueRow> {
  final Value<int> id;
  final Value<String> entryId;
  final Value<String> operation;
  final Value<String> payload;
  final Value<int> attemptCount;
  final Value<String?> lastError;
  final Value<String?> lastErrorCode;
  final Value<int> retryAfter;
  final Value<int> createdAt;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payload = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.retryAfter = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String entryId,
    required String operation,
    required String payload,
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.retryAfter = const Value.absent(),
    required int createdAt,
  }) : entryId = Value(entryId),
       operation = Value(operation),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<SyncQueueRow> custom({
    Expression<int>? id,
    Expression<String>? entryId,
    Expression<String>? operation,
    Expression<String>? payload,
    Expression<int>? attemptCount,
    Expression<String>? lastError,
    Expression<String>? lastErrorCode,
    Expression<int>? retryAfter,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (operation != null) 'operation': operation,
      if (payload != null) 'payload': payload,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (lastError != null) 'last_error': lastError,
      if (lastErrorCode != null) 'last_error_code': lastErrorCode,
      if (retryAfter != null) 'retry_after': retryAfter,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SyncQueueCompanion copyWith({
    Value<int>? id,
    Value<String>? entryId,
    Value<String>? operation,
    Value<String>? payload,
    Value<int>? attemptCount,
    Value<String?>? lastError,
    Value<String?>? lastErrorCode,
    Value<int>? retryAfter,
    Value<int>? createdAt,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: lastError ?? this.lastError,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      retryAfter: retryAfter ?? this.retryAfter,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (lastErrorCode.present) {
      map['last_error_code'] = Variable<String>(lastErrorCode.value);
    }
    if (retryAfter.present) {
      map['retry_after'] = Variable<int>(retryAfter.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('retryAfter: $retryAfter, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$MoodDatabase extends GeneratedDatabase {
  _$MoodDatabase(QueryExecutor e) : super(e);
  $MoodDatabaseManager get managers => $MoodDatabaseManager(this);
  late final $MoodEntriesTable moodEntries = $MoodEntriesTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final MoodDao moodDao = MoodDao(this as MoodDatabase);
  late final SyncQueueDao syncQueueDao = SyncQueueDao(this as MoodDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [moodEntries, syncQueue];
}

typedef $$MoodEntriesTableCreateCompanionBuilder =
    MoodEntriesCompanion Function({
      required String id,
      required String userId,
      required String mood,
      required int intensity,
      required String note,
      required int createdAt,
      Value<int?> updatedAt,
      Value<List<String>> mediaRefs,
      required String syncState,
      required String deviceId,
      Value<int?> deletedAt,
      Value<int> rowid,
    });
typedef $$MoodEntriesTableUpdateCompanionBuilder =
    MoodEntriesCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> mood,
      Value<int> intensity,
      Value<String> note,
      Value<int> createdAt,
      Value<int?> updatedAt,
      Value<List<String>> mediaRefs,
      Value<String> syncState,
      Value<String> deviceId,
      Value<int?> deletedAt,
      Value<int> rowid,
    });

class $$MoodEntriesTableFilterComposer
    extends Composer<_$MoodDatabase, $MoodEntriesTable> {
  $$MoodEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intensity => $composableBuilder(
    column: $table.intensity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get mediaRefs => $composableBuilder(
    column: $table.mediaRefs,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MoodEntriesTableOrderingComposer
    extends Composer<_$MoodDatabase, $MoodEntriesTable> {
  $$MoodEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intensity => $composableBuilder(
    column: $table.intensity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaRefs => $composableBuilder(
    column: $table.mediaRefs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MoodEntriesTableAnnotationComposer
    extends Composer<_$MoodDatabase, $MoodEntriesTable> {
  $$MoodEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<int> get intensity =>
      $composableBuilder(column: $table.intensity, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get mediaRefs =>
      $composableBuilder(column: $table.mediaRefs, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$MoodEntriesTableTableManager
    extends
        RootTableManager<
          _$MoodDatabase,
          $MoodEntriesTable,
          MoodEntryRow,
          $$MoodEntriesTableFilterComposer,
          $$MoodEntriesTableOrderingComposer,
          $$MoodEntriesTableAnnotationComposer,
          $$MoodEntriesTableCreateCompanionBuilder,
          $$MoodEntriesTableUpdateCompanionBuilder,
          (
            MoodEntryRow,
            BaseReferences<_$MoodDatabase, $MoodEntriesTable, MoodEntryRow>,
          ),
          MoodEntryRow,
          PrefetchHooks Function()
        > {
  $$MoodEntriesTableTableManager(_$MoodDatabase db, $MoodEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MoodEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MoodEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MoodEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> mood = const Value.absent(),
                Value<int> intensity = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<List<String>> mediaRefs = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MoodEntriesCompanion(
                id: id,
                userId: userId,
                mood: mood,
                intensity: intensity,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                mediaRefs: mediaRefs,
                syncState: syncState,
                deviceId: deviceId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String mood,
                required int intensity,
                required String note,
                required int createdAt,
                Value<int?> updatedAt = const Value.absent(),
                Value<List<String>> mediaRefs = const Value.absent(),
                required String syncState,
                required String deviceId,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MoodEntriesCompanion.insert(
                id: id,
                userId: userId,
                mood: mood,
                intensity: intensity,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                mediaRefs: mediaRefs,
                syncState: syncState,
                deviceId: deviceId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MoodEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$MoodDatabase,
      $MoodEntriesTable,
      MoodEntryRow,
      $$MoodEntriesTableFilterComposer,
      $$MoodEntriesTableOrderingComposer,
      $$MoodEntriesTableAnnotationComposer,
      $$MoodEntriesTableCreateCompanionBuilder,
      $$MoodEntriesTableUpdateCompanionBuilder,
      (
        MoodEntryRow,
        BaseReferences<_$MoodDatabase, $MoodEntriesTable, MoodEntryRow>,
      ),
      MoodEntryRow,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableCreateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      required String entryId,
      required String operation,
      required String payload,
      Value<int> attemptCount,
      Value<String?> lastError,
      Value<String?> lastErrorCode,
      Value<int> retryAfter,
      required int createdAt,
    });
typedef $$SyncQueueTableUpdateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      Value<String> entryId,
      Value<String> operation,
      Value<String> payload,
      Value<int> attemptCount,
      Value<String?> lastError,
      Value<String?> lastErrorCode,
      Value<int> retryAfter,
      Value<int> createdAt,
    });

class $$SyncQueueTableFilterComposer
    extends Composer<_$MoodDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryAfter => $composableBuilder(
    column: $table.retryAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$MoodDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryAfter => $composableBuilder(
    column: $table.retryAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$MoodDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retryAfter => $composableBuilder(
    column: $table.retryAfter,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$MoodDatabase,
          $SyncQueueTable,
          SyncQueueRow,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueRow,
            BaseReferences<_$MoodDatabase, $SyncQueueTable, SyncQueueRow>,
          ),
          SyncQueueRow,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$MoodDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> entryId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<int> retryAfter = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                entryId: entryId,
                operation: operation,
                payload: payload,
                attemptCount: attemptCount,
                lastError: lastError,
                lastErrorCode: lastErrorCode,
                retryAfter: retryAfter,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String entryId,
                required String operation,
                required String payload,
                Value<int> attemptCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<int> retryAfter = const Value.absent(),
                required int createdAt,
              }) => SyncQueueCompanion.insert(
                id: id,
                entryId: entryId,
                operation: operation,
                payload: payload,
                attemptCount: attemptCount,
                lastError: lastError,
                lastErrorCode: lastErrorCode,
                retryAfter: retryAfter,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$MoodDatabase,
      $SyncQueueTable,
      SyncQueueRow,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueRow,
        BaseReferences<_$MoodDatabase, $SyncQueueTable, SyncQueueRow>,
      ),
      SyncQueueRow,
      PrefetchHooks Function()
    >;

class $MoodDatabaseManager {
  final _$MoodDatabase _db;
  $MoodDatabaseManager(this._db);
  $$MoodEntriesTableTableManager get moodEntries =>
      $$MoodEntriesTableTableManager(_db, _db.moodEntries);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
}
