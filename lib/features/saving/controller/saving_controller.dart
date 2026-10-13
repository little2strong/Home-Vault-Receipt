import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/models/receipt_model.dart';
import '../../../core/repositories/receipt_repository.dart';
import '../../../core/services/receipt_save_service.dart';

/// 30 · Saving. Reports each part of the save truthfully: the record is
/// stored first, then originals upload, then the record is marked saved.
class SavingController extends GetxController {
  SavingController({
    required this._receipts,
    required this._saver,
    required this.receiptId,
  });

  final ReceiptRepository _receipts;
  final ReceiptSaveService _saver;
  final String receiptId;

  final progress = 0.0.obs;
  final finished = false.obs;

  Receipt? get receipt => _receipts.byId(receiptId);

  bool get hasDocuments => receipt?.hasOriginal ?? false;

  @override
  void onReady() {
    super.onReady();
    _save();
  }

  Future<void> _save() async {
    final r = receipt;
    if (r == null) return;
    String route;
    Object? arguments = receiptId;
    try {
      final outcome = await _saver.save(
        r,
        onProgress: (p) => progress.value = p,
      );
      route = switch (outcome) {
        SaveOutcome.saved => Routes.saved,
        SaveOutcome.queued => Routes.pendingUploads,
        SaveOutcome.failed => Routes.uploadFailure,
      };
      if (outcome == SaveOutcome.queued) arguments = null;
    } on QuotaExceededException {
      route = Routes.pilotQuota;
      arguments = null;
    }
    finished.value = true;
    // The user may have left this screen; the save itself still completed.
    if (Get.currentRoute == Routes.saving) {
      Get.offNamed(route, arguments: arguments);
    }
  }
}
