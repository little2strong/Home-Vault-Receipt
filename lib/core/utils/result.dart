import '../error/failures.dart';

sealed class Result<T> {
  const Result();

  R when<R>({
    required R Function(T data) ok,
    required R Function(Failure failure) err,
  }) {
    return switch (this) {
      Ok<T>(:final data) => ok(data),
      Err<T>(:final failure) => err(failure),
    };
  }
}

final class Ok<T> extends Result<T> {
  const Ok(this.data);

  final T data;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;
}
