import 'package:cloud_firestore/cloud_firestore.dart';
import 'mood_type.dart';

class MoodEntry {
  final String id;
  final String userId;
  final String mood;
  final String moodCategory;
  final String text;
  final String? attachmentUrl;
  final String? attachmentType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  MoodEntry({
    required this.id,
    required this.userId,
    required this.mood,
    required this.moodCategory,
    this.text = '',
    this.attachmentUrl,
    this.attachmentType,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  MoodType? get moodType => MoodType.fromString(mood);

  MoodEntry copyWith({
    String? id,
    String? userId,
    String? mood,
    String? moodCategory,
    String? text,
    String? attachmentUrl,
    String? attachmentType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return MoodEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mood: mood ?? this.mood,
      moodCategory: moodCategory ?? this.moodCategory,
      text: text ?? this.text,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentType: attachmentType ?? this.attachmentType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'mood': mood,
      'moodCategory': moodCategory,
      'text': text,
      'attachmentUrl': attachmentUrl,
      'attachmentType': attachmentType,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory MoodEntry.fromFirestore(Map<String, dynamic> data) {
    return MoodEntry(
      id: data['id'] as String,
      userId: data['userId'] as String,
      mood: data['mood'] as String,
      moodCategory: data['moodCategory'] as String,
      text: (data['text'] as String?) ?? '',
      attachmentUrl: data['attachmentUrl'] as String?,
      attachmentType: data['attachmentType'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isSynced: true,
    );
  }

  Map<String, dynamic> toSqlite() {
    return {
      'id': id,
      'userId': userId,
      'mood': mood,
      'moodCategory': moodCategory,
      'text': text,
      'attachmentUrl': attachmentUrl,
      'attachmentType': attachmentType,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory MoodEntry.fromSqlite(Map<String, dynamic> data) {
    return MoodEntry(
      id: data['id'] as String,
      userId: data['userId'] as String,
      mood: data['mood'] as String,
      moodCategory: data['moodCategory'] as String,
      text: (data['text'] as String?) ?? '',
      attachmentUrl: data['attachmentUrl'] as String?,
      attachmentType: data['attachmentType'] as String?,
      createdAt: DateTime.parse(data['createdAt'] as String),
      updatedAt: DateTime.parse(data['updatedAt'] as String),
      isSynced: (data['isSynced'] as int) == 1,
    );
  }
}
