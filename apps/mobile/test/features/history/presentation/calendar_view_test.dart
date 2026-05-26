import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moodbloom/features/history/presentation/calendar_view.dart';
import 'package:moodbloom/features/mood/data/providers.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

/// A long-lived stream backing the `myMoodsStreamProvider` override. We use a
/// controller (not `Stream.value`) so the StreamProvider stays open and
/// `value` is populated by the time widget tree settles.
Stream<List<MoodEntry>> _moodStream(List<MoodEntry> entries) {
  final controller = StreamController<List<MoodEntry>>();
  controller.add(entries);
  return controller.stream;
}

GoRouter _buildRouter({String? initialLocation, void Function(String)? onGo}) {
  return GoRouter(
    initialLocation: initialLocation ?? '/history',
    routes: [
      GoRoute(
        path: '/history',
        builder: (_, _) => const Scaffold(body: CalendarView()),
      ),
      GoRoute(
        path: '/history/:id',
        builder: (_, state) {
          final id = state.pathParameters['id'] ?? '';
          onGo?.call('/history/$id');
          return Scaffold(body: Center(child: Text('detail-$id')));
        },
      ),
    ],
  );
}

Future<void> _pumpCalendar(
  WidgetTester tester, {
  required List<MoodEntry> entries,
  void Function(String)? onGo,
}) async {
  await tester.binding.setSurfaceSize(const Size(600, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        myMoodsStreamProvider.overrideWith((_) => _moodStream(entries)),
      ],
      child: MaterialApp.router(
        theme: buildLightTheme(),
        routerConfig: _buildRouter(onGo: onGo),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

MoodEntry _entry({
  required String id,
  required MoodType mood,
  required int intensity,
  required DateTime createdAt,
}) {
  return MoodEntry(
    id: id,
    userId: 'u-1',
    mood: mood,
    intensity: intensity,
    text: '',
    createdAt: createdAt,
  );
}

void main() {
  group('CalendarView', () {
    testWidgets('empty state renders compassionate copy', (tester) async {
      await _pumpCalendar(tester, entries: const []);
      expect(
        find.text('No moods this month - tap Log Mood to start.'),
        findsOneWidget,
      );
      // No streak-shaming copy.
      expect(find.textContaining('streak'), findsNothing);
      expect(find.textContaining('missed'), findsNothing);
    });

    testWidgets('one entry today renders a dot in today\'s cell', (
      tester,
    ) async {
      final today = DateTime.now();
      final state = _entry(
        id: 'e1',
        mood: MoodType.happy,
        intensity: 4,
        createdAt: today,
      );
      await _pumpCalendar(tester, entries: [state]);

      // The day-number text is present.
      expect(find.text('${today.day}'), findsOneWidget);

      // The cell should be tappable (Semantics with button:true and the
      // "Day N, 1 entry" label).
      final semantics = find.bySemanticsLabel(
        RegExp('Day ${today.day}, 1 entry'),
      );
      expect(semantics, findsOneWidget);

      // Empty-state copy must NOT appear.
      expect(
        find.text('No moods this month - tap Log Mood to start.'),
        findsNothing,
      );
    });

    testWidgets('tapping a day with an entry navigates to /history/<id>', (
      tester,
    ) async {
      final today = DateTime.now();
      final entry = _entry(
        id: 'most-recent',
        mood: MoodType.happy,
        intensity: 3,
        createdAt: today,
      );
      String? navigated;
      await _pumpCalendar(
        tester,
        entries: [entry],
        onGo: (loc) => navigated = loc,
      );

      // Find the day cell by its semantics label and tap it.
      final cell = find.bySemanticsLabel(RegExp('Day ${today.day}, 1 entry'));
      expect(cell, findsOneWidget);
      await tester.tap(cell);
      await tester.pumpAndSettle();

      expect(navigated, '/history/most-recent');
      expect(find.text('detail-most-recent'), findsOneWidget);
    });

    testWidgets('tapping a day with no entries does nothing', (tester) async {
      // No entries this month at all — every day cell is non-interactive.
      await _pumpCalendar(tester, entries: const []);

      // Find any "Day N, no entries" cell. Day 1 is always present on a
      // month grid.
      final blankCell = find.bySemanticsLabel(RegExp('Day 1, no entries'));
      expect(blankCell, findsOneWidget);

      // Tapping should NOT route us anywhere.
      await tester.tap(blankCell, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Still on the calendar — empty-state copy still visible.
      expect(
        find.text('No moods this month - tap Log Mood to start.'),
        findsOneWidget,
      );
    });

    testWidgets('next-month button is disabled in the current month', (
      tester,
    ) async {
      await _pumpCalendar(tester, entries: const []);

      final nextButton = tester.widget<MbIconButton>(
        find.widgetWithIcon(MbIconButton, Icons.chevron_right),
      );
      expect(
        nextButton.onPressed,
        isNull,
        reason:
            'next-month chevron must be disabled when viewing the current '
            'month so users cannot navigate to the future',
      );
    });

    testWidgets(
      'previous-month chevron is enabled and updates the visible month',
      (tester) async {
        await _pumpCalendar(tester, entries: const []);

        // Capture the initial month label.
        final now = DateTime.now();
        final monthNames = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ];
        final currentLabel = '${monthNames[now.month - 1]} ${now.year}';
        expect(find.text(currentLabel), findsOneWidget);

        await tester.tap(find.widgetWithIcon(MbIconButton, Icons.chevron_left));
        await tester.pumpAndSettle();

        // Now showing the previous month.
        final prev = DateTime(now.year, now.month - 1, 1);
        final prevLabel = '${monthNames[prev.month - 1]} ${prev.year}';
        expect(find.text(prevLabel), findsOneWidget);
        expect(find.text(currentLabel), findsNothing);
      },
    );
  });
}
