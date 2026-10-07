/// Thrown by data sources; converted to [Failure]s by repositories.
class CacheException implements Exception {
  const CacheException([this.message = 'Local storage error']);

  final String message;

  @override
  String toString() => 'CacheException: $message';
}

class ServerException implements Exception {
  const ServerException([this.message = 'Server error']);

  final String message;

  @override
  String toString() => 'ServerException: $message';
}
