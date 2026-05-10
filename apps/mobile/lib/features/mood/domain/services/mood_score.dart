import 'package:freezed_annotation/freezed_annotation.dart';

import '../entities/mood_type.dart';

part 'mood_score.freezed.dart';

/// Per-entry mood score `S_t = v × (i / 5)`, where `v` is the emotion sign
/// (+1 for Joy/Calm/Okay; -1 for Sadness/Anger/Anxiety) and `i` is the
/// user-reported intensity (1..5). See ADR-0010 §2 and spec §2.1.
@freezed
abstract class MoodScore with _$MoodScore {
  const factory MoodScore({
    required double value,
    required int sign,
    required int intensity,
  }) = _MoodScore;
}

/// Computes [MoodScore] from a [MoodType] + intensity. Pure function;
/// safe to call from any layer. Intensity must be in 1..5; the function
/// asserts on out-of-range input (caller is expected to have validated
/// via `MoodEntry.create` before this point).
MoodScore computeMoodScore(MoodType mood, int intensity) {
  assert(
    intensity >= 1 && intensity <= 5,
    'intensity must be 1..5; got $intensity',
  );
  final sign = mood.category == MoodCategory.positive ? 1 : -1;
  return MoodScore(
    value: sign * (intensity / 5),
    sign: sign,
    intensity: intensity,
  );
}
