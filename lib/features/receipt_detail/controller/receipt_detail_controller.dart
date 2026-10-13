import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/models/receipt_document.dart';
import '../../../core/models/receipt_item.dart';
import '../../../core/models/receipt_model.dart';
import '../../../core/repositories/receipt_repository.dart';
import '../../../core/utils/toast.dart';
import '../../review/controller/edit_item_controller.dart';
import '../../shell/controller/shell_controller.dart';

/// 32 · Receipt detail, 33/34 · Original, 36 · Delete.
class ReceiptDetailController extends GetxController {
  ReceiptDetailController({required this._receipts, required this.receiptId});

  final ReceiptRepository _receipts;
  final String receiptId;

  final page = 0.obs;
  final quarterTurns = 0.obs;
  final isDeleting = false.obs;

  Receipt? get receipt => _receipts.byId(receiptId);

  DateTime get today => _receipts.today;

  bool get isPdf => receipt?.documents.firstOrNull?.kind == DocumentKind.pdf;

  int get pageCount {
    final docs = receipt?.documents ?? const [];
    return docs.fold(0, (sum, d) => sum + d.pageCount);
  }

  // Original evidence is only shown through this explicit action.
  void openOriginal() {
    page.value = 0;
    quarterTurns.value = 0;
    Get.toNamed(Routes.originalDocument, arguments: receiptId);
  }

  void nextPage() {
    if (page.value < pageCount - 1) page.value++;
  }

  void previousPage() {
    if (page.value > 0) page.value--;
  }

  void rotate() => quarterTurns.value = (quarterTurns.value + 1) % 4;

  void openEdit() => Get.toNamed(Routes.editReceipt, arguments: receiptId);

  void openDelete() => Get.toNamed(Routes.deleteReceipt, arguments: receiptId);

  void openDeadline() {
    final r = receipt;
    if (r == null) return;
    Get.toNamed(
      r.returnDeadline == null ? Routes.returnTerms : Routes.reminderDetail,
      arguments: receiptId,
    );
  }

  void openPending() {
    final r = receipt;
    if (r == null) return;
    Get.toNamed(
      r.status == ReceiptStatus.draft
          ? Routes.reviewSummary
          : Routes.pendingUploads,
      arguments: r.status == ReceiptStatus.draft ? receiptId : null,
    );
  }

  Future<void> editItem(ReceiptItem item) async {
    final r = receipt;
    if (r == null) return;
    final result = await Get.toNamed(
      Routes.editItem,
      arguments: ItemEditArgs(
        item: item,
        currency: r.currency,
        canRemove: r.items.length > 1,
      ),
    );
    if (result is! ItemEditResult) return;
    final current = receipt;
    if (current == null) return;
    final items = [
      for (final i in current.items)
        if (i.id != item.id) i else if (!result.removed) result.item!,
    ];
    await _receipts.upsert(current.copyWith(items: items));
    Toast.show(AppStrings.receiptUpdated);
  }

  Future<void> delete() async {
    if (isDeleting.value) return;
    isDeleting.value = true;
    try {
      await _receipts.delete(receiptId);
    } on AppException catch (e) {
      isDeleting.value = false;
      Toast.show(e.message);
      return;
    }
    // Navigating away disposes this controller, so nothing runs after it.
    ShellController.openTab(ShellTab.receipts);
    Toast.show(AppStrings.receiptDeleted);
  }
}
