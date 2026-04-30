import 'package:core/core.dart';

/// All failure modes for the mood feature. Sealed so every consumer that
/// pattern-matches gets exhaustive-switch help from the analyzer.
sealed class MoodFailure extends Failure {
  const MoodFailure({required super.message});

  const factory MoodFailure.invalidIntensity(int value) = _InvalidIntensity;
  const factory MoodFailure.textTooLong(int length) = _TextTooLong;
  const factory MoodFailure.missingMood() = _MissingMood;
  const factory MoodFailure.malformed(String reason) = _Malformed;
  const factory MoodFailure.locked() = _Locked;
  const factory MoodFailure.notFound(String id) = _NotFound;
  const factory MoodFailure.network() = _Network;
  const factory MoodFailure.server(String reason) = _Server;
  const factory MoodFailure.unknown(Object? cause) = _Unknown;
}

class _InvalidIntensity extends MoodFailure {
  const _InvalidIntensity(this.value)
    : super(message: 'Intensity must be 1..5; got value.');
  final int value;
}

class _TextTooLong extends MoodFailure {
  const _TextTooLong(this.length)
    : super(message: 'Mood text exceeds 500-character limit.');
  final int length;
}

class _MissingMood extends MoodFailure {
  const _MissingMood() : super(message: 'Pick a mood before saving.');
}

class _Malformed extends MoodFailure {
  const _Malformed(this.reason) : super(message: 'Malformed mood entry.');
  final String reason;
}

class _Locked extends MoodFailure {
  const _Locked()
    : super(message: 'This entry is older than 24h and cannot be edited.');
}

class _NotFound extends MoodFailure {
  const _NotFound(this.id) : super(message: 'Mood entry not found.');
  final String id;
}

class _Network extends MoodFailure {
  const _Network() : super(message: 'Network unavailable.');
}

class _Server extends MoodFailure {
  const _Server(this.reason) : super(message: 'Server error.');
  final String reason;
}

class _Unknown extends MoodFailure {
  const _Unknown(this.cause) : super(message: 'Unknown error.');
  final Object? cause;
}
