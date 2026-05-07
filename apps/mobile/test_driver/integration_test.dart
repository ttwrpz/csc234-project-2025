// Driver entrypoint for `flutter drive --driver=test_driver/integration_test.dart`.
// The canonical Flutter pattern: a one-line file that boots the
// `integration_test` runner. The real test bodies live in
// `integration_test/<flow>.dart` and are passed via `--target=...`.
//
// Used for the Sprint 5 Day 4 Chrome web matrix per S5 plan §8 and
// kickoff §"Acceptance criteria" ("Integration test for login flow
// passes on Android emulator AND Chrome web"). On Chrome the driver
// boots a real Chrome instance, loads the test target, and reports the
// result back via the integration_test plugin's WebDriver bridge.
//
// Reference: https://docs.flutter.dev/testing/integration-tests

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
