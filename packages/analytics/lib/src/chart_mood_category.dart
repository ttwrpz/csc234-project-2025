/// Sibling enum to the app's `MoodCategory` (lives in `apps/mobile`). Exists
/// here so `packages/analytics` stays free of any dependency on the mood
/// feature module - the screen-side glue maps from the app enum to this one.
///
/// Keep these three values in lock-step with `MoodCategory` in
/// `apps/mobile/lib/features/mood/domain/entities/mood_type.dart`.
enum ChartMoodCategory { positive, negativeMild, negativeStrong }
