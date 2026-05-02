import 'package:freezed_annotation/freezed_annotation.dart';

part 'mood_media.freezed.dart';

/// A piece of media (image or video) the user has picked but not yet uploaded.
/// Lives only in memory while the log-mood draft is being composed; never
/// serialized. Once the entry is saved, the data layer uploads each item to
/// Storage and the resulting `gs://` URI lands in `MoodEntry.mediaRefs`.
@freezed
abstract class MoodMedia with _$MoodMedia {
  const factory MoodMedia({
    /// Device-side file URI returned by the picker. Treat as ephemeral —
    /// callers must upload before the user backgrounds the app for long.
    required String localPath,
    required MoodMediaKind kind,
    required int sizeBytes,

    /// MIME type detected from the picker (`XFile.mimeType`) or, when null,
    /// inferred from the filename via `package:mime`.
    required String mimeType,
  }) = _MoodMedia;
}

enum MoodMediaKind { image, video }
