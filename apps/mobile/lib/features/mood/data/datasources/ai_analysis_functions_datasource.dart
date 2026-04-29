import 'package:cloud_functions/cloud_functions.dart';
import 'package:uuid/uuid.dart';

/// Thin wrapper over `FirebaseFunctions.httpsCallable('analyzeMoodText')`. The
/// repository converts the raw payload to domain types — this layer just owns
/// transport (request ID generation, region pinning, exception mapping).
class AiAnalysisFunctionsDatasource {
  AiAnalysisFunctionsDatasource(this._functions, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final FirebaseFunctions _functions;
  final Uuid _uuid;

  /// Calls the Cloud Function and returns the raw payload map. Throws typed
  /// private exceptions for the protocol-level failures (`unauthenticated`,
  /// `unavailable`, `deadline-exceeded`); other Firebase exceptions bubble
  /// unchanged so the repository can wrap them as `unknown`.
  Future<Map<String, dynamic>> call({
    required String text,
    String? locale,
  }) async {
    final callable = _functions.httpsCallable('analyzeMoodText');
    final request = <String, Object?>{
      'text': text.trim(),
      'requestId': _uuid.v4(),
      // ignore: use_null_aware_elements
      if (locale != null) 'locale': locale,
      'v': 1,
    };

    try {
      final result = await callable.call<Object?>(request);
      final data = result.data;
      if (data is! Map) {
        throw const AiAnalysisDatasourceException.parseError(
          'response data was not a map',
        );
      }
      return Map<String, dynamic>.from(data);
    } on FirebaseFunctionsException catch (e) {
      switch (e.code) {
        case 'unauthenticated':
          throw const AiAnalysisDatasourceException.unauthenticated();
        case 'unavailable':
        case 'deadline-exceeded':
          throw const AiAnalysisDatasourceException.network();
        default:
          rethrow;
      }
    }
  }
}

/// Typed exceptions the repository unwraps into `AiAnalysisFailure` variants.
/// Scoped to the data layer — the domain never sees these. Public (not
/// underscore-prefixed) so the repository in a sibling file can pattern-match
/// against the sealed hierarchy.
sealed class AiAnalysisDatasourceException implements Exception {
  const AiAnalysisDatasourceException();

  const factory AiAnalysisDatasourceException.unauthenticated() =
      AiUnauthenticatedException;
  const factory AiAnalysisDatasourceException.network() = AiNetworkException;
  const factory AiAnalysisDatasourceException.parseError(String reason) =
      AiParseErrorException;
}

class AiUnauthenticatedException extends AiAnalysisDatasourceException {
  const AiUnauthenticatedException();
}

class AiNetworkException extends AiAnalysisDatasourceException {
  const AiNetworkException();
}

class AiParseErrorException extends AiAnalysisDatasourceException {
  const AiParseErrorException(this.reason);
  final String reason;
}
