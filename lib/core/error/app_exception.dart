class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// The free pilot stores at most `ReceiptRepository.pilotLimit` receipts.
class QuotaExceededException extends AppException {
  const QuotaExceededException()
    : super('Your pilot vault is full. Export or delete records to make room.');
}

/// No connection: the record stays queued on this device.
class OfflineException extends AppException {
  const OfflineException() : super('Waiting for connection');
}

/// The connection dropped mid-upload: the draft is preserved for retry.
class UploadException extends AppException {
  const UploadException([super.message = 'Connection interrupted']);
}

class LockedDocumentException extends AppException {
  const LockedDocumentException()
    : super('We cannot read a password-protected document.');
}

class UnreadableDocumentException extends AppException {
  const UnreadableDocumentException()
    : super('Some printed details could not be recognised.');
}

class AuthException extends AppException {
  const AuthException(super.message);
}
