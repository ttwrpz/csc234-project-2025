/// A pure-Dart sealed `Result<T, F>` for fallible operations.
///
/// Domain repositories return [Result] instead of throwing so that callers can
/// pattern-match on success/failure without try/catch. Avoid Freezed here so
/// `packages/core` does not need build_runner.
sealed class Result<T, F> {
  const Result();
}

final class Ok<T, F> extends Result<T, F> {
  const Ok(this.value);
  final T value;
}

final class Err<T, F> extends Result<T, F> {
  const Err(this.failure);
  final F failure;
}

extension ResultX<T, F> on Result<T, F> {
  /// Collapses the `Result` into a single `R` by running [ok] or [err].
  R fold<R>({required R Function(T) ok, required R Function(F) err}) =>
      switch (this) {
        Ok(:final value) => ok(value),
        Err(:final failure) => err(failure),
      };

  /// Maps the success value, leaving any failure untouched.
  Result<R, F> map<R>(R Function(T) f) => switch (this) {
    Ok(:final value) => Ok(f(value)),
    Err(:final failure) => Err(failure),
  };

  /// Maps the failure value, leaving any success untouched.
  Result<T, G> mapErr<G>(G Function(F) f) => switch (this) {
    Ok(:final value) => Ok(value),
    Err(:final failure) => Err(f(failure)),
  };

  /// Returns the wrapped value, or `null` if this is an [Err].
  T? getOrNull() => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  /// Returns the wrapped failure, or `null` if this is an [Ok].
  F? errOrNull() => switch (this) {
    Ok() => null,
    Err(:final failure) => failure,
  };
}
