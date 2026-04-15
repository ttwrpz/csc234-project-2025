import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/mood_entry.dart';
import '../../models/mood_type.dart';
import '../../utils/date_helpers.dart';
import '../../widgets/mood_card.dart';

class MoodCalendarView extends StatefulWidget {
  final List<MoodEntry> entries;
  final void Function(MoodEntry entry) onEntryTap;

  const MoodCalendarView({
    super.key,
    required this.entries,
    required this.onEntryTap,
  });

  @override
  State<MoodCalendarView> createState() => _MoodCalendarViewState();
}

class _MoodCalendarViewState extends State<MoodCalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  List<MoodEntry> _getEntriesForDay(DateTime day) {
    return widget.entries
        .where((e) => DateHelpers.isSameDay(e.createdAt, day))
        .toList();
  }

  bool get _isOnCurrentMonth =>
      _focusedDay.year == DateTime.now().year &&
      _focusedDay.month == DateTime.now().month;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!_isOnCurrentMonth)
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime.now();
                    _selectedDay = DateTime.now();
                  });
                },
                icon: const Icon(Icons.today, size: 16),
                label: const Text('Today'),
              ),
            ),
          ),
        TableCalendar<MoodEntry>(
          firstDay: DateTime(2024),
          lastDay: DateTime.now().add(const Duration(days: 1)),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) =>
              _selectedDay != null && isSameDay(_selectedDay, day),
          eventLoader: _getEntriesForDay,
          calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.monday,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: Theme.of(context).textTheme.headlineSmall!,
            leftChevronIcon: Icon(
              Icons.chevron_left,
              color: Theme.of(context).colorScheme.primary,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            todayTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            selectedDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              shape: BoxShape.circle,
            ),
            markerSize: 6,
            markersMaxCount: 3,
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (events.isEmpty) return null;
              return Positioned(
                bottom: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (events.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${events.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                          ),
                        ),
                      )
                    else
                      ...events.take(3).map((entry) {
                        final mood = MoodType.fromString(entry.mood);
                        return Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: mood?.color ?? Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                  ],
                ),
              );
            },
          ),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
        ),
        const Divider(),
        // Entries for selected day
        Expanded(
          child: _selectedDay == null
              ? Center(
                  child: Text(
                    'Select a date to view entries',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              : _buildDayEntries(),
        ),
      ],
    );
  }

  Widget _buildDayEntries() {
    final dayEntries = _getEntriesForDay(_selectedDay!);
    if (dayEntries.isEmpty) {
      return Center(
        child: Text(
          'No entries for this day',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: dayEntries.length,
      itemBuilder: (context, index) {
        return MoodCard(
          entry: dayEntries[index],
          onTap: () => widget.onEntryTap(dayEntries[index]),
        );
      },
    );
  }
}
