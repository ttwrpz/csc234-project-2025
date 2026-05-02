import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences-backed persistence for the cheer-up intervention's
/// "last triggered" + "first triggered" anchors. Read by
/// [interventionStateProvider] (in `garden/data/providers.dart`) before each
/// detector evaluation, written after a trigger fires.
///
/// The Sprint 4 detector uses these anchors:
///  * **last_triggered_at** — drives the 48h cooldown gate (suppress new
///    triggers within the cooldown window).
///  * **first_triggered_at** — drives the 10-day escalation flag.
///
/// **Lifecycle contract** (per kickoff plan §"Day 4"): when 48h+ pass
/// without a trigger evaluation returning `triggered`, callers MUST clear
/// `firstTriggeredAt` so a fresh streak starts a new escalation clock.
/// The detector itself is pure and cannot do this — the provider that
/// orchestrates evaluations enforces it via [maybeClearFirstTriggeredAt].
class InterventionStateStorage {
  const InterventionStateStorage(this._prefs);

  static const String _kLast = 'intervention.last_triggered_at_iso8601';
  static const String _kFirst = 'intervention.first_triggered_at_iso8601';

  final SharedPreferences _prefs;

  DateTime? readLastTriggeredAt() => _readIso(_kLast);
  DateTime? readFirstTriggeredAt() => _readIso(_kFirst);

  Future<void> writeLastTriggeredAt(DateTime t) async {
    await _prefs.setString(_kLast, t.toUtc().toIso8601String());
  }

  Future<void> writeFirstTriggeredAt(DateTime t) async {
    await _prefs.setString(_kFirst, t.toUtc().toIso8601String());
  }

  Future<void> clearFirstTriggeredAt() async {
    await _prefs.remove(_kFirst);
  }

  /// Lifecycle helper: when no trigger has fired in the cooldown window
  /// (48h+) AND the current evaluation does NOT trigger, the
  /// `firstTriggeredAt` anchor must be cleared so the next streak starts
  /// fresh. Pass [now] from the same source the detector uses.
  Future<void> maybeClearFirstTriggeredAt({
    required DateTime now,
    required bool currentlyTriggered,
  }) async {
    if (currentlyTriggered) return;
    final last = readLastTriggeredAt();
    if (last == null) {
      // No prior trigger ever → nothing to clear.
      return;
    }
    if (now.difference(last) >= const Duration(hours: 48)) {
      await clearFirstTriggeredAt();
    }
  }

  DateTime? _readIso(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }
}
