import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_centric_mobile_app/models/mood_type.dart';
import 'package:user_centric_mobile_app/widgets/mood_chip.dart';

void main() {
  group('MoodChip', () {
    testWidgets('renders mood label and emoji', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoodChip(
              moodType: MoodType.happy,
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Happy'), findsOneWidget);
      expect(find.text(MoodType.happy.emoji), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoodChip(
              moodType: MoodType.calm,
              isSelected: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(MoodChip));
      expect(tapped, isTrue);
    });

    testWidgets('shows larger emoji when selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoodChip(
              moodType: MoodType.happy,
              isSelected: true,
              onTap: () {},
            ),
          ),
        ),
      );

      // Find the emoji text widget and check its font size
      final emojiWidget = tester.widget<Text>(
        find.text(MoodType.happy.emoji),
      );
      expect(emojiWidget.style?.fontSize, 32);
    });

    testWidgets('shows smaller emoji when not selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoodChip(
              moodType: MoodType.happy,
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      final emojiWidget = tester.widget<Text>(
        find.text(MoodType.happy.emoji),
      );
      expect(emojiWidget.style?.fontSize, 24);
    });
  });
}
