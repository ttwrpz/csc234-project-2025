import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// AI suggestion → user override → save flow. Sprint 4 stub; Sprint 5
/// CI matrix expands. The contract documented here:
///  1. Open /log-mood, type into the journal field.
///  2. Wait for the AI suggestion pill to appear.
///  3. Tap a different mood than the one suggested.
///  4. Save → `MoodEntry` persisted with the user's pick (not the AI's).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('AI override flow (S5)', () {
    testWidgets(
      'STUB — full flow lands in S5',
      (_) async {},
      // WBS 7.3 stub — Sprint 5 CI matrix owns the implementation.
      skip: true,
    );
  });
}
