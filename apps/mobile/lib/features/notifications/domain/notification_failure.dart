import 'package:core/core.dart';

/// All failure modes for the notifications feature. Sealed so consumers
/// pattern-matching on a returned `Result.Err` get exhaustive-switch help
/// from the analyzer.
///
/// PII: every message in this file is safe to surface to the UI and to
/// log. We never embed the FCM token, the user's mood text, or any other
/// identifier into a [NotificationFailure].
sealed class NotificationFailure extends Failure {
  const NotificationFailure({required super.message});

  const factory NotificationFailure.permissionDenied() = _PermissionDenied;
  const factory NotificationFailure.tokenUnavailable() = _TokenUnavailable;
  const factory NotificationFailure.network() = _Network;
  const factory NotificationFailure.unknown(Object? cause) = _Unknown;
}

class _PermissionDenied extends NotificationFailure {
  const _PermissionDenied()
    : super(
        message:
            'Enable notifications in your phone settings to receive cheer-up '
            'reminders.',
      );
}

class _TokenUnavailable extends NotificationFailure {
  const _TokenUnavailable()
    : super(message: 'Could not register this device for cheer-up reminders.');
}

class _Network extends NotificationFailure {
  const _Network() : super(message: 'Network unavailable.');
}

class _Unknown extends NotificationFailure {
  const _Unknown(this.cause) : super(message: 'Something went wrong.');
  final Object? cause;
}
