import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Pattern detection → cheer-up banner flow. Sprint 4 stub; Sprint 5
/// CI matrix expands. The detector + storage are wired in S4
/// (`features/garden/data/intervention_state_storage.dart`,
/// `interventionStateProvider`); S5 adds the banner UI that consumes
/// the provider and writes the persistence anchors when the user
/// dismisses or acts on the banner.
///
/// Contract for S5:
///  1. Seed history with five distinct negative days.
///  2. Pump harness, sign in, navigate to /home.
///  3. Assert the cheer-up banner renders.
///  4. Tap the banner → flow lands on the breathing exercise screen
///     (also S5).
///  5. Confirm `intervention.last_triggered_at_iso8601` is persisted.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Pattern intervention banner (S5)', () {
    testWidgets(
      'STUB — banner UI lands in S5',
      (_) async {},
      // WBS 7.3 stub — Sprint 5 CI matrix owns the implementation.
      skip: true,
    );
  });
}
