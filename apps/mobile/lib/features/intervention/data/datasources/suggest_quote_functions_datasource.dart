import 'package:cloud_functions/cloud_functions.dart';

/// Thin wrapper over `FirebaseFunctions.httpsCallable('suggestQuote')`.
///
/// The repository ([AIQuoteRepositoryImpl]) maps the raw payload to domain
/// types and the dispatcher composes the filter on top. This layer owns
/// transport (region pinning, exception → typed enum) only.
///
/// **PII fence:** the outbound payload contains only `tier`, `weekId`,
/// `dailyAvgS`, and `dominantEmotion`. Never `userId`, `email`, raw
/// `moodText`, or any FCM token. The Dart-side unit test asserts this
/// complement to the TypeScript-side PII canary.
class SuggestQuoteFunctionsDatasource {
  SuggestQuoteFunctionsDatasource(this._functions);

  final FirebaseFunctions _functions;

  /// Returns the raw response map on success. Throws a typed
  /// [SuggestQuoteDatasourceException] for protocol-level failures; other
  /// Firebase exceptions bubble unchanged so the repository can wrap them
  /// as `QuoteFailure.unknown`.
  ///
  /// The function `name` is fixed to `'suggestQuote'`; visible-for-testing
  /// via the constructor injection (`_functions` is the swappable seam).
  Future<Map<String, dynamic>> call({
    required int tier,
    required String weekId,
    required double dailyAvgS,
    required String dominantEmotion,
  }) async {
    final callable = _functions.httpsCallable('suggestQuote');
    final request = <String, Object?>{
      'tier': tier,
      'context': <String, Object?>{
        'weekId': weekId,
        'dailyAvgS': dailyAvgS,
        'dominantEmotion': dominantEmotion,
      },
    };

    try {
      final result = await callable.call<Object?>(request);
      final data = result.data;
      if (data is! Map) {
        throw const SuggestQuoteDatasourceException.malformed(
          'response data was not a map',
        );
      }
      return Map<String, dynamic>.from(data);
    } on FirebaseFunctionsException catch (e) {
      switch (e.code) {
        case 'unauthenticated':
          throw const SuggestQuoteDatasourceException.unauthenticated();
        case 'unavailable':
        case 'deadline-exceeded':
          throw const SuggestQuoteDatasourceException.network();
        case 'resource-exhausted':
          throw const SuggestQuoteDatasourceException.rateLimited();
        case 'invalid-argument':
          throw SuggestQuoteDatasourceException.malformed(
            e.message ?? 'invalid-argument',
          );
        default:
          rethrow;
      }
    }
  }
}

/// Typed exceptions the repository unwraps into [QuoteFailure] variants.
/// Scoped to the data layer — the domain never sees these. Public so the
/// repository in a sibling file can pattern-match on the sealed hierarchy.
sealed class SuggestQuoteDatasourceException implements Exception {
  const SuggestQuoteDatasourceException();

  const factory SuggestQuoteDatasourceException.unauthenticated() =
      SuggestQuoteUnauthenticatedException;
  const factory SuggestQuoteDatasourceException.network() =
      SuggestQuoteNetworkException;
  const factory SuggestQuoteDatasourceException.rateLimited() =
      SuggestQuoteRateLimitedException;
  const factory SuggestQuoteDatasourceException.malformed(String reason) =
      SuggestQuoteMalformedException;
}

class SuggestQuoteUnauthenticatedException
    extends SuggestQuoteDatasourceException {
  const SuggestQuoteUnauthenticatedException();
}

class SuggestQuoteNetworkException extends SuggestQuoteDatasourceException {
  const SuggestQuoteNetworkException();
}

class SuggestQuoteRateLimitedException extends SuggestQuoteDatasourceException {
  const SuggestQuoteRateLimitedException();
}

class SuggestQuoteMalformedException extends SuggestQuoteDatasourceException {
  const SuggestQuoteMalformedException(this.reason);
  final String reason;
}
