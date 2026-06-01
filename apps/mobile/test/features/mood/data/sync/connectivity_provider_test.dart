import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/mood/data/sync/connectivity_provider.dart';

// We unit-test the pure mapping helper [isOnlineFromResults] rather than the
// `connectivityProvider` itself. Riverpod's StreamProvider is a one-line wrapper
// (`.map(isOnlineFromResults).distinct()`) - exercising it would require
// mocking the `connectivity_plus` MethodChannel, which is fiddly across
// platforms and adds zero coverage over the helper. Documented choice.

void main() {
  group('isOnlineFromResults - connectivity_plus 6.x/7.x list semantics', () {
    test('empty list → offline (defensive default)', () {
      expect(isOnlineFromResults(const <ConnectivityResult>[]), isFalse);
    });

    test('[none] → offline', () {
      expect(isOnlineFromResults(const [ConnectivityResult.none]), isFalse);
    });

    test('[none, none] → offline', () {
      expect(
        isOnlineFromResults(const [
          ConnectivityResult.none,
          ConnectivityResult.none,
        ]),
        isFalse,
      );
    });

    test('[wifi] → online', () {
      expect(isOnlineFromResults(const [ConnectivityResult.wifi]), isTrue);
    });

    test('[wifi, mobile] → online', () {
      expect(
        isOnlineFromResults(const [
          ConnectivityResult.wifi,
          ConnectivityResult.mobile,
        ]),
        isTrue,
      );
    });

    test('[none, wifi] (rare mid-transition state) → online', () {
      expect(
        isOnlineFromResults(const [
          ConnectivityResult.none,
          ConnectivityResult.wifi,
        ]),
        isTrue,
      );
    });
  });
}
