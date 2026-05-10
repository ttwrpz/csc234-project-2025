import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/disclaimer/domain/disclaimer_copy.dart';
import 'package:moodbloom/features/disclaimer/presentation/widgets/disclaimer_panel.dart';

void main() {
  group('DisclaimerPanel', () {
    testWidgets('renders the full disclaimer text byte-for-byte', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(body: DisclaimerPanel()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(DisclaimerCopy.full), findsOneWidget);
    });

    testWidgets('renders the medical-information icon (visual cue)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(body: DisclaimerPanel()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.medical_information_outlined), findsOneWidget);
    });

    testWidgets('renders no interactive elements — read-only by construction', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(body: DisclaimerPanel()),
        ),
      );
      await tester.pumpAndSettle();

      // No buttons / switches / radios should appear in this read-only
      // surface — the (S5) ack dialog owns the "I understand" path.
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(Switch), findsNothing);
    });
  });
}
