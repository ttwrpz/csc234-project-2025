/// The six moods MoodBloom supports across logging, history, and the garden
/// visualization (S4). The order here is the order the selector grid will use.
enum MoodType {
  happy,
  calm,
  okay,
  sad,
  angry,
  anxious;

  /// Visual category used by the S3 line chart and the S4 garden mapping:
  /// positive → flowers, negativeMild → wilting plants, negativeStrong → rain
  /// clouds.
  MoodCategory get category => switch (this) {
    MoodType.happy || MoodType.calm => MoodCategory.positive,
    MoodType.okay || MoodType.sad => MoodCategory.negativeMild,
    MoodType.angry || MoodType.anxious => MoodCategory.negativeStrong,
  };
}

/// Bucket used by S3 charts and the S4 garden visualization.
enum MoodCategory { positive, negativeMild, negativeStrong }
