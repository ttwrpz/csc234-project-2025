import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class DateHelpers {
  static String formatFull(DateTime date) {
    return DateFormat('EEEE, MMMM d, y \'at\' h:mm a').format(date);
  }

  static String formatShort(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  static String formatRelative(DateTime date) {
    return timeago.format(date);
  }

  static String formatDateOnly(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static int calculateStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;

    final sorted = dates.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    if (sorted.first != todayOnly &&
        sorted.first != todayOnly.subtract(const Duration(days: 1))) {
      return 0;
    }

    int streak = 1;
    for (int i = 0; i < sorted.length - 1; i++) {
      final diff = sorted[i].difference(sorted[i + 1]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  static List<DateTime> getWeekDays() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(
      7,
      (i) => DateTime(monday.year, monday.month, monday.day + i),
    );
  }
}
