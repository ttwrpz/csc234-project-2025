import 'dart:developer' as dev;

/// Thin wrapper over `dart:developer.log` that tags every message with [name].
///
/// PII redaction is the *call site's* responsibility (per CLAUDE.md):
/// never pass `entry.text`, raw email, or `userId + text` correlations
/// to any of these methods.
class Logger {
  const Logger(this.name);

  final String name;

  void debug(String msg, {Object? data}) =>
      dev.log(data == null ? msg : '$msg | $data', name: name, level: 500);

  void info(String msg, {Object? data}) =>
      dev.log(data == null ? msg : '$msg | $data', name: name, level: 800);

  void warn(String msg, {Object? data}) =>
      dev.log(data == null ? msg : '$msg | $data', name: name, level: 900);

  void error(String msg, {Object? error, StackTrace? stackTrace}) => dev.log(
    msg,
    name: name,
    level: 1000,
    error: error,
    stackTrace: stackTrace,
  );
}
