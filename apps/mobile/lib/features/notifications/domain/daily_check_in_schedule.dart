/// Default reminder time when the user has never picked one: 9:30 PM
/// (21:30 in 24h form), matching the onboarding notification slide's
/// stated default. Used by the controller to seed cold-start state.
const int defaultDailyCheckInHour = 21;
const int defaultDailyCheckInMinute = 30;

/// Pure-Dart value type for the self-set daily check-in reminder.
///
/// Carries the on/off flag plus the wall-clock [hour]/[minute] the user
/// picked. Lives in `domain/` so it has zero Flutter/Firebase imports and
/// the next-occurrence math is unit-testable without a plugin or a
/// `TimeOfDay`. The presentation layer maps this to/from `TimeOfDay`; the
/// data layer maps it to/from SharedPreferences ints.
class DailyCheckInSchedule {
  const DailyCheckInSchedule({
    required this.enabled,
    required this.hour,
    required this.minute,
  }) : assert(hour >= 0 && hour <= 23, 'hour must be 0..23'),
       assert(minute >= 0 && minute <= 59, 'minute must be 0..59');

  /// Whether the reminder is armed.
  final bool enabled;

  /// Reminder hour in 24h form, 0..23.
  final int hour;

  /// Reminder minute, 0..59.
  final int minute;

  DailyCheckInSchedule copyWith({bool? enabled, int? hour, int? minute}) {
    return DailyCheckInSchedule(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  /// The next wall-clock [DateTime] this reminder should fire, computed
  /// relative to [from]. If [from] is before today's [hour]:[minute], the
  /// occurrence is today; otherwise it rolls to tomorrow. At exactly the
  /// target time we roll forward a day so a re-schedule triggered by the
  /// user tapping "on" at 21:30:00 doesn't fire instantly.
  ///
  /// Pure and timezone-agnostic - operates in the same zone as [from].
  /// The scheduler wraps the result in a `TZDateTime` before handing it
  /// to the platform plugin; keeping the arithmetic here (not in the
  /// data layer) makes the roll-forward rule testable.
  DateTime nextOccurrenceAfter(DateTime from) {
    final todayAtTime = DateTime(from.year, from.month, from.day, hour, minute);
    if (todayAtTime.isAfter(from)) return todayAtTime;
    return todayAtTime.add(const Duration(days: 1));
  }

  @override
  bool operator ==(Object other) =>
      other is DailyCheckInSchedule &&
      other.enabled == enabled &&
      other.hour == hour &&
      other.minute == minute;

  @override
  int get hashCode => Object.hash(enabled, hour, minute);
}
