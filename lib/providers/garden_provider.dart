import 'dart:math';
import 'package:flutter/material.dart';
import '../models/mood_entry.dart';
import '../models/mood_type.dart';

class GardenElement {
  final String id;
  final MoodType moodType;
  final Offset position;
  final double size;
  final double opacity;
  final DateTime createdAt;

  GardenElement({
    required this.id,
    required this.moodType,
    required this.position,
    this.size = 40,
    this.opacity = 1.0,
    required this.createdAt,
  });

  bool get isBug => moodType.category == MoodCategory.negative;
}

class GardenProvider extends ChangeNotifier {
  final List<GardenElement> _elements = [];
  double _animationSpeed = 2.0;

  List<GardenElement> get elements => _elements;
  double get animationSpeed => _animationSpeed;

  void setAnimationSpeed(double speed) {
    _animationSpeed = speed;
    notifyListeners();
  }

  void updateGarden(List<MoodEntry> entries) {
    _elements.clear();
    final random = Random(42); // Seeded for consistent layout

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final moodType = MoodType.fromString(entry.mood);
      if (moodType == null) continue;

      // Calculate fade for negative moods based on age
      double opacity = 1.0;
      if (moodType.category == MoodCategory.negative) {
        final age = DateTime.now().difference(entry.createdAt).inHours;
        final fadeHours = (72 / _animationSpeed).round(); // Fade over 72h at 1x
        opacity = (1.0 - (age / fadeHours)).clamp(0.1, 1.0);
      }

      // Position based on mood category for natural layering
      final x = 0.05 + random.nextDouble() * 0.9;
      double y;
      if (moodType.category == MoodCategory.positive) {
        y = 0.4 + random.nextDouble() * 0.5; // Flowers on ground
      } else if (moodType.category == MoodCategory.negative) {
        y = 0.1 + random.nextDouble() * 0.55; // Bugs flying above
      } else {
        y = 0.25 + random.nextDouble() * 0.55; // Neutral scattered
      }

      _elements.add(
        GardenElement(
          id: entry.id,
          moodType: moodType,
          position: Offset(x, y),
          size: 32 + random.nextDouble() * 16,
          opacity: opacity,
          createdAt: entry.createdAt,
        ),
      );
    }
    notifyListeners();
  }
}
