import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/models/receipt_model.dart';
import '../../../core/repositories/receipt_repository.dart';
import '../../shell/controller/shell_controller.dart';

/// 31 · Saved confirmation and 38 · Upload failure.
class SaveResultController extends GetxController {
  SaveResultController({required this._receipts, required this.receiptId});

  final ReceiptRepository _receipts;
  final String receiptId;

  Receipt? get receipt => _receipts.byId(receiptId);

  void viewReceipt() {
    ShellController.openTab(ShellTab.receipts);
    Get.toNamed(Routes.receiptDetail, arguments: receiptId);
  }

  void addReturnDate() => Get.toNamed(Routes.returnTerms, arguments: receiptId);

  void done() => ShellController.openTab(ShellTab.home);

  /// Continues the same save: same record id, so no duplicate is created.
  void retry() => Get.offNamed(Routes.saving, arguments: receiptId);
}
