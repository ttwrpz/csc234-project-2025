import 'package:design_system/design_system.dart';

import '../../domain/entities/mood_type.dart';

/// Adapter from the domain [MoodType] (6 values) to the design-system
/// [MbMoodKind]. Kept in the presentation layer so the design_system package
/// stays free of any apps/mobile dependency, and so domain entities never
/// reach for `MbMoodKind` directly.
extension MoodTypeMbMoodKind on MoodType {
  MbMoodKind get mbKind => switch (this) {
    MoodType.happy => MbMoodKind.happy,
    MoodType.calm => MbMoodKind.calm,
    MoodType.okay => MbMoodKind.okay,
    MoodType.sad => MbMoodKind.sad,
    MoodType.angry => MbMoodKind.angry,
    MoodType.anxious => MbMoodKind.anxious,
  };
}
