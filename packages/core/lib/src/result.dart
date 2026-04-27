// result.dart — stub; Day 2 fills in sealed Result<T, F>
// ignore_for_file: unused_element
sealed class Result<T, F> {
  const Result();
}

class Ok<T, F> extends Result<T, F> {
  final T value;
  const Ok(this.value);
}

class Err<T, F> extends Result<T, F> {
  final F failure;
  const Err(this.failure);
}
