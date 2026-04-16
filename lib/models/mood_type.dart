import 'package:flutter/material.dart';

/// Categories that group mood types into positive, negative, or neutral.
enum MoodCategory { positive, negative, neutral }

/// The 10 supported mood types, each with display properties and garden mapping.
enum MoodType {
  happy(
    label: 'Happy',
    emoji: '\u{1F60A}',
    color: Color(0xFFFFD93D),
    category: MoodCategory.positive,
    gardenElement: 'Sunflower',
    gardenEmoji: '\u{1F33B}',
  ),
  calm(
    label: 'Calm',
    emoji: '\u{1F60C}',
    color: Color(0xFF9DB4C0),
    category: MoodCategory.positive,
    gardenElement: 'Lavender',
    gardenEmoji: '\u{1F33F}',
  ),
  grateful(
    label: 'Grateful',
    emoji: '\u{1F64F}',
    color: Color(0xFFC27A8A),
    category: MoodCategory.positive,
    gardenElement: 'Rose',
    gardenEmoji: '\u{1F339}',
  ),
  excited(
    label: 'Excited',
    emoji: '\u{1F389}',
    color: Color(0xFFFF6B6B),
    category: MoodCategory.positive,
    gardenElement: 'Tulip',
    gardenEmoji: '\u{1F337}',
  ),
  loved(
    label: 'Loved',
    emoji: '\u{1F970}',
    color: Color(0xFFFF85A2),
    category: MoodCategory.positive,
    gardenElement: 'Cherry Blossom',
    gardenEmoji: '\u{1F338}',
  ),
  sad(
    label: 'Sad',
    emoji: '\u{1F622}',
    color: Color(0xFF5B9BD5),
    category: MoodCategory.negative,
    gardenElement: 'Caterpillar',
    gardenEmoji: '\u{1F41B}',
  ),
  angry(
    label: 'Angry',
    emoji: '\u{1F620}',
    color: Color(0xFFE25050),
    category: MoodCategory.negative,
    gardenElement: 'Beetle',
    gardenEmoji: '\u{1FAB2}',
  ),
  anxious(
    label: 'Anxious',
    emoji: '\u{1F630}',
    color: Color(0xFFA78BCA),
    category: MoodCategory.negative,
    gardenElement: 'Moth',
    gardenEmoji: '\u{1F98B}',
  ),
  stressed(
    label: 'Stressed',
    emoji: '\u{1F629}',
    color: Color(0xFFE8915A),
    category: MoodCategory.negative,
    gardenElement: 'Ant',
    gardenEmoji: '\u{1F41C}',
  ),
  tired(
    label: 'Tired',
    emoji: '\u{1F634}',
    color: Color(0xFF8E8E93),
    category: MoodCategory.neutral,
    gardenElement: 'Leaf',
    gardenEmoji: '\u{1F343}',
  );

  const MoodType({
    required this.label,
    required this.emoji,
    required this.color,
    required this.category,
    required this.gardenElement,
    required this.gardenEmoji,
  });

  final String label;
  final String emoji;
  final Color color;
  final MoodCategory category;
  final String gardenElement;
  final String gardenEmoji;

  /// Parses a mood name string into a [MoodType], or null if not found.
  static MoodType? fromString(String value) {
    try {
      return MoodType.values.firstWhere(
        (m) => m.name == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}
