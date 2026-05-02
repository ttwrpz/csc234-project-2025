import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/app/bootstrap.dart';

/// Shared rig for `integration_test/`. Builds a `ProviderScope` with the
/// production [MoodBloomApp] inside it, plus the caller's [overrides] —
/// all Firebase-touching providers MUST be overridden by the caller so
/// the test never reaches a real backend.
///
/// Sprint 4 only ships two real flows ([auth_flow_test], [mood_log_history_flow_test]);
/// the AI-override and pattern-intervention flows are skipped stubs that
/// document the contract for Sprint 5. See those files for shape.
///
/// **Web parity:** the harness is platform-agnostic. The two real flows
/// must pass on Android emulator AND `flutter drive -d chrome` per the
/// kickoff acceptance bar.
Future<void> pumpHarness(
  WidgetTester tester, {
  required List<Override> overrides,
}) async {
  await tester.pumpWidget(
    ProviderScope(overrides: overrides, child: const MoodBloomApp()),
  );
  // One extra settle pass so router redirects + first stream emissions
  // resolve before the test starts asserting.
  await tester.pumpAndSettle();
}
