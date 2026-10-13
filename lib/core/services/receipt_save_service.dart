import '../error/app_exception.dart';
import '../models/receipt_model.dart';
import '../repositories/receipt_repository.dart';
import 'upload_service.dart';

enum SaveOutcome { saved, queued, failed }

/// Saves a confirmed receipt local-first, then uploads its originals.
///
/// The record is written to the device before any network work, so nothing
/// the user confirmed is lost. Retrying reuses the same record id, so a retry
/// can never create a duplicate.
class ReceiptSaveService {
  ReceiptSaveService({required this._receipts, required this._uploads});

  final ReceiptRepository _receipts;
  final UploadService _uploads;

  bool get isOnline => _uploads.isOnline.value;

  /// Throws [QuotaExceededException] before writing anything when the pilot
  /// vault is full.
  Future<SaveOutcome> save(
    Receipt receipt, {
    void Function(double progress)? onProgress,
  }) async {
    final wasSaved = _receipts.byId(receipt.id)?.isSaved ?? false;
    if (!wasSaved && _receipts.isAtPilotLimit) {
      throw const QuotaExceededException();
    }

    var record = await _receipts.upsert(
      receipt.copyWith(status: ReceiptStatus.queued),
    );
    if (!isOnline) return SaveOutcome.queued;

    try {
      final documents = [...record.documents];
      final pending = [
        for (var i = 0; i < documents.length; i++)
          if (!documents[i].uploaded) i,
      ];
      for (var n = 0; n < pending.length; n++) {
        final index = pending[n];
        await for (final p in _uploads.upload(documents[index])) {
          onProgress?.call((n + p) / pending.length);
        }
        documents[index] = documents[index].copyWith(uploaded: true);
        record = await _receipts.upsert(record.copyWith(documents: documents));
      }
      onProgress?.call(1);
      await _receipts.commit(record);
      return SaveOutcome.saved;
    } on OfflineException {
      return SaveOutcome.queued;
    } on UploadException {
      await _receipts.upsert(record.copyWith(status: ReceiptStatus.failed));
      return SaveOutcome.failed;
    }
  }

  /// Retries every queued or failed record. Returns how many were saved.
  Future<int> retryPending() async {
    var saved = 0;
    final waiting = _receipts.pending.where(
      (r) => r.status != ReceiptStatus.draft,
    );
    for (final record in waiting.toList()) {
      try {
        if (await save(record) == SaveOutcome.saved) saved++;
      } on QuotaExceededException {
        break;
      }
    }
    return saved;
  }
}
