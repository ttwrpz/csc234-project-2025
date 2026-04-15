import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_centric_mobile_app/models/mood_entry.dart';
import 'package:user_centric_mobile_app/models/mood_type.dart';
import 'package:user_centric_mobile_app/widgets/mood_card.dart';

void main() {
  final entry = MoodEntry(
    id: 'test-id',
    userId: 'user-123',
    mood: 'happy',
    moodCategory: 'positive',
    text: 'Having a wonderful day!',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    updatedAt: DateTime.now(),
  );

  group('MoodCard', () {
    testWidgets('displays mood label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoodCard(entry: entry, onTap: () {}),
          ),
        ),
      );

      expect(find.text('Happy'), findsOneWidget);
    });

    testWidgets('displays mood emoji', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoodCard(entry: entry, onTap: () {}),
          ),
        ),
      );

      expect(find.text(MoodType.happy.emoji), findsOneWidget);
    });

    testWidgets('displays text preview', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoodCard(entry: entry, onTap: () {}),
          ),
        ),
      );

      expect(find.text('Having a wonderful day!'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoodCard(
              entry: entry,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(MoodCard));
      expect(tapped, isTrue);
    });

    testWidgets('shows attachment icon when entry has attachment',
        (tester) async {
      final entryWithAttachment = entry.copyWith(
        attachmentUrl: 'https://example.com/photo.jpg',
        attachmentType: 'image',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoodCard(entry: entryWithAttachment, onTap: () {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.photo_rounded), findsOneWidget);
    });

    testWidgets('shows video icon for video attachment', (tester) async {
      final entryWithVideo = entry.copyWith(
        attachmentUrl: 'https://example.com/video.mp4',
        attachmentType: 'video',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoodCard(entry: entryWithVideo, onTap: () {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.videocam_rounded), findsOneWidget);
    });
  });
}
