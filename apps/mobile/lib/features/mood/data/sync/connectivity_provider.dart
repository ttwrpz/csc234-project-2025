import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Source of truth for online/offline state.
///
/// `connectivity_plus` 6.x+ emits `List<ConnectivityResult>` (a single device
/// can be on Wi-Fi and VPN simultaneously). We collapse the list to a single
/// `bool`: `true` when at least one transport is non-`none`.
///
/// Consumed by [MoodSyncManager]'s constructor and exposed to the
/// "pending uploads" UI badge.
final connectivityProvider = StreamProvider<bool>((ref) {
  // Debug override: when the Settings "Force offline" toggle is on, we
  // synthesise a steady stream of `false` so the rest of the app behaves
  // exactly as if Wi-Fi was unplugged. The override is opt-in (defaults
  // to false) and lives only in memory, so toggling it has no effect
  // outside the current session.
  final forced = ref.watch(debugForceOfflineProvider);
  if (forced) {
    return Stream<bool>.value(false);
  }
  return _onlineStream();
});

/// Debug-only override for [connectivityProvider]. Set from the Settings
/// screen via the "Force offline" switch. Persists for the current
/// session only.
class DebugForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  // ignore: avoid_positional_boolean_parameters
  void set(bool value) => state = value;
}

final debugForceOfflineProvider =
    NotifierProvider<DebugForceOfflineNotifier, bool>(
      DebugForceOfflineNotifier.new,
    );

/// Plain `Stream<bool>` exposed to plain-Dart consumers (e.g.
/// [MoodSyncManager]) that want a raw stream rather than an `AsyncValue`.
/// Riverpod retired `StreamProvider.stream`; the replacement is to expose
/// the underlying broadcast stream via a sibling provider.
final connectivityStreamProvider = Provider<Stream<bool>>((ref) {
  return _onlineStream();
});

Stream<bool> _onlineStream() {
  final connectivity = Connectivity();
  return connectivity.onConnectivityChanged.map(isOnlineFromResults).distinct();
}

/// Synchronous-current-value snapshot for one-shot gating logic.
///
/// Polls `Connectivity.checkConnectivity()` once. `connectivityProvider` should
/// be preferred for live updates.
final connectivityCurrentProvider = FutureProvider<bool>((ref) async {
  final results = await Connectivity().checkConnectivity();
  return isOnlineFromResults(results);
});

/// Pure helper: at least one transport that is not [ConnectivityResult.none].
///
/// Empty list (defensive — undocumented but observed on some platforms during
/// startup) is treated as offline.
bool isOnlineFromResults(List<ConnectivityResult> results) {
  if (results.isEmpty) return false;
  return results.any((r) => r != ConnectivityResult.none);
}
