import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sliding 5-minute idle window per ADR-0013 Decision D.
const Duration _idleWindow = Duration(minutes: 5);

/// App-background threshold per ADR-0013 Decision D §5. A user who
/// backgrounds the app for less than this keeps the unlock; longer
/// backgrounds clear it so a roommate picking up a phone that was
/// last looked at "this morning" can't browse the journal.
const Duration _backgroundResetThreshold = Duration(seconds: 30);

/// State of the History route's session unlock (ADR-0013 Decision D).
///
/// Three semantically-distinct states are encoded:
///   - `lastActivityAt == null` → locked. Router redirects to
///     `/unlock-history`.
///   - `lastActivityAt` within the last 5 minutes → unlocked. Router
///     allows the route through.
///   - `lastActivityAt` older than 5 minutes → stale, treated as
///     locked. Router redirects.
@immutable
class HistoryUnlockState {
  const HistoryUnlockState({this.lastActivityAt});

  /// Null when the History route has never been unlocked this session
  /// (or was reset by sign-out / background-too-long).
  final DateTime? lastActivityAt;

  /// Returns true iff the route is currently unlocked AND within the
  /// 5-minute idle window. The clock is injected for tests.
  bool isUnlocked({required DateTime now}) {
    final last = lastActivityAt;
    if (last == null) return false;
    return now.difference(last) < _idleWindow;
  }
}

/// Notifier owning the History unlock state plus the
/// `WidgetsBindingObserver` that clears the unlock when the app has
/// been backgrounded for > 30 s.
///
/// Per ADR-0013 Open Follow-up #3, the lifecycle observer lives next
/// to this notifier rather than in `router.dart` so the router file
/// stays lean.
class HistoryUnlockedThisSessionNotifier extends Notifier<HistoryUnlockState>
    with WidgetsBindingObserver {
  /// Optional clock injection — tests pass a fake to control idle
  /// transitions deterministically.
  DateTime Function()? clockOverride;

  DateTime _now() => (clockOverride ?? DateTime.now)();

  DateTime? _pausedAt;

  @override
  HistoryUnlockState build() {
    final binding = WidgetsBinding.instance;
    binding.addObserver(this);
    ref.onDispose(() => binding.removeObserver(this));
    return const HistoryUnlockState();
  }

  /// Records a fresh unlock — call this after a successful biometric
  /// or PIN verification. Sets `lastActivityAt = now`.
  void unlock() {
    state = HistoryUnlockState(lastActivityAt: _now());
  }

  /// Resets the sliding window — call this on every meaningful tap
  /// inside the History route (entry list tap, scroll-into-view,
  /// etc.). Tapping outside the History route should NOT touch this
  /// timer (Decision D §4).
  void touch() {
    if (state.lastActivityAt == null) return;
    state = HistoryUnlockState(lastActivityAt: _now());
  }

  /// Hard-locks. Called on sign-out (parallel to the existing
  /// `biometricUnlockedThisSessionProvider` reset on sign-out, see
  /// `router.dart` line 71..73 for the pattern).
  void lock() {
    state = const HistoryUnlockState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _pausedAt = _now();
      case AppLifecycleState.resumed:
        final pausedAt = _pausedAt;
        if (pausedAt != null &&
            _now().difference(pausedAt) >= _backgroundResetThreshold) {
          lock();
        }
        _pausedAt = null;
      case AppLifecycleState.detached:
        // Detach is terminal — clearing the unlock is the safe default
        // even though a fresh launch rebuilds the provider anyway.
        lock();
        _pausedAt = null;
    }
  }
}

final historyUnlockedThisSessionProvider =
    NotifierProvider<HistoryUnlockedThisSessionNotifier, HistoryUnlockState>(
      HistoryUnlockedThisSessionNotifier.new,
    );
