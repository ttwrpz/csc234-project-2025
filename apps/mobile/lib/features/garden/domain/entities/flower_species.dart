import '../../../mood/domain/entities/mood_type.dart';

/// The six flower species used as a per-entry visual cue across the
/// history list, the garden's "Recent moods" preview, and (in future
/// sprints) the weekly-harvest summary surfaces.
///
/// The mapping from `MoodType` was chosen by the team in the v1.0
/// redesign polish round and is intentionally fixed: each mood owns a
/// single species so the user can learn the visual vocabulary at a
/// glance.
///
/// This file is pure Dart on purpose — no `package:flutter` imports —
/// so the mapping can be unit-tested without spinning up a widget tree.
/// The actual painting lives in
/// `presentation/widgets/flower_sprite.dart`.
enum FlowerSpecies {
  sunflower,
  forgetMeNot,
  daisy,
  poppy,
  fern,
  lavender;

  /// Pure mapping from a [MoodType] to the canonical flower species
  /// chosen by the team in the v1.0 redesign polish round.
  ///
  /// `fern` is technically a leaf rather than a flower; it represents
  /// `MoodType.anxious` because the team wanted a calming, non-blooming
  /// silhouette for high-arousal negative moods.
  static FlowerSpecies forMood(MoodType mood) => switch (mood) {
    MoodType.happy => FlowerSpecies.sunflower,
    MoodType.sad => FlowerSpecies.forgetMeNot,
    MoodType.okay => FlowerSpecies.daisy,
    MoodType.angry => FlowerSpecies.poppy,
    MoodType.anxious => FlowerSpecies.fern,
    MoodType.calm => FlowerSpecies.lavender,
  };
}
