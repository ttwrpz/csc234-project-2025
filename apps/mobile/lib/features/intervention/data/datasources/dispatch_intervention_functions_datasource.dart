import 'package:cloud_functions/cloud_functions.dart';

import '../../../pattern_engine/domain/entities/tier.dart';

/// Thin seam over `FirebaseFunctions.httpsCallable('dispatchIntervention')`.
///
/// Called by [InterventionController] AFTER the audit doc at
/// `users/{uid}/interventions/{dispatchId}` has been written successfully.
/// The CF reads that doc back, validates tier + opt-out, then sends a
/// LOCKED per-tier FCM payload (no body comes from the request).
///
/// **PII fence:** outbound payload carries only `{ v, tier, dispatchId }`.
/// Never the quote text, never tokens, never the user's mood text. The
/// audit-doc body field is intentionally NOT sent — the CF's notification
/// payload is module-scope-constant per tier (see `dispatchIntervention.ts`).
///
/// Errors are SWALLOWED at the call site: the in-app banner has already
/// surfaced the dispatch; an FCM transport failure must not unwind the
/// user's experience. The controller logs the failure (PII-free) and
/// moves on.
///
/// Abstract so widget / controller tests can inject a recording fake
/// without touching the cloud_functions platform channel.
abstract class DispatchInterventionFunctionsDatasource {
  const DispatchInterventionFunctionsDatasource();

  /// Fires the FCM dispatch best-effort. Returns the CF's outcome string
  /// on success (`'sent'`, `'opted_out'`, `'rate_limited'`, …). Returns
  /// `null` on any transport-level error so the caller can carry on
  /// without a typed exception ladder — the in-app banner is the source
  /// of truth, not this call.
  Future<String?> call({
    required Tier tier,
    required String dispatchId,
    String? requestId,
  });
}

/// Production implementation: invokes the real callable via
/// `FirebaseFunctions.httpsCallable('dispatchIntervention')`.
class DispatchInterventionFunctionsDatasourceImpl
    implements DispatchInterventionFunctionsDatasource {
  const DispatchInterventionFunctionsDatasourceImpl(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<String?> call({
    required Tier tier,
    required String dispatchId,
    String? requestId,
  }) async {
    final callable = _functions.httpsCallable('dispatchIntervention');
    final request = <String, Object?>{
      'v': 1,
      'tier': tier.name, // 'one' | 'two' | 'three' — matches the CF schema.
      'dispatchId': dispatchId,
      'requestId': ?requestId,
    };
    try {
      final result = await callable.call<Object?>(request);
      final data = result.data;
      if (data is Map && data['outcome'] is String) {
        return data['outcome'] as String;
      }
      return null;
    } on FirebaseFunctionsException {
      // Transport failure. The in-app banner is already up; we do not
      // throw past this seam. The controller logs the runtimeType only.
      return null;
    } catch (_) {
      return null;
    }
  }
}
