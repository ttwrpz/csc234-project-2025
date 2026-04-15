import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_centric_mobile_app/widgets/confirmation_dialog.dart';

void main() {
  group('showConfirmationDialog', () {
    testWidgets('displays title and message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showConfirmationDialog(
                context,
                title: 'Test Title',
                message: 'Test message body',
              ),
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test message body'), findsOneWidget);
    });

    testWidgets('shows custom button text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showConfirmationDialog(
                context,
                title: 'Title',
                message: 'Message',
                confirmText: 'Delete',
                cancelText: 'Nope',
              ),
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Nope'), findsOneWidget);
    });

    testWidgets('returns false on cancel', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showConfirmationDialog(
                  context,
                  title: 'Title',
                  message: 'Message',
                );
              },
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('returns true on confirm', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showConfirmationDialog(
                  context,
                  title: 'Title',
                  message: 'Message',
                );
              },
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });
}
