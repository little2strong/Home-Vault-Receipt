import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/models/receipt_item.dart';
import '../../../core/models/receipt_model.dart';
import '../../../core/repositories/receipt_repository.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/ids.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/toast.dart';
import '../../../core/widgets/pickers.dart';
import 'edit_item_controller.dart';

/// 29 · Manual receipt: only the essentials are required.
class ManualReceiptController extends GetxController {
  ManualReceiptController({
    required this._receipts,
    this._clock = DateTime.now,
  });

  final ReceiptRepository _receipts;
  final Clock _clock;

  final formKey = GlobalKey<FormState>();
  final retailerController = TextEditingController();
  final totalController = TextEditingController();
  final purchaseDate = Rxn<DateTime>();
  final currency = 'GBP'.obs;
  final items = <ReceiptItem>[].obs;
  final dateError = RxnString();
  final isBusy = false.obs;

  Future<void> pickPurchaseDate(BuildContext context) async {
    final picked = await pickDate(
      context,
      initial: purchaseDate.value ?? _receipts.today,
      last: _receipts.today,
      help: 'Purchase date',
    );
    if (picked != null) {
      purchaseDate.value = picked;
      dateError.value = null;
    }
  }

  Future<void> pickCurrency(BuildContext context) async {
    final i = await showOptionSheet(
      context,
      title: 'Currency',
      options: Money.currencies,
      selected: Money.currencies.indexOf(currency.value),
    );
    if (i != null) currency.value = Money.currencies[i];
  }

  Future<void> editProduct([ReceiptItem? item]) async {
    final result = await Get.toNamed(
      Routes.editItem,
      arguments: ItemEditArgs(item: item, currency: currency.value),
    );
    if (result is! ItemEditResult) return;
    final index = item == null ? -1 : items.indexWhere((i) => i.id == item.id);
    if (result.removed) {
      if (index != -1) items.removeAt(index);
    } else if (index != -1) {
      items[index] = result.item!;
    } else {
      items.add(result.item!);
    }
  }

  Future<void> save() async {
    final formOk = formKey.currentState?.validate() ?? false;
    dateError.value = purchaseDate.value == null
        ? 'Choose the purchase date.'
        : null;
    if (!formOk || dateError.value != null || isBusy.value) return;

    isBusy.value = true;
    try {
      final draft = await _receipts.upsert(
        Receipt(
          id: Ids.next('rcpt'),
          retailer: retailerController.text.trim(),
          purchaseDate: purchaseDate.value!,
          total: Money.parse(totalController.text)!,
          currency: currency.value,
          items: items.toList(),
          createdAt: _clock(),
        ),
      );
      final duplicate = _receipts.findDuplicate(draft);
      Get.toNamed(
        duplicate == null ? Routes.saving : Routes.duplicate,
        arguments: draft.id,
      );
    } on Object {
      Toast.show('Could not save the draft. Try again.');
    } finally {
      isBusy.value = false;
    }
  }

  @override
  void onClose() {
    retailerController.dispose();
    totalController.dispose();
    super.onClose();
  }
}
