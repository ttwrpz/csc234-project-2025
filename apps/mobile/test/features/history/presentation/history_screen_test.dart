import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moodbloom/features/history/presentation/calendar_view.dart';
import 'package:moodbloom/features/history/presentation/history_screen.dart';
import 'package:moodbloom/features/mood/data/providers.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';

Stream<List<MoodEntry>> _moodStream(List<MoodEntry> entries) {
  final controller = StreamController<List<MoodEntry>>();
  controller.add(entries);
  return controller.stream;
}

Future<void> _pumpHistory(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(600, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        myMoodsStreamProvider.overrideWith((_) => _moodStream(const [])),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/history',
          routes: [
            GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
            GoRoute(
              path: '/history/:id',
              builder: (_, state) => Scaffold(
                body: Center(
                  child: Text('detail-${state.pathParameters['id']}'),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('HistoryScreen', () {
    testWidgets('renders both List and Calendar tabs', (tester) async {
      await _pumpHistory(tester);
      expect(find.text('List'), findsOneWidget);
      expect(find.text('Calendar'), findsOneWidget);
    });

    testWidgets(
      'starts on the List tab — CalendarView is not in the foreground',
      (tester) async {
        await _pumpHistory(tester);
        // The list-empty-state copy is visible.
        expect(find.text('Your history starts here.'), findsOneWidget);
      },
    );

    testWidgets('tapping the Calendar tab swaps the body to CalendarView', (
      tester,
    ) async {
      await _pumpHistory(tester);

      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();

      expect(find.byType(CalendarView), findsOneWidget);
      expect(
        find.text('No moods this month — tap Log Mood to start.'),
        findsOneWidget,
      );
    });
  });
}
