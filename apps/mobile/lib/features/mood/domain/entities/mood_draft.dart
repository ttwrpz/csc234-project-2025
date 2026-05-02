import 'package:freezed_annotation/freezed_annotation.dart';

import 'mood_media.dart';
import 'mood_type.dart';

part 'mood_draft.freezed.dart';

/// In-progress mood entry held by `LogMoodController` (lands in 3.2).
///
/// Lives only in memory — never serialized — so it has no JSON support.
///
/// `pickedMedia` is the local-device list of attachments the user has chosen
/// but not yet uploaded. They become `mediaRefs` (`gs://...` URIs) only after
/// a successful save flow uploads each item — see WBS 3.3.
@freezed
abstract class MoodDraft with _$MoodDraft {
  const factory MoodDraft({
    MoodType? mood,
    @Default(3) int intensity,
    @Default('') String text,
    @Default(<String>[]) List<String> mediaRefs,
    @Default(<MoodMedia>[]) List<MoodMedia> pickedMedia,
  }) = _MoodDraft;

  const MoodDraft._();

  factory MoodDraft.empty() => const MoodDraft();

  /// True when the draft satisfies all pivot-feature invariants and the user
  /// has picked a mood. Controllers gate the Save button on this getter.
  bool get isReadyToSave =>
      mood != null && intensity >= 1 && intensity <= 5 && text.length <= 500;
}
