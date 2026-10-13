import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/models/receipt_model.dart';
import '../../../core/repositories/receipt_repository.dart';
import '../../../core/services/receipt_save_service.dart';
import '../../../core/services/upload_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/toast.dart';

/// 37 · Offline queue: everything confirmed or drafted but not yet saved.
class PendingController extends GetxController {
  PendingController({
    required this._receipts,
    required this._saver,
    required this._uploads,
  });

  final ReceiptRepository _receipts;
  final ReceiptSaveService _saver;
  final UploadService _uploads;

  final isRetrying = false.obs;

  List<Receipt> get pending => _receipts.pending;

  bool get isOnline => _uploads.isOnline.value;

  bool get hasUploads => pending.any((r) => r.status != ReceiptStatus.draft);

  String titleFor(Receipt r) {
    final what = switch (r.source) {
      ReceiptSource.camera || ReceiptSource.photos => 'photo',
      ReceiptSource.pdf => 'PDF',
      ReceiptSource.manual => 'record',
    };
    final name = r.retailer.isEmpty ? 'Untitled' : r.retailer;
    return '$name $what';
  }

  void open(Receipt r) {
    if (r.status == ReceiptStatus.draft) {
      Get.toNamed(Routes.reviewSummary, arguments: r.id);
    } else if (r.status == ReceiptStatus.failed) {
      Get.toNamed(Routes.uploadFailure, arguments: r.id);
    }
  }

  Future<void> retry() async {
    if (isRetrying.value) return;
    if (!isOnline) {
      Toast.show('Still offline. Your records are safe on this device.');
      return;
    }
    isRetrying.value = true;
    try {
      final saved = await _saver.retryPending();
      Toast.show(
        saved == 0
            ? 'Nothing was uploaded. Try again shortly.'
            : '${Formatters.count(saved, 'receipt')} saved to your vault',
      );
    } finally {
      isRetrying.value = false;
    }
  }
}
