/// Date utilities shared across features. Pure Dart - no Flutter, no
/// Firebase. Domain layers are allowed to import this.
library;

/// Truncates [dt] to midnight in the local time zone. Doing the conversion
/// to local *before* the date math is what makes "an entry at 23:59 local"
/// land on the day the user expects.
///
/// Extracted from `compute_garden_state.dart` and
/// `compute_analytics_state.dart`, which both had byte-identical
/// `_atMidnightLocal` helpers.
DateTime localMidnight(DateTime dt) {
  final local = dt.toLocal();
  return DateTime(local.year, local.month, local.day);
}
