abstract class Failure {
  const Failure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Could not access local data']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong on the server']);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'An unexpected error occurred']);
}
