/// The six moods MoodBloom supports across logging, history, and the garden
/// visualization (S4). The order here is the order the selector grid will use.
enum MoodType {
  happy,
  calm,
  okay,
  sad,
  angry,
  anxious;

  /// Sign bucket for `computeMoodScore` (ADR-0010, spec §2.1). Joy/Calm/Okay
  /// sit in `positive` (sign +1); Sadness/Anger/Anxiety sit in negativeMild /
  /// negativeStrong (both sign -1; the strong/mild distinction is a holdover
  /// for legacy callers and is deprecated for new code).
  MoodCategory get category => switch (this) {
    MoodType.happy || MoodType.calm || MoodType.okay => MoodCategory.positive,
    MoodType.sad => MoodCategory.negativeMild,
    MoodType.angry || MoodType.anxious => MoodCategory.negativeStrong,
  };
}

/// Bucket used by S3 charts and the S4 garden visualization.
enum MoodCategory { positive, negativeMild, negativeStrong }
