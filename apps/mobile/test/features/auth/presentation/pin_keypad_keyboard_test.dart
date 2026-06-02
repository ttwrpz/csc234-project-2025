// Verifies the PinKeypad accepts physical-keyboard entry (desktop / web):
// number-row + numpad digits append, Backspace deletes, and `onComplete`
// fires once six digits are entered.

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/presentation/widgets/pin_keypad.dart';

Future<void> _pumpKeypad(
  WidgetTester tester, {
  required void Function(String) onComplete,
  bool enabled = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(
        body: Center(
          child: PinKeypad(enabled: enabled, onComplete: onComplete),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('PinKeypad keyboard', () {
    testWidgets('number-row digits complete the PIN', (tester) async {
      String? completed;
      await _pumpKeypad(tester, onComplete: (p) => completed = p);

      for (final k in const [
        LogicalKeyboardKey.digit1,
        LogicalKeyboardKey.digit2,
        LogicalKeyboardKey.digit3,
        LogicalKeyboardKey.digit4,
        LogicalKeyboardKey.digit5,
        LogicalKeyboardKey.digit6,
      ]) {
        await tester.sendKeyEvent(k);
        await tester.pump();
      }

      expect(completed, '123456');
    });

    testWidgets('numpad digits complete the PIN', (tester) async {
      String? completed;
      await _pumpKeypad(tester, onComplete: (p) => completed = p);

      for (final k in const [
        LogicalKeyboardKey.numpad9,
        LogicalKeyboardKey.numpad8,
        LogicalKeyboardKey.numpad7,
        LogicalKeyboardKey.numpad6,
        LogicalKeyboardKey.numpad5,
        LogicalKeyboardKey.numpad4,
      ]) {
        await tester.sendKeyEvent(k);
        await tester.pump();
      }

      expect(completed, '987654');
    });

    testWidgets('Backspace removes the last digit before completion', (
      tester,
    ) async {
      String? completed;
      await _pumpKeypad(tester, onComplete: (p) => completed = p);

      // Type 1 2 3, delete the 3, then type 3 4 5 6 -> "123456".
      for (final k in const [
        LogicalKeyboardKey.digit1,
        LogicalKeyboardKey.digit2,
        LogicalKeyboardKey.digit3,
      ]) {
        await tester.sendKeyEvent(k);
        await tester.pump();
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      for (final k in const [
        LogicalKeyboardKey.digit3,
        LogicalKeyboardKey.digit4,
        LogicalKeyboardKey.digit5,
        LogicalKeyboardKey.digit6,
      ]) {
        await tester.sendKeyEvent(k);
        await tester.pump();
      }

      expect(completed, '123456');
    });

    testWidgets('disabled keypad ignores key events', (tester) async {
      String? completed;
      await _pumpKeypad(
        tester,
        enabled: false,
        onComplete: (p) => completed = p,
      );

      for (final k in const [
        LogicalKeyboardKey.digit1,
        LogicalKeyboardKey.digit2,
        LogicalKeyboardKey.digit3,
        LogicalKeyboardKey.digit4,
        LogicalKeyboardKey.digit5,
        LogicalKeyboardKey.digit6,
      ]) {
        await tester.sendKeyEvent(k);
        await tester.pump();
      }

      expect(completed, isNull);
    });
  });
}
