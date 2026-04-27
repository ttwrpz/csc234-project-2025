// logger.dart — stub; Day 2 fills in structured logger
class Logger {
  const Logger(this.name);
  final String name;
  void info(String msg) {}
  void warn(String msg) {}
  void error(String msg, [Object? err, StackTrace? st]) {}
}
