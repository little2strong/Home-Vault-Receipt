import 'package:get/get.dart';

import '../error/app_exception.dart';
import '../models/receipt_document.dart';

/// Uploads original documents. This build simulates the transfer; swap the
/// body of [upload] for Firebase Storage without touching callers.
///
/// [isOnline] and [failNextUpload] are exposed so the offline queue and
/// failure recovery screens can be exercised from Help & support.
class UploadService {
  UploadService({this.step = const Duration(milliseconds: 120)});

  final Duration step;
  final isOnline = true.obs;
  final failNextUpload = false.obs;

  /// Emits progress from 0 to 1. Throws [OfflineException] when there is no
  /// connection and [UploadException] when the transfer is interrupted.
  Stream<double> upload(ReceiptDocument document) async* {
    if (!isOnline.value) throw const OfflineException();
    const chunks = 10;
    for (var i = 1; i <= chunks; i++) {
      await Future<void>.delayed(step);
      if (!isOnline.value) throw const OfflineException();
      if (failNextUpload.value && i == 7) {
        failNextUpload.value = false;
        throw const UploadException();
      }
      yield i / chunks;
    }
  }
}
